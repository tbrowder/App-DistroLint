use Test;

use File::Temp;
use File::Find;
use File::Directory::Tree;

use Mi6::Helper;
use Mi6::Helper::Utils;

my $debug = 1;

#my $tdir = tempdir;
my $tdir = "./bad/tmp";
rmtree $tdir if $tdir.IO ~~ :d;
mkdir $tdir;

my ($proc);
lives-ok {
    say "Running 'mi6-helper'...";
    #$proc = run "mi6-helper", "force", "dir=$tdir", "new=Foo::Bar", :out, :err;
    run "bin/mi6-helper", "force", "dir=$tdir", "new=Foo::Bar";
=begin comment
    my $e = $proc.exitcode;
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
   say "exitcode: $e" if $debug;
    say "out: $out" if $debug;
    say "err: $err" if $debug;
=end comment 
}, "gen new mod Foo::Bar in dir '$tdir'";

#dies-ok {
#   $proc = run "mi6-helper", "force", "dir=$tdir", "new=Foo::Bar", :out, :err;
#}

=finish

#say $proc.raku;
if $proc.err.open.so {
    say "err is still open";
}
if $proc.out.open {
    say "out is still open";
}

say $proc.out.close.so;

    #die "FATAL" unless $proc.defined;
    #die "FATAL" if $proc.exitcode ~~ /Nil/; #.defined;
    #die "FATAL" if $proc.exitcode ~~ /Nil/; #.defined;
    #die "FATAL" if $proc.exitcode != 0; #~~ /Nil/; #.defined;
#   die "FATAL" if $proc !~~ Proc;
#   die "FATAL" if $proc.exitcode != 0; #~~ /Nil/; #.defined;

#say $proc.gist;

    =begin comment
    die "FATAL" unless $e.defined;
    say "exitcode: $e";
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
    say "out: $out";
    say "err: $err";
    =end comment
#}, "no force used";

#rmdir $tmpdir;
