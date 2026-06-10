bin/dlint: bin/distrolint

	cp bin/dlint bin/distrolint

go:
	raku -Ilib bin/dlint

test:
	touch
