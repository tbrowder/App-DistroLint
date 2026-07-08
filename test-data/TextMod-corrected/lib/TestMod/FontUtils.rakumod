unit module TestMod::FontUtils;

use PDF::API6;
use PDF::Lite;
use PDF::Page;
use PDF::Font::Loader :load-font;
use PDF::Content::FontObj;

sub get-font(
    #PDF::API6:D $pdf,
    PDF::Lite $pdf,
    Str :$core-font = "Times-Roman",
    Str :$font-file,
    PDF::Content::FontObj :$font-object,
) is export {
    if $font-object.defined {
        return $font-object;
    }

    if $font-file.defined and
        $font-file.IO.e {
        return load-font(:file($font-file));
    }

    return $pdf.core-font($core-font);
}

