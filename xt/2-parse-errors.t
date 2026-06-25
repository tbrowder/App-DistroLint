use Test;

use App::DistroLint;

subtest 'duplicate adverbs are errors' => {
    # an error return
    my $dep = parse-dependency-statement(
        'use Foo::Bar:ver<1>:ver<2>',
        :file<lib/Foo.rakumod>,
        :line-number(20),
    );

    isa-ok $dep, DependencyError;
    is $dep.file, 'lib/Foo.rakumod';
    is $dep.line-number, 20;
    #like $dep.message, /duplicate/;
    #like $dep.message, /ver/;
};

=begin comment
subtest 'unknown adverb is an error' => {
    my $err = parse-dependency-statement(
        'use Foo::Bar:xyz<abc>',
        :file<lib/Foo.rakumod>,
        :line-number(21),
    );

    isa-ok $err, DependencyError;
    like $err.message, /unknown|invalid/;
};
=end comment

done-testing;
