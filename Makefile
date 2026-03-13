PREFIX = /usr/local
TESTDIR = t

test:
	prove -r $(TESTDIR)

clean:
	rm -rf $(TESTDIR)/templ $(TESTDIR)/config/newf

install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	install -m 755 src/newf $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/man/man1
	install -m 644 doc/newf.1  $(DESTDIR)$(PREFIX)/man/man1

.PHONY: test clean install uninstall
