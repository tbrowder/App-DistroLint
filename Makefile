bin/dlint: bin/distrolint

	cp bin/distrolint bin/dlint

go:
	raku -Ilib bin/dlint

test:
	touch
