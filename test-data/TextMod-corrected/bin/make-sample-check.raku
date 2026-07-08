#!/usr/bin/env raku

use JSON::Fast;

use SingleCheck; 

my $acct  = "sample-account"; # use a default
my $cnum  = get-next-check-number $acct;
my $amt   = 0;
my $memo  = "";
my $payee = "";
my $data  = Date.today;

# public data
my %layout = load-layout("check-layouts/hancock-whitney.json");

=begin comment

# all following is private data
# kept in json files in the user's $*HOME/.SingleCheck directory
# in files ? and ?

my %data = %(
        # constant data per account
);
        
my %check = %(
        # data varying per check
);

render-check(
    :outfile("output/anytown-sample.pdf"),
    :layout(%layout),
    :%data,
);

#store-check(
#) {
#}

say "Wrote output/anytown-sample-check.pdf";

=end comment
