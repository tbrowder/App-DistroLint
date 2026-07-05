unit module TestMod;

use PDF::API6;
use PDF::Page;
use PDF::Font::Loader :load-font;
use PDF::Content::FontObj;
use JSON::Fast;
use Text::Utils :strip-comment;
use Lingua::EN::Numbers;

use SingleCheck::FontUtils;

constant MICR-TRANSIT is export = chr(0x2446);
constant MICR-ON-US   is export = chr(0x2447);
constant MICR-AMOUNT  is export = chr(0x2448);
constant MICR-DASH    is export = chr(0x2449);

# adjust vertical setting by using
# origin at top-left corner of
# the page and positive y down
sub _pdf-y($page, $y) { 
    $page.height - $y 
}

sub _hline($page, :$x!, :$y!, :$w!, :$stroke = 0.5) {
    $page.graphics: {
        .LineWidth = $stroke; 
        .MoveTo($x, _pdf-y($page, $y)); 
        .LineTo($x + $w, _pdf-y($page, $y));
        .Stroke;
    }
} # end of sub _hline

sub _rect($page, :$x!, :$y!, :$w!, :$h!, :$stroke = 0.5) {
    # the rectangle is drawn counter-clockwise starting 
    # at the lower-left corner (0,0)
    $page.graphics: {
        .LineWidth = $stroke;
        .Rectangle($x, _pdf-y($page, $y) - $h, $w, $h);
        .Stroke;
    }
} # end of sub _rect

sub _text(
    $pdf,
    $page, 
    Str $txt, 
    :$x!, :$y!, 
    :$core-font = 'Helvetica', 
    :$size = 10,
) {
    my $f = get-font($pdf, :$core-font);
    $page.text: {
        .font = $f, $size;

        .text-position = $x, _pdf-y($page, $y);

        .say: $txt;
    }
} # end of sub _text

sub load-layout(Str $path --> Hash:D) is export { #(:load-layout) {
    from-json $path.IO.slurp;
}

sub render-check(
    # how do we identify the input data?
    # need to enable easy private data for check
    # layout and data
    Str :$outfile!, # = "output/sample-check.pdf",
    Hash :$layout!,
         :%data!,
         :$debug,

=begin comment
    :%data = Hash[Str,Str].new(
        addr1 => "JOHN G. AND SALLY D. JOHNSON",
        addr2 => "123 MAIN STREET",
        addr3 => "ANYTOWN, USA 99999",
        check_number => "1001",
        date => "____/____/______",
        payee => "________________________________",
        amount_num => "",
        amount_words => "______________________________________________",
        memo => "",
        bank_info => "LOCAL BANK, ANYTOWN, USA",
        micr_routing => "000000000",
        micr_account => "0000000000",
        micr_checkno => "1001"
    ),
=end comment
) is export { #(:render-check) {

    my $dir = $outfile.IO.dirname;
    $dir.IO.mkdir unless $dir.IO.e;

    my $w = $layout<page><width>;
    my $h = $layout<page><height>;
    my $pdf = PDF::Lite.new(:page-size($w, $h));

    my $page = $pdf.add-page;

    my %p  = $layout<positions>;
    my %f  = $layout<fonts>;
    my %ln = $layout<lines> // {};
    my %wm = $layout<watermark> // {};
    my %ov = $layout<overlays>  // {};

=begin comment
# TODO no such ops!!
    # light background
    $page.graphics: {
        #.fill-color(0.98, 0.99, 1.0);
        .Rectangle(0, 0, $page.width, $page.height);
        .fill;
    }
=end comment

    # watermark
    if %wm && (%wm<text> // '').chars {
        my $rad = +(%wm<angle> // 30) * pi / 180;
        my $size = +(%wm<size> // (%f<watermark> // 22));
        my $x = +(%wm<x> // 100);
        my $y = +(%wm<y> // 110);
        my $opacity = +(%wm<opacity> // 0.15);
        my $wfont = get-font $pdf, :core-font('Helvetica-Bold');

        $page.gfx.graphics: -> $gfx {
            $gfx.graphics: {
                #.fill-alpha($opacity);
                .transform: :rotate($rad), :translate($x, _pdf-y($page, $y));
                .text: {
                    .font = $wfont, $size;
                    .text-position = 0, 0;
                    .say: %wm<text>;
                }
            }
        }

        =begin comment
        $page.graphics: {
            .save;
            .fill-alpha($opacity);
            .transform: :rotate($rad), :translate($x, _pdf-y($page, $y));
        }
        $page.text: {
            .font($wfont, $size);
            .move-text-position(0, 0);
            .show-text(%wm<text>);
        }
        $page.graphics: { .restore; }
        =end comment
    }

    # address block
    my $ax = %p<addr_block><x>;
    my $ay = %p<addr_block><y>;
    my $leading = %p<addr_block><leading> // 11;
    for ($%data<addr1>, $%data<addr2>, $%data<addr3>).grep(*.so).kv -> $i, $line {
        _text($pdf, $page, $line, 
              :x($ax), :y($ay + $i * $leading), :core-font('Helvetica'), :size(%f<info>)
             );
    }

    # headings and lines
    _text($pdf, $page, $%data<check_number>, :x(%p<check_number><x>), :y(%p<check_number><y>), 
          :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, "Date:", :x(%p<date_label><x>), :y(%p<date_label><y>), 
          :core-font('Times-Roman'), :size(%f<label>));
    _hline($page, :x(%p<date_line><x>), :y(%p<date_line><y>), :w(%p<date_line><w>), 
           :stroke(%ln<stroke> // 0.5));

    _text($pdf, $page, "Pay to the Order of", :x(%p<payee_label><x>), :y(%p<payee_label><y>), 
          :core-font('Times-Roman'), :size(%f<label>));
    _hline($page, :x(%p<payee_line><x>), :y(%p<payee_line><y>), :w(%p<payee_line><w>), 
           :stroke(%ln<stroke> // 0.5));

    _rect($page, :x(%p<amount_box><x>), :y(%p<amount_box><y>), :w(%p<amount_box><w>), 
          :h(%p<amount_box><h>), :stroke(%ln<stroke> // 0.5));

    _hline($page, :x(%p<legal_line><x>), :y(%p<legal_line><y>), :w(%p<legal_line><w>), 
           :stroke(%ln<stroke> // 0.5));
    _text($pdf, $page, "Dollars", :x(%p<dollars_word><x>), :y(%p<dollars_word><y>), 
          :core-font('Times-Roman'), :size(%f<label>));

    _text($pdf, $page, $%data<bank_info>, :x(%p<bank_info><x>), :y(%p<bank_info><y>), 
          :core-font('Helvetica'), :size(%f<info>));

    _text($pdf, $page, "For", :x(%p<memo_label><x>), :y(%p<memo_label><y>), 
          :core-font('Times-Roman'), :size(%f<label>));
    _hline($page, :x(%p<memo_line><x>), :y(%p<memo_line><y>), :w(%p<memo_line><w>), 
           :stroke(%ln<stroke> // 0.5));
    _hline($page, :x(%p<signature_line><x>), :y(%p<signature_line><y>), 
           :w(%p<signature_line><w>), :stroke(%ln<stroke> // 0.5));

    # draw a horizontal line along the cut line of the standard check paper
    _hline($page, :x(), :y(), :w(8.5*72), 0.5);

    _text($pdf, $page, $%data<payee>, :x(%p<payee_line><x> + 2), :y(%p<payee_line><y> - 2), 
          :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, $%data<amount_num>, :x(%p<amount_box><x> + 4), :y(%p<amount_box><y> - 2),
           :core-font('Helvetica-Bold'), :size(%f<amount_box>));
    _text($pdf, $page, $%data<amount_words>, :x(%p<legal_line><x> + 2), 
          :y(%p<legal_line><y> - 2), :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, $%data<memo>, :x(%p<memo_line><x> + 2), :y(%p<memo_line><y> - 2), 
          :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, $%data<date>, :x(%p<date_line><x> + 2), :y(%p<date_line><y> - 2), 
          :core-font('Helvetica'), :size(%f<field>));

    # overlays: draw image if available, else a labeled guide box
    for <logo signature> -> $k {
        my %cfg = %ov{$k} // next;
        next unless %cfg<enabled>;
        my $path = %cfg<path> // "";
        my $x = +(%cfg<x> // 0);
        my $y = +(%cfg<y> // 0);
        my $w = +(%cfg<w> // 40);
        my $h = +(%cfg<h> // 20);

        my $drawn = False;
        if $path.chars and $path.IO.e {
            try {
                my $img = $page.image($path);
                $page.graphics: {
                    .save;
                    .translate($x, _pdf-y($page, $y) - $h);
                    .image($img, :$w, :$h);
                    .restore;
                }
                $drawn = True;
            }
            CATCH { default { $drawn = False } }
        }

        if !$drawn {
            _rect($page, :x($x), :y($y), :w($w), :h($h));
            _text($pdf, $page, uc($k) ~ " HERE", :x($x + 2), :y($y + $h - 4), 
                  :core-font('Helvetica'), :size(6));
        }
    }

    # MICR placeholder (Courier). Adjust baseline with positions.micr.baseline_from_bottom
    my $micr = ":{$%data<micr_routing>}:{$%data<micr_account>} {$%data<micr_checkno>}";
    my $baseline = %p<micr><baseline_from_bottom> // 16;
    
    # check for access to micre fonts
    my ($mfont, $mfil);
    my $ffil = "$*HOME/\.SingleCheck/font-files\.list".IO // '';
    if $ffil.IO.e {
        # read to find the mfont path
        if 1 or $debug {
            say "DEBUG: found user's list of font files: '$ffil'";
        }
        my ($code);
        for $ffil.IO.lines -> $line is copy {
            $line = strip-comment $line;
            next unless $line ~~ /\S/;
            # two parts
            # code font-file-path
            my @words = $line.words;
            $code = @words.head;
            $mfil = @words.tail;
            
        }
        if 1 or $debug {
            say "DEBUG: found micre font file: '$mfil'";
        }
        $mfont = get-font $pdf, :font-file($mfil);
    }
    else {
        if 1 or $debug {
            say "DEBUG: did not find micre font file";
        }
        # alternate font
        $mfont = get-font $pdf, :core-font('Courier');
    }

    if 1 or $debug {
        say "DEBUG: \$micr text: '$micr'";
    }

    $page.text: {
        .font = $mfont, %f<micr>;
        .text-position = 16, $baseline;
        .say: $micr;
    }

    $pdf.save-as($outfile);
} # end of sub render-check(

#=finish

=begin comment

#!/usr/bin/env raku

use PDF::Lite;
use PDF::Font::Loader :load-font;
use PDF::Content::FontObj;

constant MICR-TRANSIT = chr(0x2446);
constant MICR-ON-US   = chr(0x2447);
constant MICR-AMOUNT  = chr(0x2448);
constant MICR-DASH    = chr(0x2449);

my $mpath = "/home/tbrowde/mydata/tbrowde-home/Monotype-MyFonts/MICR/MICRStd.otf";

=end comment

class Mtext is export {
    has Str $.routing = "123456789";
    has Str $.account = "0123456789";
    has Int $.number is rw = 1000 ;
}

sub print-micre-line-style1(
    # The defaults for the prefix and suffix characters are for one known use case
    # for a personal checking account.
    # other styles may print the parts in a different order and require a different
    # subroutine.

    # the defaults for the enclosed numbers are place holders for testing
    #                           prefix                suffix
    :$routing = "123456789",    :$rp = MICR-TRANSIT, :$rs = MICR-TRANSIT,
    :$account = "000123456789", :$ap = "",           :$as = MICR-AMOUNT,
    :$number  = "1234",         :$np = "",           :$ns = "",

    :$pdf!, :$page!,
    :$font-path!, 
    :$font-size = 12, 
    :$x! is rw, :$y!, # starting point for the text line
                #   where y is the distance from the TOP of the page
    :$d1 = 36,  # distance between routing and account

    :$d2 = 42,  # distance between account and check number
    :$box = False, # if True, put a box around the text line
    :$debug = False;

) is export {
    # given a path to a micre font, a font size, and other info, print 
    # a micr check line

    my $micr-font = load-font(:file($font-path));
    # build the micre line
    my $mtext1 = $rp ~ $routing ~ $rs;
    my $mtext2 = $ap ~ $account ~ $as;
    my $mtext3 = $np ~ $number  ~ $ns;

    my @box;
    $page.text: {
        .font = $micr-font, $font-size;

        # print the first chunk
        .text-position = $x, $y;
        @box = .print: $mtext1;
        say "DEBUG: starting x = {@box[0]}" if 0 or $debug;
        say "DEBUG: ending   x = {@box[2]}" if 0 or $debug;
        $x = @box[2] + $d1; 

        # print the second chunk
        .text-position = $x, $y;
        @box = .print: $mtext2;
        $x = @box[2] + $d2; 

        # print the third chunk
        .text-position = $x, $y;
        @box = .print: $mtext3;
    }
} # end of sub print-micre-line-style1(

#sub populate(IO::Path $dir, :$debug) is export {
sub populate($dir, :$debug) is export {
    unless $dir.IO.d {
        die qq:to/HERE/;
        FATAL: Unable to populate directory '$dir'.
           Please file an issue with details.
        HERE
    }

    # TODO check and ask the user to add private account info.
    #   The default zero values must be filled before and personal
    #   can be written!! Note there will be some exceptions:
    #     + second name
    #     + third address line

    # copy the files from dir 'resources' into the dir.
    # do NOT overwrite existing files
    # remember to add the config.yml file, too (don't 
    # forget its contents)
    if $debug {
        say "DEBUG: filling dir '$dir' with config files";
    }
} # sub populate

sub get-next-check-number(
    $account,
    :$debug = False,
) is export {
    # the directory with zero or more used checks
    my $cdir = "$*HOME/.SingleCheck/accounts/$account/checks";
}

=finish

#my PDF::Content::FontObj $micr-font = load-font(:file($mpath));

my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;

# desired starting positions
my $y = 700;
my $x = 40;

print-micre-line-style1 :$pdf, :$page, :$x, :$y, :font-path($mpath);

say "Writing a personal check micre line: ";
my $mtest = "micr-font-test.pdf";
$pdf.save-as($mtest);
say "See file $mtest";
