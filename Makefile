APP := Promptu.app
BIN := .build/release/PromptuBar
ICONSET := .build/AppIcon.iconset

.PHONY: app icon run test install clean

app: icon
	swift build -c release
	rm -rf dist/$(APP)
	mkdir -p dist/$(APP)/Contents/MacOS dist/$(APP)/Contents/Resources
	cp Info.plist dist/$(APP)/Contents/Info.plist
	cp $(BIN) dist/$(APP)/Contents/MacOS/PromptuBar
	cp .build/AppIcon.icns dist/$(APP)/Contents/Resources/AppIcon.icns
	codesign --force --sign - dist/$(APP)

icon:
	rm -rf $(ICONSET)
	mkdir -p $(ICONSET)
	swift scripts/make-icon.swift mascot.svg $(ICONSET)
	iconutil -c icns $(ICONSET) -o .build/AppIcon.icns

run:
	swift run

test:
	swift test

install: app
	rm -rf /Applications/$(APP)
	cp -R dist/$(APP) /Applications/

clean:
	rm -rf .build dist
