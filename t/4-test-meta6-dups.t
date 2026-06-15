use Test;

use JSON::Fast;

my $tmeta-fil = "xtra/test-meta.json";
my $meta = from-json $tmeta-fil.IO.slurp;
isa-ok $meta, Hash;

my @deps = @($meta<depends>);
isa-ok @deps, List;
is @deps.head, "Foo";

my @b-deps = @($meta<build-depends>);
isa-ok @b-deps, List;
is @b-deps.elems, 3;
is @b-deps.head, "Foo";
is @b-deps[1], "Bar";
is @b-deps.tail, "Bar";

my @t-deps = @($meta<test-depends>);
isa-ok @t-deps, List;
is @t-deps.head, "Foo";

# test for dups using intersections (from ChatGPT)

# find common elements in 1 array
my $dups-deps   = set Bag(@deps).grep(*.value > 1).map(*.key);
my $dups-t-deps = set Bag(@t-deps).grep(*.value > 1).map(*.key);
my $dups-b-deps = set Bag(@b-deps).grep(*.value > 1).map(*.key);

# find common elements between 2 arrays
my $common = Set(@deps) (&) Set(@t-deps);

# show the sorted values in a set
my $cmn =  $common.keys.sort.join(" ");
is $cmn, "Foo JSON::Fast";



done-testing;


