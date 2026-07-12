use Test;

use Lingua::EN::Numbers;
no-commas;

my @nums = <
    10.22
    1100.16
    12243.30
    201632.43
    38
    0.57
    10
>;

for @nums -> $num {
    # split into whole and decimal parts
    my ($dollars, $cents) = 0, 0;
    if $num ~~ /'.'/ {
        ($dollars, $cents) = $num.split('.');
    }
    else {
        $dollars = $num;
    }
    my $out1 = "{cardinal $dollars}";
    my $out2 = "{$cents}/100 dollars";
    if $cents == 0 {
        $out2 = "no/100 dollars";
    }

    say "input: '$num', dollars: '$dollars', cents: '$cents'";
    say "  output: '$out1 and $out2'";

}

done-testing;

