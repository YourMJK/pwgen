.PHONY: build macos linux dir install clean distclean

PRODUCT = pwgen
DEST = build
SWIFTBUILD = swift build -c release --product $(PRODUCT)
BINARY = .build/release/$(PRODUCT)
PREFIX = /usr/local

build: $(BINARY) dir
	@cp -v $(BINARY) $(DEST)/

$(BINARY):
	$(SWIFTBUILD)

macos: BINARY = .build/apple/Products/Release/$(PRODUCT)
macos: dir
	$(SWIFTBUILD) --arch arm64 --arch x86_64
	@cp -v $(BINARY) $(DEST)/$(PRODUCT)_macos

linux: dir
	$(SWIFTBUILD) --static-swift-stdlib
	@cp -v $(BINARY) $(DEST)/$(PRODUCT)_linux

dir:
	@mkdir -p $(DEST)

install: $(BINARY)
	@cp -v $(BINARY) $(PREFIX)/bin/

clean:
	swift package clean
	rm -rf $(DEST)

distclean: clean
	rm -rf Package.resolved
