import Foundation
import ZIPFoundation
import SQLite

public enum ApkgError: Error {
    case collectionDatabaseInvalid(info: String)
    case collectionDatabaseNotFound
    case cardInvalid
    case revlogInvalid
    case noteModelJsonInvalid
    case deckJsonInvalid
}

extension ApkgError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .collectionDatabaseInvalid(info):
            return "[ApkgError.collectionDatabaseInvalid]\n\(info)"
        default:
            return self.localizedDescription
        }
    }
}

func unwrapOrThrow<T>(_ valOpt: T?, err: Error) throws -> T {
    guard let val = valOpt else {
        throw err
    }
    
    return val
}

public struct AnkiCard {
    public init(id: Int64,
                nid: Int64,
                did: Int64,
                ord: Int64,
                mod: Int64,
                type: Int64,
                queue: Int64,
                due: Int64,
                ivl: Int64,
                factor: Int64,
                reps: Int64,
                lapses: Int64,
                left: Int64,
                flags: Int64) {
        self.id = id
        self.nid = nid
        self.did = did
        self.ord = ord
        self.mod = mod
        self.type = type
        self.queue = queue
        self.due = due
        self.ivl = ivl
        self.factor = factor
        self.reps = reps
        self.lapses = lapses
        self.left = left
        self.flags = flags
    }
    
    public let id: Int64
    public let nid: Int64
    public let did: Int64
    public let ord: Int64
    public let mod: Int64
    public let type: Int64
    public let queue: Int64
    public let due: Int64
    public let ivl: Int64
    public let factor: Int64
    public let reps: Int64
    public let lapses: Int64
    public let left: Int64
    public let flags: Int64
}

public struct AnkiNote {
    public init(id: Int64, guid: String, mid: Int64, mod: Int64, flds: [String]) {
        self.id = id
        self.guid = guid
        self.mid = mid
        self.mod = mod
        self.flds = flds
    }
    
    public let id: Int64
    public let guid: String
    public let mid: Int64
    public let mod: Int64
    public let flds: [String]
}

public struct AnkiRevlog {
    public let id: Int64
    public let cid: Int64
    public let ease: Int64
    public let ivl: Int64
    public let lastIvl: Int64
    public let factor: Int64
    public let time: Int64
    public let type: Int64
}

public struct AnkiNoteField: Decodable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case ord
        case name
    }
    
    public let id: Int64
    public let ord: Int64
    public let name: String
    
    public init(ord: Int64, name: String) {
        self.id = ord
        self.ord = ord
        self.name = name
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.ord = try values.decode(Int64.self, forKey: .ord)
        self.name = try values.decode(String.self, forKey: .name)
        self.id = self.ord
    }
}

public struct AnkiNoteTemplate: Decodable {
    enum CodingKeys: String, CodingKey {
        case ord
        case name
        case qfmt
        case afmt
    }
    
    public let ord: Int64
    public let name: String
    public let qfmt: String
    public let afmt: String
    
    public init(ord: Int64, name: String, qfmt: String, afmt: String) {
        self.ord = ord
        self.name = name
        self.qfmt = qfmt
        self.afmt = afmt
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.ord = try values.decode(Int64.self, forKey: .ord)
        self.name = try values.decode(String.self, forKey: .name)
        self.qfmt = try values.decode(String.self, forKey: .qfmt)
        self.afmt = try values.decode(String.self, forKey: .afmt)
    }
}

public struct AnkiNoteModel: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mod
        case css
        case did
        case flds
        case tmpls
        case type
    }
    
    public let id: Int64
    public let name: String
    public let mod: Int64
    public let css: String?
    public let did: Int64?
    public let flds: [AnkiNoteField]
    public let tmpls: [AnkiNoteTemplate]
    public let type: Int64
    
    public init(id: Int64,
                name: String,
                mod: Int64,
                css: String?,
                did: Int64?,
                flds: [AnkiNoteField],
                tmpls: [AnkiNoteTemplate],
                type: Int64) {
        self.id = id
        self.name = name
        self.mod = mod
        self.css = css
        self.did = did
        self.flds = flds
        self.tmpls = tmpls
        self.type = type
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int64.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.mod = try values.decode(Int64.self, forKey: .mod)
        self.css = try values.decode(String?.self, forKey: .css)
        self.did = try values.decode(Int64?.self, forKey: .did)
        self.flds = try values.decode([AnkiNoteField].self, forKey: .flds)
        self.tmpls = try values.decode([AnkiNoteTemplate].self, forKey: .tmpls)
        self.type = try values.decode(Int64.self, forKey: .type)
    }
}

public struct AnkiNoteModelOld: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mod
        case css
        case did
        case flds
        case tmpls
        case type
    }
    
    public let id: Int64
    public let name: String
    public let mod: Int64
    public let css: String?
    public let did: Int64?
    public let flds: [AnkiNoteField]
    public let tmpls: [AnkiNoteTemplate]
    public let type: Int64
    
    public init(id: Int64,
                name: String,
                mod: Int64,
                css: String?,
                did: Int64?,
                flds: [AnkiNoteField],
                tmpls: [AnkiNoteTemplate],
                type: Int64) {
        self.id = id
        self.name = name
        self.mod = mod
        self.css = css
        self.did = did
        self.flds = flds
        self.tmpls = tmpls
        self.type = type
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try unwrapOrThrow(Int64(try values.decode(String.self, forKey: .id)), err: ApkgError.noteModelJsonInvalid)
        self.name = try values.decode(String.self, forKey: .name)
        self.mod = try values.decode(Int64.self, forKey: .mod)
        self.css = try values.decode(String?.self, forKey: .css)
        self.did = try values.decode(String?.self, forKey: .did).map { try unwrapOrThrow(Int64($0), err: ApkgError.noteModelJsonInvalid) }
        self.flds = try values.decode([AnkiNoteField].self, forKey: .flds)
        self.tmpls = try values.decode([AnkiNoteTemplate].self, forKey: .tmpls)
        self.type = try values.decode(Int64.self, forKey: .type)
    }
    
    public func toNew() -> AnkiNoteModel {
        AnkiNoteModel(id: self.id,
                      name: self.name,
                      mod: self.mod,
                      css: self.css,
                      did: self.did,
                      flds: self.flds,
                      tmpls: self.tmpls,
                      type: self.type)
    }
}

public struct AnkiDeck: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mod
        case desc
    }
    
    public let id: Int64
    public let name: String
    public let mod: Int64
    public let desc: String
    
    public init(id: Int64, name: String, mod: Int64, desc: String) {
        self.id = id
        self.name = name
        self.mod = mod
        self.desc = desc
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int64.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.mod = try values.decode(Int64.self, forKey: .mod)
        self.desc = try values.decode(String.self, forKey: .desc)
    }
}

public struct AnkiCollection {
    public let decks: [Int64: AnkiDeck]
    public let noteModels: [Int64: AnkiNoteModel]
    
    public init(decks: [Int64 : AnkiDeck], noteModels: [Int64 : AnkiNoteModel]) {
        self.decks = decks
        self.noteModels = noteModels
    }
}

public struct AnkiPackage {
    public let collections: [AnkiCollection]
    public let notes: [Int64: AnkiNote]
    public let cards: [Int64: AnkiCard]
    public let revlog: [Int64: AnkiRevlog]
    public let mediaMapping: [String: String]
    
    public init(collections: [AnkiCollection], notes: [Int64 : AnkiNote], cards: [Int64 : AnkiCard], revlog: [Int64 : AnkiRevlog], mediaMapping: [String : String]) {
        self.collections = collections
        self.notes = notes
        self.cards = cards
        self.revlog = revlog
        self.mediaMapping = mediaMapping
    }
    
    static func parseNoteModels(_ noteModelsJson: [String], is21: Bool) throws -> [[Int64: AnkiNoteModel]] {
        let decoder = JSONDecoder()
        
        return try noteModelsJson.map { noteModelJson in
            let noteModelEntry: [String: AnkiNoteModel]
            
            let noteModelData = try unwrapOrThrow(noteModelJson.data(using: .utf8), err: ApkgError.noteModelJsonInvalid)
            
            do {
                if (is21) {
                    noteModelEntry = try decoder.decode([String: AnkiNoteModel].self, from: noteModelData)
                } else {
                    let noteModelEntryOld = try decoder.decode([String: AnkiNoteModelOld].self, from: noteModelData)
                    
                    noteModelEntry = Dictionary(uniqueKeysWithValues: noteModelEntryOld.map { ($0.key, $0.value.toNew()) })
                }
            } catch {
                throw ApkgError.noteModelJsonInvalid
            }
            
            return try Dictionary(uniqueKeysWithValues: noteModelEntry.map {
                guard let intKey = Int64($0.key) else {
                    throw ApkgError.noteModelJsonInvalid
                }
                
                return (intKey, $0.value)
            })
        }
    }
    
    static func parseDecks(_ decksJson: [String]) throws -> [[Int64: AnkiDeck]] {
        let decoder = JSONDecoder()
        
        return try decksJson.map { deckJson in
            guard let deckData = deckJson.data(using: .utf8) else {
                throw ApkgError.deckJsonInvalid
            }
            
            do {
                let deckDict = try decoder.decode([String: AnkiDeck].self, from: deckData)
                return try Dictionary(uniqueKeysWithValues: deckDict.map {
                    guard let intKey = Int64($0.key) else {
                        throw ApkgError.deckJsonInvalid
                    }
                    
                    return (intKey, $0.value)
                })
            } catch {
                throw ApkgError.deckJsonInvalid
            }
        }
    }
    
    static func parseNotes(_ db: Connection) throws -> [Int64: AnkiNote] {
        // Verify the notes table is valid and contains the required columns with the correct types
        let pragmaStatement = "PRAGMA table_info(notes);"
        let pragmaQuery = try db.prepare(pragmaStatement)
        
        let expectedColumnDict = [
            "id": "INTEGER",
            "guid": "TEXT",
            "mid": "INTEGER",
            "mod": "INTEGER",
            "flds": "TEXT"
        ]
        var correctColumnFound = Set<String>()
        
        // Iterate through the results
        for row in pragmaQuery {
            guard let columnName = row[1] as? String,
                  let columnType = row[2] as? String else {
                continue
            }
            
            if let expectedColumnType = expectedColumnDict[columnName], columnType == expectedColumnType {
                correctColumnFound.insert(columnName)
            }
        }
        
        if correctColumnFound.count != expectedColumnDict.count {
            var missingColumnErrorMsg = "Missing columns in the \"notes\" table: \n"
            
            expectedColumnDict.forEach { columnName, columnType in
                if !correctColumnFound.contains(columnName) {
                    missingColumnErrorMsg += " > \(columnName) [type=\(columnType)]"
                }
            }
            
            throw ApkgError.collectionDatabaseInvalid(info: missingColumnErrorMsg)
        }
        
        let notes = try db.prepare("SELECT id, guid, mid, mod, flds FROM notes").map { row in
            let id = try unwrapOrThrow(row[0] as? Int64, err: ApkgError.collectionDatabaseInvalid(info: "id invalid"))
            let guid = try unwrapOrThrow(row[1] as? String, err: ApkgError.collectionDatabaseInvalid(info: "guid invalid"))
            let mid = try unwrapOrThrow(row[2] as? Int64, err: ApkgError.collectionDatabaseInvalid(info: "mid invalid"))
            let mod = try unwrapOrThrow(row[3] as? Int64, err: ApkgError.collectionDatabaseInvalid(info: "mod invalid"))
            let fldsStr = try unwrapOrThrow(row[4] as? String, err: ApkgError.collectionDatabaseInvalid(info: "flds invalid"))
            let separator = String(UnicodeScalar(0x1f))
            let flds = fldsStr.components(separatedBy: separator)
            
            return AnkiNote(id: id, guid: guid, mid: mid, mod: mod, flds: flds)
        }
        
        return Dictionary(uniqueKeysWithValues: notes.map { ($0.id, $0) })
    }
    
    static func parseCards(_ db: Connection) throws -> [Int64: AnkiCard] {
        let selectQuery = "SELECT id, nid, did, ord, mod, type, queue, due, ivl, factor, reps, lapses, left, flags FROM cards"
        
        let cards = try db.prepare(selectQuery).map { row in
            let id = try unwrapOrThrow(row[0] as? Int64, err: ApkgError.cardInvalid)
            let nid = try unwrapOrThrow(row[1] as? Int64, err: ApkgError.cardInvalid)
            let did = try unwrapOrThrow(row[2] as? Int64, err: ApkgError.cardInvalid)
            let ord = try unwrapOrThrow(row[3] as? Int64, err: ApkgError.cardInvalid)
            let mod = try unwrapOrThrow(row[4] as? Int64, err: ApkgError.cardInvalid)
            let type = try unwrapOrThrow(row[5] as? Int64, err: ApkgError.cardInvalid)
            let queue = try unwrapOrThrow(row[6] as? Int64, err: ApkgError.cardInvalid)
            let due = try unwrapOrThrow(row[7] as? Int64, err: ApkgError.cardInvalid)
            let ivl = try unwrapOrThrow(row[8] as? Int64, err: ApkgError.cardInvalid)
            let factor = try unwrapOrThrow(row[9] as? Int64, err: ApkgError.cardInvalid)
            let reps = try unwrapOrThrow(row[10] as? Int64, err: ApkgError.cardInvalid)
            let lapses = try unwrapOrThrow(row[11] as? Int64, err: ApkgError.cardInvalid)
            let left = try unwrapOrThrow(row[12] as? Int64, err: ApkgError.cardInvalid)
            let flags = try unwrapOrThrow(row[13] as? Int64, err: ApkgError.cardInvalid)
            
            return AnkiCard(
                id: id,
                nid: nid,
                did: did,
                ord: ord,
                mod: mod,
                type: type,
                queue: queue,
                due: due,
                ivl: ivl,
                factor: factor,
                reps: reps,
                lapses: lapses,
                left: left,
                flags: flags)
        }
        
        return Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
    }
    
    static func parseRevlog(_ db: Connection) throws -> [Int64: AnkiRevlog] {
        let revlog = try db.prepare("SELECT id, cid, ease, ivl, lastIvl, factor, time, type FROM revlog").map { row in
            let id = try unwrapOrThrow(row[0] as? Int64, err: ApkgError.revlogInvalid)
            let cid = try unwrapOrThrow(row[1] as? Int64, err: ApkgError.revlogInvalid)
            let ease = try unwrapOrThrow(row[2] as? Int64, err: ApkgError.revlogInvalid)
            let ivl = try unwrapOrThrow(row[3] as? Int64, err: ApkgError.revlogInvalid)
            let lastIvl = try unwrapOrThrow(row[4] as? Int64, err: ApkgError.revlogInvalid)
            let factor = try unwrapOrThrow(row[5] as? Int64, err: ApkgError.revlogInvalid)
            let time = try unwrapOrThrow(row[6] as? Int64, err: ApkgError.revlogInvalid)
            let type = try unwrapOrThrow(row[7] as? Int64, err: ApkgError.revlogInvalid)
            
            return AnkiRevlog(id: id, cid: cid, ease: ease, ivl: ivl, lastIvl: lastIvl, factor: factor, time: time, type: type)
        }
        
        return Dictionary(uniqueKeysWithValues: revlog.map { ($0.id, $0) })
    }
    
    static func parseCollections(_ db: Connection, is21: Bool) throws -> [AnkiCollection] {
        let colQuery = try db.prepare("SELECT models, decks FROM col")
        
        let noteModelsJson = try colQuery.map { row in
            try unwrapOrThrow(row[0] as? String, err: ApkgError.collectionDatabaseInvalid(info: "invalid noteModels column type"))
        }
        
        let decksJson = try colQuery.map { row in
            try unwrapOrThrow(row[1] as? String, err: ApkgError.collectionDatabaseInvalid(info: "invalid decks column type"))
        }
        
        let colCount = noteModelsJson.count
        var collections = [AnkiCollection]()
        
        let noteModelsDict = try parseNoteModels(noteModelsJson, is21: is21)
        let decksDict = try parseDecks(decksJson)
        
        for i in 0..<colCount {
            collections.append(AnkiCollection(decks: decksDict[i], noteModels: noteModelsDict[i]))
        }
        
        return collections
    }
    
    static func parseMediaMapping(_ workDir: URL) throws -> [String: String] {
        let mediaData = try Data(contentsOf: workDir.appendingPathComponent("media"))
        
        let decoder = JSONDecoder()
        let mediaMapping = try decoder.decode([String: String].self, from: mediaData)
        
        return mediaMapping
    }
    
    public static func parse(_ fileUrl: URL) throws -> AnkiPackage {
        let fileManager = FileManager()
        let workDir = fileManager.temporaryDirectory.appendingPathComponent("apkg_contents")
        
        // Erase any workdir remaining after a previous import
        do {
            try fileManager.removeItem(at: workDir)
        } catch {
            // Do nothing
        }
        
        try fileManager.unzipItem(at: fileUrl, to: workDir)
        
        var dbPath = workDir.appendingPathComponent("collection.anki21")
        var is21 = true
        
        // Check if an old version of the collection database exists
        if !fileManager.fileExists(atPath: dbPath.path) {
            dbPath = workDir.appendingPathComponent("collection.anki2")
            is21 = false
        }
        
        // No collection database found
        if !fileManager.fileExists(atPath: dbPath.path) {
            throw ApkgError.collectionDatabaseNotFound
        }
        
        let db = try Connection(dbPath.absoluteString)
        
        let collections = try parseCollections(db, is21: is21)
        let notesDict = try parseNotes(db)
        let cardsDict = try parseCards(db)
        let revlogDict = try parseRevlog(db)
        let mediaMapping = try parseMediaMapping(workDir)
        
        try fileManager.removeItem(at: workDir)
        
        return AnkiPackage(collections: collections, notes: notesDict, cards: cardsDict, revlog: revlogDict, mediaMapping: mediaMapping)
    }
}
