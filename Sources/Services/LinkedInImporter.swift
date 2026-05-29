import Foundation

struct LinkedInImporter {
    enum ImportError: LocalizedError {
        case missingColumns
        var errorDescription: String? {
            "The CSV is missing 'First Name' and 'Last Name' columns. Ensure you're using the LinkedIn Connections export."
        }
    }

    static func parse(url: URL) throws -> [LinkedInConnection] {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSV(content)
        guard let header = rows.first else { return [] }

        let headers = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        func col(_ names: String...) -> Int? {
            names.lazy.compactMap { headers.firstIndex(of: $0) }.first
        }

        guard let firstIdx = col("first name", "firstname"),
              let lastIdx = col("last name", "lastname") else {
            throw ImportError.missingColumns
        }
        let emailIdx = col("email address", "email")
        let companyIdx = col("company")
        let positionIdx = col("position")

        func field(_ row: [String], _ idx: Int?) -> String {
            guard let i = idx, i < row.count else { return "" }
            return row[i].trimmingCharacters(in: .whitespaces)
        }

        return rows.dropFirst().compactMap { row in
            let first = field(row, firstIdx)
            let last = field(row, lastIdx)
            guard !first.isEmpty || !last.isEmpty else { return nil }
            return LinkedInConnection(
                firstName: first,
                lastName: last,
                emailAddress: field(row, emailIdx),
                company: field(row, companyIdx),
                position: field(row, positionIdx)
            )
        }
    }

    // RFC 4180-compliant CSV parser
    private static func parseCSV(_ text: String) -> [[String]] {
        var result: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var idx = text.startIndex

        while idx < text.endIndex {
            let c = text[idx]
            if inQuotes {
                if c == "\"" {
                    let next = text.index(after: idx)
                    if next < text.endIndex && text[next] == "\"" {
                        field.append("\"")
                        idx = text.index(after: next)
                        continue
                    }
                    inQuotes = false
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    row.append(field); field = ""
                case "\r":
                    row.append(field); field = ""
                    result.append(row); row = []
                    let next = text.index(after: idx)
                    if next < text.endIndex && text[next] == "\n" {
                        idx = text.index(after: next)
                        continue
                    }
                case "\n":
                    row.append(field); field = ""
                    result.append(row); row = []
                default:
                    field.append(c)
                }
            }
            idx = text.index(after: idx)
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            result.append(row)
        }
        if result.last?.allSatisfy({ $0.isEmpty }) == true {
            result.removeLast()
        }
        return result
    }
}
