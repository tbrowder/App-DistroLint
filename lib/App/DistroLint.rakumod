unit module App::DistroLint;

=finish

use JSON::Tiny;

sub to-json(
    Hash %hash
) is export {
    Rakudo::Internals::JSON.to-json: %hash, :pretty, :sorted-keys;
}

sub from-json(
    Str $string
) is export {
    Rakudo::Internals::JSON.from-json: $string;
}

