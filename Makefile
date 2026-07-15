APP := Promptu.app
BIN := .build/release/PromptuBar

.PHONY: app run test install clean

app:
	swift build -c release
	rm -rf dist/$(APP)
	mkdir -p dist/$(APP)/Contents/MacOS
	cp Info.plist dist/$(APP)/Contents/Info.plist
	cp $(BIN) dist/$(APP)/Contents/MacOS/PromptuBar
	codesign --force --sign - dist/$(APP)

run:
	swift run

test:
	swift test

install: app
	rm -rf /Applications/$(APP)
	cp -R dist/$(APP) /Applications/

clean:
	rm -rf .build dist
