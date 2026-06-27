use Test;

my $exe  = "bin/dlint".IO;
my $exe2 = "bin/distrolint".IO;

ok $exe.f,  "bin/dlint exists";
ok $exe2.f, "bin/distrolint exists";

my $proc = run 
    $*EXECUTABLE,
   '-Ilib',
    $exe,
    :out,
    :err;

my $ecode = $proc.exitcode;
isnt $proc.exitcode, 0, "dlint exits successfully with a default usage statement";
say "exit code is not zero but > 0 as expected. actual value: $ecode";
my $out = $proc.out.slurp(:close).chomp;
my $err = $proc.err.slurp(:close).chomp;
say "out: '$out'";
say "err: '$err'";
like $err, /Usage:/, "usage message printed";

$proc = run 
    $*EXECUTABLE,
   '-Ilib',
    $exe2,
    :out,
    :err;

$ecode = $proc.exitcode;
isnt $proc.exitcode, 0, "dlint exits successfully with a default usage statement";
say "exit code is not zero but > 0 as expected. actual value: $ecode";
$out = $proc.out.slurp(:close).chomp;
$err = $proc.err.slurp(:close).chomp;
say "out: '$out'";
say "err: '$err'";
like $err, /Usage:/, "usage message printed";

done-testing;

