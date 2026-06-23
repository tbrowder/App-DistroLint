use Test;
use App::DistroLint;

my SetHash %depends;
my SetHash %test-depends;
my SetHash %build-depends;

%depends<JSON::Fast> = True;
%depends<Runtime::Only> = True;

%test-depends<JSON::Fast> = True;
%test-depends<Test::Only> = True;

%build-depends<App::Mi6> = True;
%build-depends<Test::Only> = True;

my %clean = canonicalize-meta-dependency-sets(
    :%depends,
    :%test-depends,
    :%build-depends,
);

ok %clean<depends><JSON::Fast>:exists;
nok %clean<test-depends><JSON::Fast>:exists;

ok %clean<build-depends><Test::Only>:exists;
nok %clean<test-depends><Test::Only>:exists;

ok %clean<depends><Runtime::Only>:exists;
ok %clean<build-depends><App::Mi6>:exists;

done-testing;
