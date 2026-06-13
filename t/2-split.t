use Test;

use Text::Utils :strip-comment;

my $s = "use Blah:ver<0.0.1> ; use Bar :baz; # comment";
say "two uses and a comment: $s";
$s = strip-comment $s;

# from chatgpt:
my @parts = $s.split(';').map(*.trim).grep(*.chars);
# note prev op will not clean multiple white space

my $s1 = @parts.head.words.join(" ");
my $s2 = @parts.tail.words.join(" ");
say "first part: $s1";
say "second part: $s2";

my $n = @parts.elems;

is $n, 2;

done-testing;


