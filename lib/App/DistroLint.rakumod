unit module App::DistroLint;

use Text::Utils :strip-comment;

# need a class to hold file error details?
class FileSpec is export {
    has $path;
    has @modules;
    has %adverbs;
}

sub parse-use-line(
    $line is copy,
    :$debug,
    --> List
) is export {
    $line = strip-comment $line;
    unless $line ~~ /\S/ {
        die qq:to/HERE/;
        FATAL: Unexpected empty line...
        HERE
    }

    my @parts = $line.split(';').map(*.trim).grep(*.chars);
    # note prev op will NOT clean multiple white spaces
    # do that this way
    for @parts.kv -> $i, $part is copy {
        $part = $part.words.join(" ");
        say "part $i: '$part'";
        @parts[$i] = $part;
    }
    
    my $first = @parts.head;
    unless $line ~~ /^ [use|require|need]/ {
        die qq:to/HERE/;
        FATAL: Unexpected line without leading 'use|need|require': 
                 '$line'
        HERE
    }

    =begin comment
    if $debug {
        say "DEBUG: input 'use' line: $line";
        say "  pieces:";
        say "  $_" for @pieces;
    }
    =end comment

    my @new-parts;
    # fix lines with export tags
    for @parts -> $part {
        my @w = $part.words;
        my $line = @w[0, 1].join(" ");
        @new-parts.push: $line;
    }

    @new-parts;
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
