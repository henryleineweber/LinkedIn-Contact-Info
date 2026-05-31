.PHONY: setup open clean

setup:
	@which xcodegen > /dev/null 2>&1 || brew install xcodegen
	xcodegen generate

open: setup
	open LinkedInContactSync.xcodeproj

clean:
	rm -rf LinkedInContactSync.xcodeproj DerivedData
