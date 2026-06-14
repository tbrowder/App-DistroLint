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

    my @modlines = $line.split(';').map(*.trim).grep(*.chars);
    # note prev op will NOT clean multiple white spaces
    # so do that this way
    for @modlines.kv -> $i, $modline is copy {

        unless $modline ~~ /^ [use|require|need]/ {
            die qq:to/HERE/;
            FATAL: Unexpected line without leading 'use|need|require': 
                     '$modline'
            HERE
        }

        # now split again into parts
        my @parts = $modline.words[0..1];
        for @parts.kv -> $j, $part is copy {
             # part 0 is use|need|require
             # part 1 is the module name
             # additional parts are export tags and will be ignored
        }
        $modline = @parts[0..1].join(" ");
        @modlines[$i] = $modline;

        say "modline $i: '$modline'";
    }

    =begin comment
    if $debug {
        say "DEBUG: input 'use' line: $line";
        say "  pieces:";
        say "  $_" for @pieces;
    }
    =end comment

    @modlines;
    =begin comment
    my @new-parts;
    # fix lines with export tags
    for @parts -> $part {
        my @w = $part.words;
        my $line = @w[0, 1].join(" ");
        @new-parts.push: $line;
    }
    @new-parts;
    =end comment

} # end of sub parse-use-line(

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
    %result<command> = ~$m[0]; # use|need|require %result<module>  = ~$m[1]; # module name without adverbs
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
