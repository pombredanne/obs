from BBDependencies import BBDependencyGraph
import unittest

# This is a test case for the dependency lister.
#
# main depends on library, lib2a, and lib2b
# lib2a depends on library
# lib2b depends on nothing
#
# So we want a build of library to trigger a rebuild of lib2a,
# and a build of lib2a or lib2b to trigger a rebuild of main,
# but we do not want a build of library to directly trigger a rebuild of main,
# because we do not want main to be rebuilt twice as a result of library being built once.
# We accept that main will be built twice - once as a result of lib2a,
# ones as a result of lib2b - because we don't have any control over how
# those are ordered in the buildbot world (yet?).

class TestDependencyGraph(unittest.TestCase):
    _graph = BBDependencyGraph()
    _graph.loadDependenciesFromFiles("bs_deps/ubu1604")
    _graph.dump()
    def testLoad(self):
        g = self._graph
        self.assertEqual(g.depends("mumble-main"), [
                         "mumble-lib2a", "mumble-lib2b", "mumble-library"])
        self.assertEqual(
            g.reverse_depends("mumble-library"), ["mumble-lib2a", "mumble-main"])
        self.assertEqual(g.reverse_depends("mumble-lib2a"), ["mumble-main"])
        self.assertEqual(g.in_build_order_without_repeats(
            g.reverse_depends("mumble-library")), ["mumble-lib2a"])
if __name__ == '__main__':
    unittest.main()
