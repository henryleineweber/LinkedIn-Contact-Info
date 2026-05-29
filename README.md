# LinkedIn Contact Sync

A native SwiftUI app for macOS and iOS that syncs job titles, companies, and photos from a LinkedIn connections export into your Contacts app. Each proposed change is presented for your review before anything is written.

## How it works

1. **Import** — Pick your LinkedIn `Connections.csv` export and (optionally) a folder of contact photos.
2. **Review** — The app matches your LinkedIn connections to existing contacts, then shows every proposed change with field-level toggles to approve or skip individual updates.
3. **Apply** — Confirm, and the approved changes are written to your Contacts app (and sync to iPhone via iCloud Contacts).

## Getting LinkedIn data

1. Go to **LinkedIn → Me → Settings & Privacy → Data privacy → Get a copy of your data**
2. Select **Connections** and request the archive
3. Download and unzip — you'll find `Connections.csv`

The CSV includes: First Name, Last Name, Email Address, Company, Position, Connected On.

> **Photos:** LinkedIn's export does not include profile photos. To sync photos, create a folder where each file is named `First Last.jpg` (or `.png`, `.heic`). The app will match filenames to contact names.

## Requirements

- Xcode 15+ (for building)
- macOS 13.0+ (macOS target)
- iOS 15.0+ (iOS target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (to generate the Xcode project)

## Setup

```bash
# Install XcodeGen if needed, generate project, and open in Xcode
make open
```

Or manually:

```bash
brew install xcodegen
xcodegen generate
open LinkedInContactSync.xcodeproj
```

Then in Xcode:
1. Select your **Development Team** in the Signing & Capabilities tab for each target
2. Build and run on your device or simulator

## Project structure

```
Sources/
  App.swift                     # @main entry point
  Models/
    LinkedInConnection.swift    # Parsed row from CSV
    ContactUpdate.swift         # Proposed change for one contact
  Services/
    LinkedInImporter.swift      # RFC 4180 CSV parser
    ContactsService.swift       # CNContacts read/write wrapper
    MatchingService.swift       # Fuzzy name + email matching
  Views/
    ContentView.swift           # Root phase state machine
    ImportView.swift            # File picker screen
    ReviewView.swift            # Approve/reject list
    ContactUpdateRow.swift      # Per-contact change card
    DoneView.swift              # Success screen
Resources/
  Info.plist                    # Shared app metadata
  macOS.entitlements            # Sandbox + contacts + file access
project.yml                     # XcodeGen configuration
```

## Matching logic

Contacts are matched against LinkedIn connections using:
- Exact first + last name (score 1.0)
- Email address match (0.95)
- Same last name + matching first initial (0.85)
- Same last name + one name contains the other (0.80)
- Levenshtein similarity on full name ≥ 70% (used as fallback)

Only matches with a confidence ≥ 0.7 are shown.

## Privacy

All processing happens on-device. No data is sent to any server.
