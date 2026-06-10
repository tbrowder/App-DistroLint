unit module App::DistroLint;

# need a class to hold file error details
class FileSpec is export {
    has $path;
    has @modules;
    has %adverbs;
}

sub parse-module-spec(
    $line,
    :$debug,
    --> Hash
) is export {

    my %result;
    my $m = $line.match(
        /^ 
        \s* 
        (use|need|require) 
        \s+ 
        (<[\w:]>+) 
        (
            [ 
                ':' (auth|ver|api) '<' (<-[>]>+) '>' 
            ]*
        ) 
        \s+ 
        $/ 
    );

    return %result unless $m;

    %result<command> = ~$m[0];
    %result<module>  = ~$m[1];
    %result<auth>    = Nil;
    %result<ver>     = Nil;
    %result<api>     = Nil;

    my $rest = ~$m[2];

    for $rest ~~ m:g/
        ':' (auth|ver|api) '<' (<-[>]>+) '>' 
    / -> $adv {
        my $kind  = ~$adv[0];
        my $value = ~$adv[1];

        given $kind {
            when 'auth' { 
                return {} if %result<auth>.defined;
                %result<auth> = $value; 
            }
            when 'ver' { 
                return {} if %result<ver>.defined;
                %result<ver> = $value; 
            }
            when 'api' { 
                return {} if %result<api>.defined;
                %result<api> = $value; 
            }
        }
    }

    %result;
} # end of sub parse-module-spec(

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

