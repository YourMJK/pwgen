PRODUCT = pwgen
DIR = bin
SWIFTBUILD = swift build -c release --product $(PRODUCT)
BINARY = .build/release/$(PRODUCT)
MANUAL = .build/plugins/GenerateManual/outputs/$(PRODUCT)/$(PRODUCT).1
PREFIX = /usr/local

DISTR_MACOS = $(PRODUCT).macOS.Universal
DISTR_LINUX = $(PRODUCT).Linux.x86_64
CODESIGN_ID_APP = AFB2E179D076A5FE9111BE28A2F4E0F52BDDF7C4

.PHONY: build $(BINARY) $(MANUAL) macos linux install uninstall clean distclean
.DEFAULT_GOAL := build


$(DIR):
	mkdir $(DIR)

$(BINARY):
	$(SWIFTBUILD)

$(MANUAL):
	swift package plugin generate-manual


build: $(BINARY) $(DIR)
	@cp -v $(BINARY) $(DIR)/

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


macos: BINARY = .build/apple/Products/Release/$(PRODUCT)
macos: $(DIR)
	$(SWIFTBUILD) --arch arm64 --arch x86_64
	@cp -v $(BINARY) $(DIR)/
	@#cd $(DIR) && zip $(PRODUCT).macOS.Universal.zip $(PRODUCT)
	xcrun codesign -s "$(CODESIGN_ID_APP)" --options=runtime --timestamp $(DIR)/$(PRODUCT)
	rm -rf tmp && mkdir -p tmp && xattr -cr tmp
	cp $(DIR)/$(PRODUCT) tmp/
	rm -f $(DIR)/$(DISTR_MACOS).dmg
	hdiutil create -fs HFS+ -volname $(DISTR_MACOS) -srcfolder tmp $(DIR)/$(DISTR_MACOS).dmg
	rm -rf tmp
	xcrun codesign -s "$(CODESIGN_ID_APP)" $(DIR)/$(DISTR_MACOS).dmg
	xcrun notarytool submit $(DIR)/$(DISTR_MACOS).dmg --keychain-profile "personal" --wait
	xcrun stapler staple $(DIR)/$(DISTR_MACOS).dmg

linux: $(DIR)
	$(SWIFTBUILD) --static-swift-stdlib
	@cp -v $(BINARY) $(DIR)/
	cd $(DIR) && tar -czf $(DISTR_LINUX).tar.gz $(PRODUCT)
