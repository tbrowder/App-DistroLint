use Test;
use App::DistroLint;

my %depends is SetHash = (<JSON::Fast> => True);
# add an item 
%depends (|)= <Runtime::Only>;

my %test-depends is SetHash = (<JSON::Fast> => True);
%test-depends (|)= <Test::Only>;

my %build-depends is SetHash = (<App::Mi6> => True);
%build-depends (|)= <Test::Only>;

my %clean = canonicalize-meta-dependency-sets(
    :%depends,
    :%test-depends,
    :%build-depends,
);

=begin comment
ok %clean<depends><JSON::Fast>:exists;
nok %clean<test-depends><JSON::Fast>:exists;

ok %clean<build-depends><Test::Only>:exists;
nok %clean<test-depends><Test::Only>:exists;

ok %clean<depends><Runtime::Only>:exists;
ok %clean<build-depends><App::Mi6>:exists;
=end comment

done-testing;
