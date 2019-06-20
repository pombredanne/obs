# Generating a report of open source licenses used by your debian package

Let's say you (foocorp) are the author of a debian package 'XYZ'.

Users of your package may ask, "If I use to build an application using 'XYZ' that otherwise consists of
a single source file, what software licenses am I bound by when I ship the resulting application?"

This page collects what we know about how to answer that question and how we generated the above report.  For deep background, see the Theory and References sections below.

### The Central Dogma

Here's a simple narrative about how it should all work.

Licensing information flows from source code to all installed Debian/Ubuntu packages (not just XYZ!) as follows:

- Each source tree contains a copyright file in DEP-5 format
- Developers add copyright info in comments in source files, and if they're on top of things, update the copyright file
- Maintainer periodically updates the copyright file, e.g. by running scancode to look for copyright notices in new source files.
- The copyright file gets installed to /usr/share/doc/$MYPACKAGENAME/copyright when the package gets installed

Then, once you've built a binary and want to check what licenses it has to obey, you can simply retrieve the licensing information from the packages used by your binary.  ob-list-licenses is a tool that uses ldd to do this; see below.

### Complications

There are deviations from the beautiful world described above, e.g.

- copyright file is somewhat coarse-grained; if the package contains both GPL and LGPL files, both licenses will be listed even if only LGPL makes its way into the final product
- unlabelled source code copying: when a developer forgets to good license info for borrowed sources
- header-only classes: some C++ classes might be expressed only as header files not in your source tree, and ldd won't see these
- static linking: if your app statically links to something, that dependency won't be picked up by ldd.  Shouldn't generally be a problem.
- late binding: if your app loads a dynamic library late (e.g. as a plugin), ldd won't see it

but don't let them bother you too much; we can handle those details later.

## Tools

### ob-list-licenses

ob-list-licenses takes a path to a single binary,
looks up what packages it relies on, and outputs their names and licenses.  (Licenses should be
output using their [SPDX id](https://spdx.org/licenses), but not all packages use those ids yet.)

Its output should be taken with a grain of salt; just because it lists GPL as a license, doesn't necessarily mean that the binary you're analyzing actually includes any GPL bits.

ob-list-licenses is installed along with obs, but is not yet really polished, and is subject to change.

Example:
```
$ cp -a /opt/foocorp/XYZ/samples .
$ cd samples/canary
$ make
$ ob-list-licenses ./canary
libc6  https://www.gnu.org/software/libc/libc.html
  "glibc-special"

libgcc1  http://gcc.gnu.org/
  "libgcc1-special"

libicu60  http://www.icu-project.org

libstdc++6  http://gcc.gnu.org/
  "libstdc++6-special"

foocorp-XYZ2  http://foocorp.com
  BSD-2-Clause
  BSD-3-Clause
  BSD-style
  Expat
  http://shop.oreilly.com/category/customer-service/faq-examples.do
  Khronos
  MIT-Like
  Proprietary
  public-domain
```

Those license names aren't all quite SPDX.  ob-list-licenses has a --spdx option that tries
harder to convert them to SPDX, but it's only half-baked.

### scancode: searches source tree for copyright and license info

This is a great tool.  Mattie had very good things to say about it when she last updated yovo's copyright file. We also rely on it heavily in `ob-list-licenses` to parse non dep-5 files to determine possible licenses.

See https://github.com/nexB/scancode-toolkit

### spdx tools

https://spdx.org/ is the home of the SPDX licensing format that, along with DEP-5, is at the heart of most licensing tools in the Linux world.

They offer a few tools, e.g. https://github.com/spdx/tools, that can e.g. validate spdx files. Example:
```
$ export JAVA_HOME=$(update-alternatives --query java | grep Value: | awk -F'Value: ' '{print $2}' | awk -F'/bin/java' '{print $1}')
$ git clone git@github.com:spdx/tools.git
$ cd tools
$ mvn package
$ cp target/spdx-tools-2.1.16-SNAPSHOT-jar-with-dependencies.jar ~
$ java -jar ~/spdx-tools-2.1.16-SNAPSHOT-jar-with-dependencies.jar Verify target/test-classes/SPDXTagExample-v2.1.spdx
```
but it doesn't do other things we'd like.

### Rust

Ignore everything else in this document, and 
use [https://github.com/onur/cargo-license](https://github.com/onur/cargo-license) to generate a list of licenses used by your project's Cargo.toml dependencies.

### FOSSology: heavyweight compliance toolkit

See https://www.fossology.org/

This is big and clunky, but might do some useful things.

## Theory

Determining compliance is at least a two-step process:

1. Source Code Analysis: scanning source code to look for any copyrights and licensing within. Most source code analysis tools assume that programmers have done the right thing when borrowing code from places and included the licensing and attribution inline. This scan can then be thought of literally as a grep of the source code for terms like "copyright" or "license". There are good tools for helping you compile this analysis, though they typically output lots of false positives. See below for an overview of these tools and how to use them to compile/update the copyright file.

2. Binary Analysis: determining what software binaries pull in at runtime. From the practical compliance guide:
>>>
A Word about Binaries
In this book, the word “binary” can mean different things. Sometimes
it means a single executable, sometimes it means an object file,
sometimes it means an archive of binaries, sometimes a firmware;
other times it means an unknown blob of data. 
Practical GPL Compliance: Approach 9
Here is what these different types of binary uses all have in common:
1. They are not source code.
2. They could be built from open source code.
3. They should be analysed.
>>>

## References

- The Linux Foundation's Guide to [Practical GPL Compliance](https://www.linuxfoundation.org/open-source-management/2017/05/practical-gpl-compliance/) : This book is primarily focused on compliance for projects that are also open sourced, however, it gives a good overview of the general problem/what it means to be compliant at the beginning.
- The Linux Foundation's [Five-Step Compliance Process for FOSS Identification and Review](http://www.ibrahimatlinux.com/uploads/6/3/9/7/6397792/2.pdf) : This pdf is a quick run down for how to look into GPL compliance for proprietary code. Thus, it maps more closely to how we should proceed.
- The [debian copyright format](https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/) -- most open source projects adhere to this format and install a formatted file so that you can determine their licensing details.
- [SPDX Licenses](https://spdx.org/licenses/) -- If projects followed the proper debian copyright format and chose a pre-ordained license, then it should map to one or more of the spdx licenses and have an spdx code you can use for license lookup. Unfortunately, copyright files can be quite complex and oftentimes refer to pre-ordained licenses using non-identical codes. The most common of which I've seen is: `GPL2+`, which should be written: `GPL-2.0-or-later`. *TBD* Does the spdx-lookup tool do a good job at converting these misnomers? 

