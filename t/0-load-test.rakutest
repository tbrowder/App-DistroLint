use Test;

my @modules = <
    App::DistroLint
>;

plan @modules.elems;

for @modules -> $m {
    use-ok $m, "Module '$m' used okay";
}
