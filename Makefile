PREFIX = /usr/local

test:
	./newf -vf -xt sh 1.sh -TX text 1.py -t ./fun 1.pl

clean:
	echo TODO: rm all files creates by test.

install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	install -m 755 newf $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/man/man1
	install -m 644 newf.1  $(DESTDIR)$(PREFIX)/man/man1

.PHONY: test clean install uninstall
