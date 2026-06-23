use Test;
use App::DistroLint;

subtest 'duplicate adverbs are errors' => {
    my $err = parse-dependency-statement(
        'use Foo::Bar:ver<1>:ver<2>',
        :file<lib/Foo.rakumod>,
        :line-number(20),
    );

    isa-ok $err, DependencyError;
    is $err.file, 'lib/Foo.rakumod';
    is $err.line-number, 20;
    like $err.message, /duplicate/;
    like $err.message, /ver/;
};

subtest 'unknown adverb is an error' => {
    my $err = parse-dependency-statement(
        'use Foo::Bar:xyz<abc>',
        :file<lib/Foo.rakumod>,
        :line-number(21),
    );

    isa-ok $err, DependencyError;
    like $err.message, /unknown|invalid/;
};

done-testing;
