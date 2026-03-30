prefix ?= /usr/local
bindir = $(prefix)/bin
appdir = $(prefix)/Applications

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(appdir)/gpad2mouse.app/Contents/MacOS"
	install ".build/release/gpad2mouse" "$(appdir)/gpad2mouse.app/Contents/MacOS/"
	install -m 644 Info.plist "$(appdir)/gpad2mouse.app/Contents/"
	install -d "$(bindir)"
	ln -sf "../Applications/gpad2mouse.app/Contents/MacOS/gpad2mouse" "$(bindir)/gpad2mouse"

clean:
	rm -rf .build

.PHONY: build install clean
