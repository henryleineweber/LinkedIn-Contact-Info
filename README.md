# LinkedIn Contact Sync

A native SwiftUI app for macOS and iOS that syncs job titles, companies, and photos from LinkedIn into your Contacts app. Each proposed change is shown for review before anything is written.

## How it works

1. **Connect** — Sign in with LinkedIn via OAuth (or import a CSV export as a fallback).
2. **Review** — The app matches your LinkedIn connections to existing contacts and shows every proposed change with field-level toggles to approve or skip.
3. **Apply** — Approved changes are written to your Contacts app and sync to iPhone via iCloud Contacts.

---

## Option A — LinkedIn API (recommended)

### 1. Create a LinkedIn Developer App

1. Go to [developer.linkedin.com](https://developer.linkedin.com) and create a new app.
2. Under **Auth**, add this OAuth 2.0 redirect URL:
   ```
   linkedincontactsync://oauth/callback
   ```
3. Request the following OAuth scopes (under **Products**):
   | Scope | Required for |
   |---|---|
   | `r_liteprofile` | Name, headline, profile photo |
   | `r_emailaddress` | Email address |
   | `r_network` | First-degree connections list |

   > **Note:** `r_network` is a restricted scope that requires LinkedIn Partner approval for distributed apps. For a personal developer app where you are the only user, you can request the connections endpoint directly — it typically works for your own account during development.

4. Copy the **Client ID** and **Client Secret**.

### 2. Configure the app

Launch the app → tap **Configure** → enter your Client ID and Client Secret.

### 3. Sign in and sync

Tap **Sign in with LinkedIn** → approve in the browser → tap **Fetch My Connections**.

---

## Option B — CSV Export (no API approval needed)

1. Go to **LinkedIn → Settings → Data privacy → Get a copy of your data → Connections**
2. Download and unzip the archive — you'll find `Connections.csv`
3. In the app, tap **Import CSV** and select the file

> **Photos via CSV:** LinkedIn's export does not include photos. To sync photos, put image files in a folder named `First Last.jpg` (or `.png`, `.heic`) and select the folder in the app.

---

## Build

```bash
git clone https://github.com/henryleineweber/linkedin-contact-info.git
cd linkedin-contact-info
make open   # installs xcodegen, generates .xcodeproj, opens Xcode
```

Then in Xcode: set your **Development Team** in Signing & Capabilities for each target and run.

**Requirements:** Xcode 15+, macOS 13.0+ (macOS target), iOS 15.0+ (iOS target), [XcodeGen](https://github.com/yonaskolb/XcodeGen)

---

## Project structure

```
Sources/
  App.swift
  Models/
    LinkedInConnection.swift    # Parsed connection record
    ContactUpdate.swift         # Proposed change for one contact
    LinkedInAPIModels.swift     # Decodable types for LinkedIn API responses
  Services/
    LinkedInAuthService.swift   # OAuth 2.0 via ASWebAuthenticationSession
    LinkedInAPIService.swift    # REST calls + pagination + photo download
    LinkedInImporter.swift      # RFC 4180 CSV parser (Option B fallback)
    ContactsService.swift       # CNContacts read/write
    MatchingService.swift       # Fuzzy name + email matching
  Views/
    ContentView.swift           # Root phase state machine
    ImportView.swift            # API sign-in + CSV fallback
    CredentialsView.swift       # Client ID / Secret entry
    ReviewView.swift            # Approve/reject list
    ContactUpdateRow.swift      # Per-contact change card
    DoneView.swift              # Success screen
Resources/
  Info.plist                    # Shared app metadata + URL scheme
  macOS.entitlements            # Sandbox + contacts + file access
project.yml                     # XcodeGen configuration
```

## Matching logic

| Signal | Confidence |
|---|---|
| Exact first + last name | 1.0 |
| Email address match | 0.95 |
| Same last name + first initial | 0.85 |
| Same last name + one name contains the other | 0.80 |
| Levenshtein similarity ≥ 70% | similarity × 0.9 |

Only matches ≥ 0.7 confidence are shown.

## Privacy

All processing is on-device. LinkedIn credentials are stored in `UserDefaults` on your local device. The app never sends data to any server other than LinkedIn's own API.
