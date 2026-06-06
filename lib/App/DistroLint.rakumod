unit module App::DistroLint;

sub to-json(
    Hash %hash
) is export {
    Rakudo::Internals::to-json %hash;
}

sub from-json(
    Str $string
) is export {
    Rakudo::Internals::from-json $string;
}

