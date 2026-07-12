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

  * Reports the distribution's list of other distributions being 'used' in the 'META6.json' file's list versus those actually being 'used' in the 'bin', 'rakumod', and test files.

  * Detects duplicate entries of used modules.

  * Detects module adverbs and recommends they only be used in the META6.json file.

More detailed information follows.

Errors recognized
=================

Following is a list of specific errors sought for in the various parts of a distribution's files. in a standard layout.

META6.json errors
-----------------

### Errors in the "provides" array

  * missing items

  * duplicate entries

  * illegal entries

### Errors in the "*depends" arrays

  * missing items

  * unrequired entries

  * module name adverbs out of correct order (ver, auth, api)

  * module name duplicate adverbs

  * duplicate module names

Errors in rakumod files
-----------------------

  * module name adverbs in 'use'd modules

  * duplicate 'use'd modules in one file

  * 'use'd modules not found in any depends array

Ecosystem installation errors
-----------------------------

  * modules uninstalled

  * modules not found in Fez 

Summary
=======

See examples of errors handled in file `test-modules/Tmod-errs/*`.

**File an issue if you would like other capabilities added.**

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

© 2026 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

