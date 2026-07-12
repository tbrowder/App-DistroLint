unit module TestMod::Utils;

use JSON::Hjson;
use JSON::Fast;
use YAMLish;
use Lingua::EN::Numbers;

use PDF::API6;
use PDF::Lite;
use PDF::Font::Loader;
use PDF::Content::Color :ColorName, :color;
use FontFactory::Type1;

sub deg2rad($d) is export { $d * pi / 180 }

sub get-yml-hash($f --> Hash) is export {
    load-yaml($f.IO.slurp)
} 

sub get-json-hash($f --> Hash) is export  {
    from-json($f.IO.slurp)
} 

sub get-hjson-hash($f --> Hash) is export  {
    from-hjson($f.IO.slurp)
} 

sub make-page(
    PDF::Lite :$pdf!,

    # payload
    #Calendar :$cal,
    #UInt :$month, # month number
    :$PW,
    :$PH,
    :$LM,
    :$font, 
    :$font2,
    :$debug,
    
) is export {
    # media-box - width and height of the printed page
    # crop-box  - region of the PDF that is displayed or printed
    # trim-box  - width and height of the printed page
    my $page = $pdf.add-page;
    my $gfx  = $page.gfx;

    # always use landscape orientation
    $gfx.Save;
    # transform coordinate system for landscape, origin
    # at lower-left corner of the page
    $gfx.transform: :translate[$PW, 0];
    # positive angle: anti-clockwise (rotate left)
    $gfx.transform: :rotate(deg2rad(90)); 

    # hard vertical dimensions:
    #   bottom of the 6-week grid above the bottom margin BM
    #   top of the 6-week grid above its bottom
    #   height of the week-day column names

    # font names and sizes:
    #   month/year title - Times-Bold 20 pt
    #   monthly quotes - Times-Italic 15 pt
    #   day text:
    #     line-space-ratio - 1.05
    #     white-on-black day-of-week - Helvetica-Bold 12 pt
    #     holidays, birthdays, etc. - Times-Bood 10 pt, indent 5 #                               
    #     day number - Helvetica 12 pt (outline for "negative" day numbers)
    #                  offset x - 4 pt from the right of cell
    #                  offset y - 12 * line-space-ratio from top of cell
    #     sun rise/set
    #     moon phase
    #     moon phase symbol 0.3 in from bottom of the cell

    # make the title line (month, year

    # make the sayings line

    # make the grid (dow, then 4, 5, or 6 weeks)
    my $nweeks = 6; #weeks-in-month $cal.year
    my $width  = ($PH - 2 * $LM)/7; # use full width less two margins
    # leave space for title and cell header row
    my $title-baseline = 72;
    my $grid-top-space = 10;
    my $cell-hdr = 10;
    my $height = ($PH - 2 * $LM)/6;

    for (20, 40 ... 200)  -> $x {
        for 20, 40, 60 -> $y {
            $gfx.&make-box: :$x, :$y, :$width, :$height;
        }
    }

    # fill each cell appropriately
    #   create a mapping from day-of-week and week-of-month
    #   to cell in the grid

    # must alway restore the CTM
    $gfx.Restore;
}

# subs for gfx calls (I do not understand this!!)
# but I'm getting the drift of it
sub make-box($_,
    :$x!, :$y!, :$width!, :$height!,
    :$linewidth = 2,
    :$debug,
    # payload
) is export {
    # given the bottom-left corner, dimensions, etc
    # draw the box
    # must save the CTM
    .Save;

    # transform to the bottom-left corner
    .transform: :translate[$x, $y];
    .Rectangle: 0, 0, $width, $height;
    .CloseStroke;

    # print or draw the data

    # restore the CTM
    .Restore;
}

sub put-text(
    PDF::Lite::Page :$page!, 
    :$font,
    :$debug
) is export {

    $page.text: -> $txt {
        $txt.font = $font, 10;
        my $text = "Other text";
	$txt.text-position = 200, 200;
        $txt.say: $text, :align<center>; #, :valign<baseline>;
    }
}

sub write-cell-line(
    # text only
    :$text = "<text>",
    :$page!,
    :$x0!, :$y0!, # the desired text origin
    :$width!, :$height!,
    :$Halign = "center",
    :$Valign = "center",
) {
    $page.text: {
        # $x0, $y0 MUST be the desired origin for the text
        .text-transform: :translate($x0+0.5*$width, $y0-0.5*$height);
        .font = .core-font('Helvetica'), 15;
        with $Halign {
            when /left/   { :align<left> }
            when /center/ { :align<center> }
            when /right/  { :align<right> }
            default {
                :align<left>;
            }
        }
        with $Valign {
            when /top/    { :valign<top> }
            when /center/ { :valign<center> }
            when /bottom/ { :valign<bottom> }
            default {
                :valign<center>;
            }
        }
        .print: $text, :align<center>, :valign<center>;
    }
}

sub draw-cell(
    # graphics only
    :$text,
    :$page!,
    :$x0!, :$y0!, # upper left corner
    :$width!, :$height!,
    ) is export {

    # Note we bound the area by width and height and put any
    # graphics inside that area.
    $page.graphics: {
        .Save;
        .transform: :translate($x0, $y0);
        # color the entire form
        .StrokeColor = color Black;
        #.FillColor = rgb(0, 0, 0); #color Black
        .LineWidth = 2;
        .Rectangle(0, -$height, $width, $height);
        .Stroke; #paint: :fill, :stroke;
        .Restore;
    }
}
