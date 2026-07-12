use Test;

my @modules = [
   "Tmod",
   "Tmod::A",
   "Tmod::A::B",
];

plan @modules.elems;

for @modules -> $m {
    use-ok $m, "Module '$m' used okay";
}
