use Test;

use Text::Utils :strip-comment;

my $s = "use Blah:ver<0.0.1> ; use Bar; # comment";
$s = strip-comment $s;
# chop the trailing semicolon
$s ~~ s/';' \s*//;

my @all = $s.split(';');
my $n = @all.elems;

is $n, 2;

done-testing;


