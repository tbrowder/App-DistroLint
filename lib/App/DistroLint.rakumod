unit module App::DistroLint;

# need a class to hold file error details?
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
    # note the good chunk does NOT consider the closing semicolon
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

    # not a 'use' line
    return %result unless $m;

    # it is a 'use' line
    %result<command> = ~$m[0]; # use|need|require
    %result<module>  = ~$m[1]; # module name without adverbs
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
