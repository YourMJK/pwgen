.PHONY: build distclean

destination = build

build:
	swift build --configuration release && \
	mkdir -p $(destination) && \
	cp -v .build/release/pwgen $(destination)/pwgen

clean:
	swift package clean
	rm -rf $(destination)/*

distclean: clean
	rm -rf Package.resolved
