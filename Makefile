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
	mkdir -p $(DESTDIR)/usr/share/fish/vendor_completions.d
	install -m 644 shell/newf.fish \
		$(DESTDIR)/usr/share/fish/vendor_completions.d/newf.fish

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/newf
	rm -f $(DESTDIR)$(PREFIX)/man/man1/newf.1
	rm -f $(DESTDIR)/usr/share/fish/vendor_completions.d/newf.fish

.PHONY: test clean install uninstall
