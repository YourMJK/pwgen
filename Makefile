PRODUCT = pwgen
DIR = bin
SWIFTBUILD = swift build -c release --product $(PRODUCT)
BINARY = .build/release/$(PRODUCT)
MANUAL = .build/plugins/GenerateManual/outputs/$(PRODUCT)/$(PRODUCT).1
PREFIX = /usr/local

.PHONY: build $(BINARY) $(MANUAL) macos linux install uninstall clean distclean

build: $(BINARY) $(DIR)
	@cp -v $(BINARY) $(DIR)/

$(BINARY):
	$(SWIFTBUILD)

$(MANUAL):
	swift package plugin generate-manual

$(DIR):
	mkdir $(DIR)

macos: BINARY = .build/apple/Products/Release/$(PRODUCT)
macos: $(DIR)
	$(SWIFTBUILD) --arch arm64 --arch x86_64
	@cp -v $(BINARY) $(DIR)/$(PRODUCT)_macos

linux: $(DIR)
	$(SWIFTBUILD) --static-swift-stdlib
	@cp -v $(BINARY) $(DIR)/$(PRODUCT)_linux

install: $(BINARY) #$(MANUAL)
	@cp -v $(BINARY) $(PREFIX)/bin/
	@#cp -v $(MANUAL) $(PREFIX)/share/man/man1/

uninstall:
	rm -f $(PREFIX)/bin/$(PRODUCT)
	@#rm -f $(PREFIX)/share/man/man1/$(PRODUCT).1

clean:
	swift package clean
	rm -rf $(DIR)

distclean: clean
	rm -rf Package.resolved
