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
        let lLast = connection.lastName.lowercased()
        let cFirst = contact.givenName.lowercased()
        let cLast = contact.familyName.lowercased()

        // Exact match
        if lFirst == cFirst && lLast == cLast { return 1.0 }

        // Email match
        if !connection.emailAddress.isEmpty {
            let email = connection.emailAddress.lowercased()
            if contact.emailAddresses.contains(where: { ($0.value as String).lowercased() == email }) {
                return 0.95
            }
        }

        // Same last name, fuzzy first name
        if lLast == cLast && !lLast.isEmpty {
            if lFirst.first == cFirst.first { return 0.85 }
            if lFirst.contains(cFirst) || cFirst.contains(lFirst) { return 0.80 }
        }

        // Levenshtein-based fallback on full name
        let fullA = "\(lFirst) \(lLast)".trimmingCharacters(in: .whitespaces)
        let fullB = "\(cFirst) \(cLast)".trimmingCharacters(in: .whitespaces)
        guard !fullA.isEmpty && !fullB.isEmpty else { return 0.0 }
        let maxLen = max(fullA.count, fullB.count)
        let similarity = 1.0 - Double(levenshtein(fullA, fullB)) / Double(maxLen)
        return similarity >= 0.7 ? similarity * 0.9 : 0.0
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
