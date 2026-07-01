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
#our regex ImportTail is export {
#    [ \h .* ]?
#}

class Dependency is export {
    has Str $.file;
    has Int $.line-number;
    has Str $.statement; # the original use string

    has Str $.command; # use, require, or need
    has Str $.module;  # bare module name

    has Str $.ver  is rw;
    has Str $.auth is rw;
    has Int $.api  is rw = Int;

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

class IgnoredStatement is export {
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

sub zef-status(
    Str $spec,
    Callable :$runner = &real-runner,
    :$debug,
    --> DistStatus
) is export {
    my $installed = False;
    my $in-fez    = False;

    # Check installed distributions
    my %p1 = $runner(
        'zef',
        '--installed',
        'list',
    );

    if %p1<exitcode> == 0 {
        for %p1<out>.lines -> $line {
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
    my %p2 = $runner(
        'zef',
        'info',
        $spec,
    );

    if %p2<exitcode> == 0 {
        $in-fez = True;
    }

    return DistStatus.new(
        :$spec,
        :$installed,
        :in-fez($in-fez),
    );
}

subset DepOrErrOrIgn of Any where { 
    $_ ~~ any(Dependency, DependencyError, IgnoredStatement) 
}
my DepOrErrOrIgn $deptyp;
sub parse-dependency-statement(
    Str $statement,
    Str :$file!,
    Int :$line-number!,
    :$debug,
    --> DepOrErrOrIgn
) is export {
	
    unless looks-like-dependency-statement($statement) {
        if $debug { say "DEBUG: does not look like a dep statement"; }
        my $deptyp = IgnoredStatement.new(
            :$file,
            :$line-number,
            :statement($statement),
            :message("not a dependency statement"),
        );
        return $deptyp;
    }

    if $debug { 
        say qq:to/HERE/;
        DEBUG: DOES look like a dep statement:
            statement: '$statement'
        HERE
    }

    my $m = $statement ~~ /^ 
        \s* 
        $<command>=(use|need|require)
        \s* 
        $<module>=(
                   <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>*
            [ '::' <[A..Z a..z _]> <[A..Z a..z 0..9 _ \-]>* ]* 
        )
        \s*
        $<adverbs>=(
            [
                ':' $<name>=(ver|auth|api)
                '<' $<value>=(<-[>]>+)
                '>'
            ]*
        )
        #<.ImportTail>
     [\s .*]?
     \s* $
   /;


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
    my $command = ~$m<command>;
    my $module  = ~$m<module>;
    my $adverbs = ~$m<adverbs>;

    if $debug {
        say "DEBUG \$m";
        say "  command: '$m<command>'";
        say();
    }

    my $dep = Dependency.new(
        :$file,
        :$line-number,
        :$statement,
        :$command,
        :$module,
    );

    my %seen;

    for $adverbs ~~ m:g/
        ':' $<name>=(ver|auth|api)
        '<' $<value>=(<-[>]>+)
        '>'
        / -> $adv {

        my $name  = ~$adv<name>;
        my $value = ~$adv<value>.Str;

        if %seen{$name}:exists {
            # return a DependencyError
            return DependencyError.new(
               :$file,
               :$line-number,
               :statement($statement),
               #:message("duplicate '{:$m<advs>}' adverb"),
               :message("invalid or duplicate adverb"),
            );
        }

        %seen{$name} = True;

        given $name {
            when 'ver'  { $dep.ver  = $value }
            when 'auth' { $dep.auth = $value }
            when 'api'  { 
                unless $value ~~ /^\d+$/ {
                    return DependencyError.new(
                        :$file,
                        :$line-number,
                        :$statement,
                        :message("api value '$value' is not an integer"),
                    );
                }
                $dep.api = $value.Int 
            }
        }
    }
    return $dep;
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

        @deps.push($result);
    }

    return @deps;
}

sub scan-distribution(
    IO::Path $root,
    :$debug = False,
    --> Hash
) is export {
    my @dependencies;
    my @errors;

    my @dirs = <lib t rakutest xt bin>;

    for @dirs -> $dir-name {
        my $dir = $root.add($dir-name);
        next unless $dir.d;

        for $dir.dir(:recursive) -> $path {
            next unless $path.f;

            my $rel = $path.relative($root).Str;
            my $line-number = 0;

            for $path.lines -> $raw-line is copy {
                ++$line-number;

                my $line = strip-comment $raw-line;
                next unless $line ~~ /\S/;
                next if $line ~~ /^ \h* '=' /;

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
    Str :$self-top!,
    --> Hash
) is export {
    my %depends       is SetHash;
    my %build-depends is SetHash;
    my %test-depends  is SetHash;

    for @dependencies -> $dep {
        next unless $dep ~~ Dependency;

        my $spec = $dep.spec;
        my $module-top = top-module($dep.module);

        next if $module-top eq $self-top;

        my $file = $dep.file;

        if $file.starts-with('t/')
            or $file.starts-with('xt/')
            or $file.starts-with('rakutest/') {

            %test-depends{$spec} = True;
        }
        elsif $file eq 'Build.rakumod'
            or $file eq 'Build.pm6'
            or $file eq 'build.raku'
            or $file.starts-with('build/')  {

            %build-depends{$spec} = True;
        }
        elsif $file.starts-with('lib/')
            or $file.starts-with('bin/') {

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
    my %new-depends       is SetHash;
    my %new-build-depends is SetHash;
    my %new-test-depends  is SetHash;

    for %depends.keys -> $spec {
        %new-depends{$spec} = True;
    }

    for %build-depends.keys -> $spec {
        next if %new-depends{$spec}:exists;

        %new-build-depends{$spec} = True;
    }

    for %test-depends.keys -> $spec {
        next if %new-depends{$spec}:exists;
        next if %new-build-depends{$spec}:exists;

        %new-test-depends{$spec} = True;
    }

    return %(
        depends       => %new-depends,
        build-depends => %new-build-depends,
        test-depends  => %new-test-depends,
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
                (module|class|role|grammar|package)
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

   %(
        exitcode => $p.exitcode,
        out      => $p.out.slurp,
        err      => $p.err.slurp,
    );
}

sub top-module(
    Str:D $name,
    :$debug,
    --> Str
) is  export {
    return $name.split('::')[0];
}

sub primary-top-module(
    %provides,
    :$debug,
    --> Str
) is export {
    for %provides.keys.sort -> $module {
        return top-module($module);
    }

    return '';
}

sub write-issues-file(
    IO::Path $root,
    @errors,
    @issues,
    --> IO::Path
) is export {
    my $out = $root.add('LintNotes.txt');

    my @lines;

    @lines.push('App::DistroLint Notes');
    @lines.push('=====================');
    @lines.push('');

    if @errors.elems {
        @lines.push('Dependency Parse Errors');
        @lines.push('-----------------------');

        for @errors -> $err {
            @lines.push("{$err.file}:{$err.line-number}: {$err.message}");
            @lines.push("    {$err.statement}");
            @lines.push('');
        }
    }

    if @issues.elems {
        @lines.push('META6.json Issues');
        @lines.push('-----------------');

        for @issues -> $issue {
            @lines.push("  $issue");
        }

        @lines.push('');
    }

    $out.spurt(@lines.join("\n") ~ "\n");

    return $out;
}

sub write-corrected-meta6(
    IO::Path $meta-path,
    $meta,
    :%depends!,
    :%build-depends!,
    :%test-depends!,
    :%provides!,
    --> IO::Path
) is export {

    my $new-meta = $meta.clone;

    $new-meta<depends> =
        %depends.keys.sort.Array;

    $new-meta<build-depends> =
        %build-depends.keys.sort.Array;

    $new-meta<test-depends> =
        %test-depends.keys.sort.Array;

    my %new-provides;

    for %provides.keys.sort -> $module {
        %new-provides{$module} = %provides{$module};
    }

    $new-meta<provides> = %new-provides;

    my $outfile =
        $meta-path.parent.add('new-META6.json');

    $outfile.spurt(
        to-json(
            $new-meta,
            :pretty,
            :sorted-keys,
        )
    );

    return $outfile;
}

sub looks-like-dependency-statement(
    $statement
    --> Bool
) is export {
    if $statement ~~ /^ \s* (use|need|require) \s+ / {
        return True;
    }
    return False;
}

