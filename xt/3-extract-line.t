use Test;

use App::DistroLint;

subtest 'multiple statements on one physical line' => {
    my $line = 'use Foo::Bar; need Baz::Qux:ver<1.2>; require Alpha::Beta';

    my @items = extract-dependencies-from-line(
        $line,
        :file<lib/Foo.rakumod>,
        :line-number(7),
    );

    is @items.elems, 3;

    is @items[0].module, 'Foo::Bar';
    is @items[1].module, 'Baz::Qux';
    is @items[1].ver, '1.2';
    is @items[2].module, 'Alpha::Beta';

    for @items -> $item {
        is $item.file, 'lib/Foo.rakumod';
        is $item.line-number, 7;
    }
};

done-testing;
