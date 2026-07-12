unit module TestMod:PayTo;

# the entry sub
sub pay-to($curdir, :$afil, :$cfil, :$debug) is export {
    # initialize data with defaults
    my $date = Date.new: now;
    my @keys = <date pay-to amount memo>;
    my %inputs = [
        date   => $date,
        pay-to => "",
        amount => 0,
        memo   => "",
    ];

    while 1 {
        say();
        get-user-inputs :%inputs, :@keys, :$debug;
        say();
        say "Your entries:";
        for @keys -> $k {
            my $v = %inputs{$k};
            say "  $k: $v";
        }
        my $answer = prompt "satisfactory (Y/n)? ";
        if $answer !~~ /:i n/ {
            say "Good...";
            last;
        }
        else {
            say "Sorry, try again...";
        }
    }

    say();
    say "Preparing the check with your inputs...";
    if $debug {
        my $amount = %inputs<amount>;
#       my $f = Amount.new: :$amount;
#       say "DEBUG: amount is '{$f.amount}'";
    }

    my $df = $*FILE;
    my $sr = &?ROUTINE.name;
    note qq:to/HERE/;
    in file '$df'
    in sub  '$sr'
    Tom, finish this file: $df
    in subroutine: $sr
    HERE

    "FAKE PATH TO PDF CHECK"
}


# use the inputs to name the PDF file:
#   check-<bank>-<number>-<date>.pdf

#### subs ####
sub get-user-inputs(:%inputs!, :@keys!, :$debug) {
    %inputs<date>   = get-user-date :date(%inputs<date>), :$debug;
    %inputs<pay-to> = get-user-pay-to :pay-to(%inputs<pay-to>), :$debug;
    %inputs<amount> = get-user-amount :amount(%inputs<amount>), :$debug;
    %inputs<memo>   = get-user-memo :memo(%inputs<memo>), :$debug;
}

sub get-user-date(Date :$date! is copy, :$debug --> Date) {
    while 1 {
        my $answer = prompt "date (default: $date): ";
        if not $answer {
            # user accepts default input
            last;
        }
        elsif $answer !~~ /^\h* \d ** 4 '-' \d\d '-' \d\d \h* $/ {
            # check format
            say "  ERROR: enter date as 'yyyy-mm-dd'";
        }
        else {
            $date = Date.new: $answer;
            last
        }
    }
    $date
}

sub get-user-pay-to(Str :$pay-to is copy = "", :$debug --> Str) {
    my $prompt-str;
    if $pay-to {
        $prompt-str = "pay-to (default: $pay-to): ";
    }
    else {
        $prompt-str = "pay-to: ";
    }
    while 1 {
        my $answer = prompt $prompt-str;
        if not $answer {
            # user accepts default input
            last
        }
        else {
            $pay-to = $answer;
            last if $answer and $answer ~~ Str;
            say "  ERROR: input '$answer' is not a string or is empty";
        }
    }
    $pay-to;
}

sub get-user-amount(Real :$amount is copy = 0, :$debug --> Real) {
    my $prompt-str;
    if $amount {
        $prompt-str = "amount (default: $amount): ";
    }
    else {
        $prompt-str = "amount: ";
    }
    while 1 {
        my $answer = prompt $prompt-str;
        if not $answer {
            # user accepts default input
            last
        }
        else {
            $amount = $answer;
            if $amount ~~ Real {
                # user accepts default input
                last
            }
            else {
                say "  ERROR: input $amount is not a Real";
            }
        }
    }
    $amount
}

sub get-user-memo(Str :$memo is copy  = "", :$debug --> Str) {
    my $prompt-str;
    if $memo {
        $prompt-str = "memo (default: $memo): ";
    }
    else {
        $prompt-str = "memo: ";
    }
    while 1 {
        my $answer = prompt $prompt-str;
        if not $answer {
            # user accepts default input
            last
        }
        else {
            $memo = $answer;
            last if $answer and $answer ~~ Str;
            say "  ERROR: input $answer is not a number";
        }
    }
    $memo
}
