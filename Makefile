.PHONY: setup open clean

setup:
	@which xcodegen > /dev/null 2>&1 || (echo "Installing XcodeGen via Homebrew..." && brew install xcodegen)
	xcodegen generate
	@echo ""
	@echo "✓ LinkedInContactSync.xcodeproj generated."
	@echo "  Run 'make open' or open the .xcodeproj in Xcode."

open: setup
	open LinkedInContactSync.xcodeproj

clean:
	rm -rf LinkedInContactSync.xcodeproj DerivedData
