use Test;

use App::DistroLint;

my $txt = q:to/HERE/;
use Foo;

if not @*ARGS {
}

HERE

for $txt.lines.kv -> $i, $line is copy {
    say "line $i: '$line'";
    unless $line ~~ /^ [use|need|require] / {
        say "    this is NOT a 'use' line";
    }
}

is 1, 1;

done-testing;



