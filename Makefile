PRODUCT = pwgen
DIR = bin
SWIFTBUILD = swift build -c release --product $(PRODUCT)
BINARY = .build/release/$(PRODUCT)
PREFIX = /usr/local

.PHONY: build $(BINARY) macos linux install uninstall clean distclean

build: $(BINARY) $(DIR)
	@cp -v $(BINARY) $(DIR)/

$(BINARY):
	$(SWIFTBUILD)

$(DIR):
	mkdir $(DIR)

macos: BINARY = .build/apple/Products/Release/$(PRODUCT)
macos: $(DIR)
	$(SWIFTBUILD) --arch arm64 --arch x86_64
	@cp -v $(BINARY) $(DIR)/$(PRODUCT)_macos

linux: $(DIR)
	$(SWIFTBUILD) --static-swift-stdlib
	@cp -v $(BINARY) $(DIR)/$(PRODUCT)_linux

install: $(BINARY)
	@cp -v $(BINARY) $(PREFIX)/bin/

uninstall:
	rm -f $(PREFIX)/bin/$(PRODUCT)

clean:
	swift package clean
	rm -rf $(DIR)

distclean: clean
	rm -rf Package.resolved
