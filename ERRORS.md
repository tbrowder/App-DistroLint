TITLE
=====

Errors recognized

Following is a list of specific errors sought for in the various parts of a distribution's files. in a standard layout.

META6.json errors
=================

Errors in "provides" array
--------------------------

  * missing items

  * duplicate entries

  * illegal entries

Errors in the "*depends" arrays
-------------------------------

  * missing items

  * illegal entries

  * module name adverbs out of correct order (ver, auth, api)

  * module name duplicate adverbs

  * duplicate module names

Errors in rakumod files
-----------------------

  * mmodule name adverbs in 'use'd modules

  * duplicate 'use'd modules in one file

  * 'use'd modules not found in any depends array

Ecosystem installation errors
=============================

  * modules uninstalled

  * modules not found in Fez 

