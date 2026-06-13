use Test;

use Text::Utils :strip-comment;

my $s = "use  Blah:ver<0.0.1> ; use Bar :baz ; # comment";
say "two uses and a comment: $s";
$s = strip-comment $s;

# from chatgpt:
# after removing comments
my @parts = $s.split(';').map(*.trim).grep(*.chars);

# note prev op will NOT clean multiple white spaces
# do that this way
for @parts.kv -> $i, $part is copy {
    $part = $part.words.join(" ");
    say "part $i: '$part'";
    @parts[$i] = $part;
}

my $n = @parts.elems;

is $n, 2;

done-testing;


