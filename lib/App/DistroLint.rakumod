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

our regex Verb is export  { use | need | require }
our regex Name is export  { <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>*
                   [ '::' <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>* ]* }
our regex Adv  is export  { ':' $<name>=(ver|auth|api) '<' $<value>=[ <-[>]>+ ] '>' }

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

class DistStatus is export {
    has Str  $.spec;
    has Bool $.installed;
    has Bool $.in-fez;
}

sub zef-status(
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

    # Not installed, check whether fez can find it in the ecosystem
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

subset DepOrErr where Dependency | DependencyError;
sub parse-dependency-statement(
    Str $statement,
    Str :$file!,
    Int :$line-number!,
    :$debug,
    --> DepOrErr
) is export {
    #                    use|need|require
    my $m = $statement ~~ /^ \s* <Verb> \s+ <Name> \s* $<advs>=(<Adv>*) \s* $/;

    unless $m {
        return DependencyError.new(
            :$file,
            :$line-number,
            :statement($statement),
            #:message("duplicate '{:$m<advs>}' adverb"),
            :message("invalid or duplicate adverb"),
        );
    }

    # fill the dep with data from $m
    my %dep =
        verb   => ~$m<Verb>,
        module => ~$m<Name>,
    ;

    for $m<advs><Adv> -> $a {
        my $name  = ~$a<name>;
        my $value;
        if $name eq 'api' {
            $value = +$a<value>;
        }
        else {
            $value = ~$a<value>;
        }

        # return a DependencyError
        if %dep{$name}:exists {
            return DependencyError.new(
                :$file,
                :$line-number,
                :statement($statement),
                #:message("duplicate '{:$m<advs>}' adverb"),
                :message("invalid or duplicate adverb"),
            )
        }

        %dep{$name} = $value;
    }

    my $dep = Dependency.new(
        :$file,
        :$line-number,
        :statement($statement),

        :command(%dep<verb>),
        :module(%dep<module>),

    );
    # other parts if they exist
    $dep.ver  = %dep<ver>  if %dep<ver>:exists;
    $dep.auth = %dep<auth> if %dep<auth>:exists;
    $dep.api  = %dep<api>  if %dep<api>:exists;

    $dep

}

sub extract-dependencies-from-line(
    Str  $line,
    Str :$file!,
    Int :$line-number!,
    :$debug,
     --> Array
) is export {
    my @deps; # = [];

    return @deps unless $line.trim.chars;

    my @parts = $line.split(';');
    if $debug {
        say "DEBUG: splitting line '\$line' on semicolons";
        say " '$_'" for @parts;
        say "early exit";
        exit(1);
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

    return @deps;
}

sub write-new-meta6(
    $meta-path,
    @source-deps,
    --> Bool
) is export {
    # checks and writes a new version only if needed
    my $json = $meta-path.slurp;
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

    my %new-depends is SetHash;
    my %new-build   is SetHash;
    my %new-test    is SetHash;

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

    my $out = $meta-path.parent.add('new-META6.json');
    $out.spurt(to-json($meta, :sorted-keys));

    True;
}

sub scan-distribution(
    IO::Path $root,
    :$debug = False,
    --> Hash
) is export {
    my @dependencies;
    my @errors;

    my @dirs = <lib t rakutest xt bin sbin>;

    for @dirs -> $dir-name {
        my $dir = $root.add($dir-name);
        next unless $dir.d;

        for $dir.dir(:recursive) -> $path {
            next unless $path.f;

            my $rel = $path.relative($root).Str;
            my $line-number = 0;

            for $path.lines -> $line {
                ++$line-number;

                my @items = extract-dependencies-from-line(
                    $line,
                    :file($rel),
                    :$line-number,
                    :$debug,
                );

                for @items -> $item {
                    if $item ~~ Dependency {
                        @dependencies.push($item);
                    }
                    elsif $item ~~ DependencyError {
                        @errors.push($item);
                    }
                }
            }
        }
    }

    return %(
        dependencies => @dependencies,
        errors       => @errors,
    );
}

sub classify-dependencies(
    @dependencies,
    --> Hash
) is export {
    my %depends       is SetHash;
    my %build-depends is SetHash;
    my %test-depends  is SetHash;

    for @dependencies -> $dep {
        next unless $dep ~~ Dependency;

        my $spec = $dep.spec;
        my $file = $dep.file;

        if $file.starts-with('t/')
            or $file.starts-with('xt/')
            or $file.starts-with('rakutest/') {

            %test-depends{$spec} = True;
        }
        elsif $file eq 'Build.rakumod'
            or $file eq 'Build.pm6'
            or $file eq 'build.raku'
            or $file.starts-with('build/') {

            %build-depends{$spec} = True;
        }
        elsif $file.starts-with('lib/')
            or $file.starts-with('bin/')
            or $file.starts-with('sbin/') {

            %depends{$spec} = True;
        }
    }

    return %(
        depends       => %depends,
        build-depends => %build-depends,
        test-depends  => %test-depends,
    );
}

sub canonicalize-meta-dependency-sets(
    :%depends!,
    :%build-depends!,
    :%test-depends!,
    --> Hash
) is export {
    my %new-depends is SetHash;

    my $i = 0;
    for %depends.keys -> $spec {
        ++$i;
        if $i == 1 {
            # initiate new SetHash
            %new-depends = ($spec);
            next;
        }
        %new-depends (|)= ($spec);
        #%new-depends{$spec} = True;
    }

    =begin comment
    for %build-depends.keys -> $spec {
        next if %new-depends{$spec}:exists;
        %new-build-depends{$spec} = True;
    }

    for %test-depends.keys -> $spec {
        next if %new-depends{$spec}:exists;
        next if %new-build-depends{$spec}:exists;
        %new-test-depends{$spec} = True;
    }
    =end comment

    return %(
    #   depends       => %new-depends,
    #   build-depends => %new-build-depends,
    #   test-depends  => %new-test-depends,
    );
}

sub read-meta6(
    IO::Path $meta-path,
    --> Associative
) is export {
    my $json = $meta-path.slurp;
    my $meta = from-json($json);

    die "META6.json top-level object is not associative"
        unless $meta ~~ Associative;

    return $meta;
}

sub build-provides-map(
    IO::Path $root,
    --> Hash
) is export {
    my %provides;

    my $lib = $root.add('lib');
    return %provides unless $lib.d;

    for $lib.dir(:recursive) -> $path {
        next unless $path.f;

        my $rel = $path.relative($root).Str;

        for $path.lines -> $line {
            my $m = $line.match(
                /^
                \s*
                [unit \s+]?
                [module|class|role|grammar|package]
                \s+
                (<[\w]>+ [ '::' <[\w]>+ ]*)
                /
            );

            if $m {
                my $module = ~$m[0];
                %provides{$module} = $rel;
                last;
            }
        }
    }

    return %provides;
}

sub analyze-meta6(
    $meta,
    :%depends!,
    :%build-depends!,
    :%test-depends!,
    :%provides!,
    --> Hash
) is export {
    my @issues;

    my %meta-dep;
    for $meta<depends> // [] -> $spec {
        if %meta-dep{$spec}:exists {
            @issues.push("duplicate depends entry: $spec");
        }
        %meta-dep{$spec} = True;
    }

    my %meta-build;
    for $meta<build-depends> // [] -> $spec {
        if %meta-build{$spec}:exists {
            @issues.push("duplicate build-depends entry: $spec");
        }
        %meta-build{$spec} = True;
    }

    my %meta-test;
    for $meta<test-depends> // [] -> $spec {
        if %meta-test{$spec}:exists {
            @issues.push("duplicate test-depends entry: $spec");
        }
        %meta-test{$spec} = True;
    }

    for %depends.keys -> $spec {
        unless %meta-dep{$spec}:exists {
            @issues.push("missing depends entry: $spec");
        }
    }

    for %build-depends.keys -> $spec {
        unless %meta-build{$spec}:exists {
            @issues.push("missing build-depends entry: $spec");
        }
    }

    for %test-depends.keys -> $spec {
        unless %meta-test{$spec}:exists {
            @issues.push("missing test-depends entry: $spec");
        }
    }

    my $meta-provides = $meta<provides> // {};

    for %provides.keys -> $module {
        if not $meta-provides{$module}:exists {
            @issues.push("missing provides entry: $module");
        }
        elsif $meta-provides{$module} ne %provides{$module} {
            @issues.push(
                "wrong provides path for $module: "
                ~ "{$meta-provides{$module}} should be {%provides{$module}}"
            );
        }
    }

    for $meta-provides.keys -> $module {
        unless %provides{$module}:exists {
            @issues.push("stale provides entry: $module");
        }
    }

    return %(
        issues => @issues,
    );
}

sub real-runner(*@cmd --> Hash) is export {
    my $p = run |@cmd, :out, :err;

    return %(
        exitcode => $p.exitcode,
        out      => $p.out.slurp,
        err      => $p.err.slurp,
    );
}
