unit module App::DistroLint;

=begin comment

Raku Dependency Parser Example

Contents:
- dependency-parser.raku

Parses dependency statements of the form:

    use Module::Name:ver<0.1>:auth<sue>:api<3>;
    need Other::Module;
    require Third::Module:ver<1.2>;

Multiple statements may appear on a line separated by semicolons.

The parser returns a normalized key in canonical order:
    Module::Name|ver=0.1|auth=sue|api=3

=end comment

use Text::Utils :strip-comment;
use JSON::Fast;

my regex Verb   { use | need | require }
my regex Name   { <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>*
                   [ '::' <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>* ]* }
my regex Adv    { ':' $<name>=(ver|auth|api) '<' $<value>=[ <-[>]>+ ] '>' }

class Dependency is export {
    has Str $.file;
    has Int $.line-number;

    has Str $.statement; # the original use string

    has Str $.command; # use, require, or need
    has Str $.module;  # bare module name

    has Str $.ver  is rw;
    has Str $.auth is rw;
    has Str $.api  is rw;

    method spec(--> Str) {
        my $spec = $.module;
        $spec ~= ":ver<{$!ver}>"   if $!ver.defined;
        $spec ~= ":auth<{$!auth}>" if $!auth.defined;
        $spec ~= ":api<{$!api}>"   if $!api.defined;

        $spec
    }

}

class DependencyError is export {
    has Str $.file;
    has Int $.line-number;
    has Str $.statement;
    has Str $.message;
}

class DistStatus is export {
    has Str  $.spec;
    has Bool $.installed;
    has Bool $.in-fez;
}

sub zef-status( # was: dist-status(
    Str $spec,
    :$debug,
    --> DistStatus
) is export {
    my $installed = False;
    my $in-fez    = False;

    # Check installed distributions
    my $p1 = run 'zef', '--installed', 'list', :out, :err;
    if $p1.exitcode == 0 {
        for $p1.out.slurp.lines -> $line {
            if $line.starts-with($spec) {
                 $installed = True;
                 last;
            }
        }
    }

    # If already installed, no reason to query fez
    if $installed {
        return DistStatus.new(
            :$spec,
            :$installed,
            :in-fez(True),
        );
    }

    # Check whether fez can find it in the ecosystem
    my $p2 = run 'zef', 'info', $spec, :out, :err;

    if $p2.exitcode == 0 {
        $in-fez = True;
    }

    return DistStatus.new(
        :$spec,
        :$installed,
        :in-fez,
    );

}

sub parse-dependency-statement( # was parse-module-spec
    Str:D $statement where *.chars,
    Str:D :$file!,
    Int:D :$line-number!,
    :$debug,
) is export {
    #                    use|need|require
    my $m = $statement ~~ /^ \s* <Verb> \s+ <Name> \s* $<advs>=(<Adv>*) \s* $/;

    unless $m {
        return DependencyError.new(
            :$file,
            :$line-number,
            :statement($statement),
	    :message("duplicate :$m<advs adverb"),
	);
    }

    return Dependency.new(
	:$file,
	:$line-number,
	:statement($statement),

        :command(%dep<verb>),
        :module(%dep<module>),

        :ver(%dep<ver>),
        :auth(%dep<auth>),
        :api(%dep<api>),
    );
}

sub extract-dependencies-from-line( # was parse-line(
    #Str:D  $line,
    Str:D  $statement,
    Str:D :$file!,
    Int:D :$line-number!,
    :$debug,
     --> Array
) is export {
    my @deps = [];

    #return @deps unless $line.trim.chars;
    return @deps unless $statement.trim.chars;

    =begin comment
    my @parts = $line.split(';');
    if $debug {
        say "DEBUG: splitting line '\$line' on semicolons";
        say " '$_'" for @parts;
        say "early exit"; exit(1);
    }

    for @parts -> $part is copy {
        $part .= trim;
        next unless $part.chars;
        my $result = parse-dependency-statement(
            $part,
            :$file,
            :$line-number,
        );

        if $result ~~ Dependency {
             @deps.push($result);
        }
        else {
            @deps.push($result);   # DependencyError object
        }
    }
    =end comment

    return @deps;
}

# IO::Path $meta-path,
sub write-new-meta6(
    $meta-path,
    @source-deps,
    --> Bool
) is export {
    # check and writes a new version only if needed
    my $json = $meta-path.IO.slurp;
    my $meta = from-json $json;

    my @depends;
    my @build-depends;
    my @test-depends;

    # collect existing, remove duplicates
    my %seen-dep;
    for $meta<depends> // [] -> $spec {
        next if %seen-dep{$spec}++;
        @depends.push: $spec;
    }

    my %seen-test;
    for $meta<test-depends> // [] -> $spec {
        next if %seen-test{$spec}++;
        @test-depends.push: $spec;
    }

    my %seen-build;
    for $meta<build-depends> // [] -> $spec {
        next if %seen-build{$spec}++;
        @build-depends.push: $spec;
    }

=begin comment
    $meta<depends>       = @depends;
    $meta<test-depends>  = @test-depends;
    $meta<build-depends> = @build-depends;
=end comment

    my SetHash %new-depends;
    my SetHash %new-build;
    my SetHash %new-test;

    # overlaps
    my @dep-test-overlap;
    my @dep-build-overlap;
    my @build-test-overlap;

    for @depends -> $spec {
        %new-depends{$spec} = True;
    }

    for @build-depends -> $spec {
        next if %new-depends{$spec}:exists;
        %new-build{$spec} = True;
    }

    for @test-depends -> $spec {
        next if %new-depends{$spec}:exists;
        next if %new-build{$spec}:exists;
        %new-test{$spec} = True;
    }

    # report what was removed

#=begin comment
    my $out = $meta-path.IO.parent.add('new-META6.json');
    $out.spurt(to-json($meta, :sorted-keys));

    True;
#=end comment

}
