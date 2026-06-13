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

    my @parts = $s.split(';').map(*.trim).grep(*.chars);
    # note prev op will NOT clean multiple white spaces
    # do it this way
    
    my $first = @parts.head;
    unless $line ~~ /^ [use|require|need]/ {
        die qq:to/HERE/;
        FATAL: Unexpected line: '$line'
        HERE
    }

    =begin comment
    if $debug {
        say "DEBUG: input 'use' line: $line";
        say "  pieces:";
        say "  $_" for @pieces;
    }
    =end comment

    my @new-pieces;
    # fix lines with export tags
    for @pieces -> $piece {
        my @w = $piece.words;
        my $line = @w[0, 1].join(" ");
        @new-pieces.push: $line;
    }

    @new-pieces;
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
