import glob
import re
import string

class BBDG_TopologicalSorter:

    """Simple helper to do a topological sort on a directed acyclical graph."""

    def __init__(self, name2deps):
        """Arg is a map from name to list of things name depends on"""
        self._name2deps = name2deps
        self._visited = dict()
        self._result = []

    def visit_dependencies(self, name):
        """Recursively visit dependencies, then add self to _result"""
        if name not in self._visited:
            self._visited[name] = True
            if name in self._name2deps:
                for dep in self._name2deps[name]:
                    self.visit_dependencies(dep)
            self._result.append(name)

    def sorted(self):
        """ Return a list of names in topological order, i.e.
            where building things in that order would satisfy dependencies.
        """
        for name in self._name2deps:
            self.visit_dependencies(name)
        return self._result


class BBDG_Visitor:

    """Simple helper to visit a node and its descendants."""

    def __init__(self, name2deps):
        """Arg is a map from name to list of things name depends on"""
        self._name2deps = name2deps
        self._visited = dict()
        self._result = []

    def was_visited(self, name):
        """Return whether the node was visited."""
        return name in self._visited

    def visit_dependencies(self, name):
        """Recursively visit dependencies, then add self to _result"""
        if not self.was_visited(name):
            self._visited[name] = True
            if name in self._name2deps:
                for dep in self._name2deps[name]:
                    self.visit_dependencies(dep)


class BBDependencyGraph:
    """Build a build dependency graph.
       The depends() and reverse_depends() methods take builder names,
       not package names.
    """

    def __init__(self):
        """
        Just initializes an empty graph.
        You'll need to call addDependency() and finalizeGraph() to populate it,
        or call loadDependenciesFromFiles() to load files and call those
        functions for you.
        """

        # map from package name to list of package names that it depends on
        self._depends = dict()

        # map from package name to list of package names that depend on it
        self._rdepends = dict()

        # map from package name to map of package names that it depends on
        self._depends_map = dict()
        # map from package name to map of package names that depend on it
        self._rdepends_map = dict()

        # Note about source of dependency info, for debugging
        self._source = ""

    def addDependency(self, target, dependency):
          if target not in self._depends_map:
             self._depends_map[target] = dict()
          if target == dependency:
             print("Naughty, naughty, builder %s declared that it depends on builder %s, ignoring (yes, this has happened)" % (target, dependency))
          else:
             print("Declaring that builder %s depends on builder %s" % (target, dependency))
             self._depends_map[target][dependency] = True;

    def finishLoading(self):
        # Reverse dependencies
        for x in self._depends_map:
           for y in self._depends_map[x]:
               if y not in self._rdepends_map:
                   self._rdepends_map[y] = dict()
               self._rdepends_map[y][x] = 1;

        # Convert to dicts of lists
        for x in self._depends_map:
           self._depends[x] = sorted([y for y in self._depends_map[x]])
        for y in self._rdepends_map:
           self._rdepends[y] = sorted([x for x in self._rdepends_map[y]])

        # Find legal build order
        m = BBDG_TopologicalSorter(self._depends)
        self._buildorder = m.sorted()

    def loadDependenciesFromFiles(self, dir):
        """
        Loads the .in and .out files from the given directory tree
        and creates a map showing which builders to trigger
        when a build finishes.

        Reads *.in and *.out to see each unit's dependencies and outputs,
        provide methods to probe the graph.

        The filenames of the .in and .out files are e.g. the buildbot builder
        names; the contents are e.g. package names.
        Package names and builder names are assumed to be unrelated.
        """
        # map from package name to builder name
        # Note: this is not unique across platforms, so we need a separate
        # instance per platform
        package2builder = dict()

        # Build translation table from package to builder that builds it
        self._source = dir
        #print "Processing directory %s" % dir
        for outfile in glob.glob(dir + "/*.out"):
           #print "found outfile %s" % outfile
           name = outfile.replace(".out", "")
           name = re.sub(r'.*/', '', name)
           with open(outfile, "r") as outf:
              for line in outf.readlines():
                  line = line.rstrip()
                  #print "Recording that package %s is built by builder %s in dir %s" % (line, name, dir)
                  package2builder[line] = name

        # For each builder, note which builders it depends on
        for infile in glob.glob(dir + "/*.in"):
           #print "found infile %s" % infile
           name = infile.replace(".in", "")
           name = re.sub(r'.*/', '', name)

           with open(infile, "r") as inf:
              for line in inf.readlines():
                  line = line.rstrip()
                  if line not in package2builder:
                      print("No package %s built by any builder, ignoring in dir %s" % (line, dir))
                      #print "Current contents of package2builder"
                      #pprint(package2builder)
                      continue
                  builder = package2builder[line]
                  self.addDependency(name, builder)

        self.finishLoading()

    def depends(self, name):
        """Returns a list of builders that the given builder depends on."""
        if name in self._depends:
            return self._depends[name]
        return None

    def reverse_depends(self, name):
        """Returns a list of builders that depend on the given builder"""
        if name in self._rdepends:
            return self._rdepends[name]
        return None

    def in_build_order(self, names):
        """Returns given list sorted such that it's safe to build them in that order."""
        return [x for x in self._buildorder if x in names]

    def in_build_order_without_repeats(self, names):
        """Returns given list sorted such that it's safe to build them in that order,
           and with obviously redundant builds ... elided.
        """
        # Get a safe order to build in
        names = self.in_build_order(names)
        # Copy each element to shortlist if it won't already have been built
        # earlier
        shortlist = []
        m = BBDG_Visitor(self._rdepends)
        for name in names:
            if not m.was_visited(name):
                shortlist.append(name)
                m.visit_dependencies(name)
                #print "in_build_order_without_repeats: triggering %s because it hasn't been triggered yet in %s" % (name, self._source)
            else:
                print("in_build_order_without_repeats: skipping %s because it was already triggered; %s" % (name, self._source))
        return shortlist

    def dump(self):
        print("Dependency graph:")
        for name in self._depends:
            print("%s: %s" % (name, " ".join(self._depends[name])))
        print("")

        print("Legal build order:")
        print(" ".join(self._buildorder))

        print("Minimal-ish legal trigger order:")
        print(" ".join(self.in_build_order_without_repeats(self._buildorder)))
