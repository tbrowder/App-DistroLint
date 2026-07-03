# test xt/8*t

use Test;

use App::DistroLint;

my $debug = 1;

my $root = "xt/data/module-discovery".IO;

say "DEBUG: \$root = $root'" if $debug;


my %provides = build-provides-map($root);

is %provides.elems, 2, "found two provided modules";
if $debug {
    say "DEBUG: \%provides contents:";
    say "  $_" for %provides.keys;
}

is-deeply %provides.keys.sort, <A A::B>.sort, "no unexpected provides modules";

=finish

ok, %provides<A>:exists, "found module A";

ok, %provides<A::B>:exists, "found module A::B";

is %provides<A>, 'lib/A.rakumod', "A path is correct";

is %provides<A::B>, 'lib/A/B.rakumod', "A::B path is correct";

done-testing;
