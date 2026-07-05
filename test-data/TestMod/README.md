TITLE
=====

Checkwriter::SampleCheck — Mi6-managed check templates

SUBTITLE
========

JSON-driven personal check rendering using PDF::Lite (Raku)

Synopsis
========

    zef install PDF::Lite JSON::Fast
    export CHECKWRITER_ASSETS=$PWD   # optional, for assets/fonts lookup
    raku bin/make-fidelity-check.raku
    raku bin/make-hancock-check.raku

Description
===========

**Checkwriter::SampleCheck** renders printable personal checks (6.00" x 2.75", 432x198 pt) as PDF using [PDF::Lite](PDF::Lite). Layout, watermark, overlays, and MICR baseline are configured via JSON files under `config/banks/`.

Bank Styles
===========

* Fidelity Investments (logo block at left; payee/date shifted right) * Hancock Whitney (classic layout; larger amount box)

Safety
======

Ships with fictional data and a visible MICR placeholder font by default. To print real checks, follow your bank's rules and use required materials.

