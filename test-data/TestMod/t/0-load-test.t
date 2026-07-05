use Test;

my @modules = [
   "SingleCheck",
#  "SingleCheck::Action",
#  "SingleCheck::Data",
   "SingleCheck::FontUtils",
   "SingleCheck::Handlers",
   "SingleCheck::PayTo",
#  "SingleCheck::Template",
   "SingleCheck::Utils",
   "SingleCheck::Vars",
];

plan @modules.elems;

for @modules -> $m {
    use-ok $m, "Module '$m' used okay";
}
