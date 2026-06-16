#!/usr/bin/env raku

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
