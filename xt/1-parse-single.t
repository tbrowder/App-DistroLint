use Test;

use App::DistroLint;

subtest 'valid single dependency statements' => {
    my $dep = parse-dependency-statement(
        'use Foo::Bar:ver<0.2>:auth<sue>:api<3>',
        :file<lib/Foo.rakumod>,
        :line-number(12),
    );

    isa-ok $dep, Dependency;
    is $dep.command, 'use';
    is $dep.module, 'Foo::Bar';
    is $dep.ver, '0.2';
    is $dep.auth, 'sue'; 
    is $dep.api, 3;
    is $dep.file, 'lib/Foo.rakumod';
    is $dep.line-number, 12;
    isa-ok $dep.spec, Str;
};

subtest 'valid statement without adverbs' => {
    my $dep = parse-dependency-statement(
        'need Baz::Qux',
        :file<t/basic.rakutest>,
        :line-number(5),
    );

    isa-ok $dep, Dependency;
    is $dep.line-number, 5;
    is $dep.command, 'need';
    is $dep.module, 'Baz::Qux';

    nok $dep.ver.defined;
    nok $dep.auth.defined;
    nok $dep.api.defined;
};

done-testing;
