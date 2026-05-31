import Contacts

struct MatchResult {
    let connection: LinkedInConnection
    let contact: CNContact
    let confidence: Double
}

struct MatchingService {
    static func match(connections: [LinkedInConnection], against contacts: [CNContact]) -> [MatchResult] {
        connections.compactMap { bestMatch(for: $0, in: contacts) }
    }

    private static func bestMatch(for connection: LinkedInConnection, in contacts: [CNContact]) -> MatchResult? {
        var best: (contact: CNContact, score: Double)?

        for contact in contacts {
            let score = similarity(connection, contact)
            if score >= 0.7 && (best == nil || score > best!.score) {
                best = (contact, score)
            }
        }

        return best.map { MatchResult(connection: connection, contact: $0.contact, confidence: $0.score) }
    }

    private static func similarity(_ connection: LinkedInConnection, _ contact: CNContact) -> Double {
        let lFirst = connection.firstName.lowercased()
        let lLast  = connection.lastName.lowercased()

        // Strip middle name: "John Michael" → "John"
        let cGiven  = contact.givenName.lowercased()
        let cFirst  = cGiven.components(separatedBy: .whitespaces).first(where: { !$0.isEmpty }) ?? cGiven
        let cLast   = contact.familyName.lowercased()
        let cNick   = contact.nickname.lowercased()

        guard !lFirst.isEmpty || !lLast.isEmpty else { return 0.0 }
        guard !cGiven.isEmpty || !cLast.isEmpty else { return 0.0 }

        // Exact match (tolerates middle name in givenName)
        if (lFirst == cFirst || lFirst == cGiven) && lLast == cLast { return 1.0 }

        // Email match
        if !connection.emailAddress.isEmpty {
            let email = connection.emailAddress.lowercased()
            if contact.emailAddresses.contains(where: { ($0.value as String).lowercased() == email }) {
                return 0.95
            }
        }

        // Nickname match + same last name (e.g. "Bob" / "Robert Smith")
        if !cNick.isEmpty && cNick == lFirst && cLast == lLast { return 0.93 }

        // Full name stored in givenName only (familyName empty) — common for imported contacts
        if cLast.isEmpty {
            let linkedInFull = "\(lFirst) \(lLast)".trimmingCharacters(in: .whitespaces)
            if cGiven == linkedInFull { return 0.95 }
            // "John Smith" stored as "Smith, John" style
            let reversed = "\(lLast) \(lFirst)".trimmingCharacters(in: .whitespaces)
            if cGiven == reversed { return 0.90 }
        }

        // Same last name — escalating first-name checks
        if !cLast.isEmpty && lLast == cLast {
            // First word of given name matches exactly
            if lFirst == cFirst { return 0.95 }
            // First initial matches
            if !lFirst.isEmpty, !cFirst.isEmpty, lFirst.first == cFirst.first { return 0.85 }
            // One first name is contained in the other ("Mike" ↔ "Michael")
            if lFirst.contains(cFirst) || cFirst.contains(lFirst) { return 0.82 }
        }

        // Levenshtein on full name as last resort
        let fullA = "\(lFirst) \(lLast)".trimmingCharacters(in: .whitespaces)
        let fullB = "\(cFirst) \(cLast)".trimmingCharacters(in: .whitespaces)
        guard !fullA.isEmpty && !fullB.isEmpty else { return 0.0 }
        let maxLen = max(fullA.count, fullB.count)
        let sim = 1.0 - Double(levenshtein(fullA, fullB)) / Double(maxLen)
        return sim >= 0.7 ? sim * 0.9 : 0.0
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        let a = Array(a), b = Array(b)
        var row = Array(0...b.count)
        for i in 1...a.count {
            let prev = row
            row[0] = i
            for j in 1...b.count {
                row[j] = a[i-1] == b[j-1]
                    ? prev[j-1]
                    : Swift.min(row[j-1], prev[j], prev[j-1]) + 1
            }
        }
        return row[b.count]
    }
}
