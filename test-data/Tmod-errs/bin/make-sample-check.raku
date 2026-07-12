#!/usr/bin/env raku

use JSON::Fast;

use Tmod; 
use Tmod::A; 
use Tmod::A::B; 

my $acct  = "sample-account"; # use a default
my $amt   = 0;
my $memo  = "";
my $payee = "";
my $date  = Date.today;
