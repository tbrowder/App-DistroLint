bin/dlint: bin/distrolint

	cp bin/distrolint bin/dlint

go:
	raku run -Ilib bin/dlint
