[![Actions Status](https://github.com/tbrowder/App-DistroLint/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/App-DistroLint/actions) [![Actions Status](https://github.com/tbrowder/App-DistroLint/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/App-DistroLint/actions) [![Actions Status](https://github.com/tbrowder/App-DistroLint/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/App-DistroLint/actions)

NAME
====

**App::DistroLint** - Provides binary file `distrolint` to check for errors in a distribution's repository directory. Also provides an alias, `dlint`, for easier typing.

SYNOPSIS
========

```raku
$ dlint /path/to/distro/repodir
```

DESCRIPTION
===========

Running binary `distrolint` on a distribution repository can be very helpful during preparation or maintenance by a distribution author. Run the binary without any arguments to see its current capabilities. The current capabilities are:

  * Reports the distribution's list of other distribution's being 'used' in the 'META6.json' file's list versus those actually being 'used' in the 'bin', 'sbin', and 'rakumod' files.

Please file an issue if you would like other capabilities added.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

© 2025 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

