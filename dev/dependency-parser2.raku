#!/usr/bin/env raku

use Test;

unless @*ARGS {
    print qq:to/HERE/;
    Usage: {$*PROGRAM-NAME} go

    Runs a copy of the dependency processor
    code to be used in the main module.

    HERE
    exit;
}

# next version

use Text::Utils :strip-comment;
use JSON::Fast;

our regex Verb is export  { use | need | require }
our regex Name is export  { <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>*
                     [ '::' <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>* ]* }
our regex Adv  is export  { ':' $<name>=(ver|auth|api) '<' $<value>=[ <-[>]>+ ] '>' }
our regex ImportTail is export {
    [
        \s+
        [
            ':' <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>*
            | ':' <[A..Z]>+
            | ':' <[\w \-]>+
            | ',' 
            | '(' <-[)]>* ')'
        ]+
    ]?
}

class Dependency is export {
    has Str $.file;
    has Int $.line-number;
    has Str $.statement; # the original use string

    has Str $.command; # use, require, or need
    has Str $.module;  # bare module name

    has Str $.ver  is rw;
    has Str $.auth is rw;
    has Int $.api  is rw;

    method spec(--> Str) {
        my $spec = $!module;
        $spec ~= ":ver<{$!ver}>"   if $!ver.defined;
        $spec ~= ":auth<{$!auth}>" if $!auth.defined;
        $spec ~= ":api<{$!api}>"   if $!api.defined;

        $spec.Str
    }
}

class DependencyError is export {
    has Str $.file;
    has Int $.line-number;
    has Str $.statement;
    has Str $.message;
}

class NilDependency is export {
    has Str $.file;
    has Int $.line-number;
#   has Str $.statement;
    has Str $.message;
}

class DistStatus is export {
    has Str  $.spec;
    has Bool $.installed;
    has Bool $.in-fez;

    method available(--> Bool) {
        $!in-fez
    }
}

say "Working on parsing module statements...";

my @lines = 
'  use  X::Y :tree ; ',
'  require  X::Y:ver<1.1> ; ',
'  need  X::Y ; use Y::Z:<ver<2.0.1> ;',
;

# a simple line splitter
sub split-line(Str $line --> Array) {
    my @deps;
    for $line.split(';') -> $part {
        my %dep = parse-dependency-statement(
                      $part,
                      :file<dummy>,
                      :line-number(0),
                 );
        if %dep.elems {
            @deps.push: %dep;
        }
    }
    return @deps;
}

my @deps;
for @lines -> $line {
    # may have multiple statements
    my @statements = split-line $line;
    for @statements -> $statement {
        say "parsing statement: |$statement|";
        my $dep = parse-dependency-statement(
                      $statement,
                      :file<some-file>,
                      :line-number<1>,
                  );
        #is $dep, DepOrErrOrNil;
        if $dep ~~ Dependency {
            @deps.push: $dep; 
        }
    }
}

subset DepOrErrOrNil of Any where { 
    $_ ~~ any(Dependency, DependencyError, NilDependency) 
}
sub parse-dependency-statement(
    Str $statement,
    Str :$file!,
    Int :$line-number!,
    :$debug,
    --> DepOrErrOrNil
) is export {
    my $m = $statement ~~ /^ \s* <Verb> \s+ <Name> \s* $<advs>=(<Adv>*) \s* $/;

    unless $m {
        return NilDependency.new(
        );
    }



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

    =begin comment
    my $key = %dep<module>;

    for <auth api ver> -> $k {
        if %dep{$k}:exists {
            $key ~= "|$k={%dep{$k}}";
        }
    }

    %dep<key> = $key;
    =end comment

    return %dep;
}
