unit module App::DistroLint;

=begin comment

Raku Dependency Parser Example

Contents:
- dependency-parser.raku

Parses dependency statements of the form:

    use Module::Name:auth<sue>:api<3>:ver<0.1>;
    need Other::Module;
    require Third::Module:ver<1.2>;

Multiple statements may appear on a line separated by semicolons.

The parser returns a normalized key in canonical order:
    Module::Name|auth=sue|api=3|ver=0.1

=end comment

use Text::Utils :strip-comment;

my regex Verb   { use | need | require }
my regex Name   { <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>* [ '::' <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>* ]* }
my regex Adv    { ':' $<name>=(auth|api|ver) '<' $<value>=[ <-[>]>+ ] '>' }

sub parse-dependency(Str $text --> Hash) {
    my $m = $text ~~ /^ \s* <Verb> \s+ <Name> \s* $<advs>=(<Adv>*) \s* $/;

    return %() unless $m;

    my %dep =
        verb   => ~$m<Verb>,
        module => ~$m<Name>,
    ;

    for $m<advs><Adv> -> $a {
        my $name  = ~$a<name>;
        my $value = ~$a<value>;

        return %() if %dep{$name}:exists;

        %dep{$name} = $value;
    }

    my $key = %dep<module>;

    for <auth api ver> -> $k {
        if %dep{$k}:exists {
            $key ~= "|$k={%dep{$k}}";
        }
    }

    %dep<key> = $key;

    return %dep;
}

sub parse-line(Str $line --> Array) {
    my @deps;

    for $line.split(';') -> $part {
        my %dep = parse-dependency($part);

        if %dep.elems {
            @deps.push: %dep;
        }
    }

    return @deps;
}

