import Foundation
import ZIPFoundation
import SQLite
import libzstd

public enum ApkgError: Error {
    case collectionDatabaseNotFound
    case cardTableInvalid(_ sqliteError: String)
    case noteTableInvalid(_ sqliteError: String)
    case revlogTableInvalid(_ sqliteError: String)
    case noteModelTableInvalid(_ sqliteError: String)
    case deckTableInvalid(_ sqliteError: String)
    case noteModelJsonInvalid(_ jsonDecodeError: String)
    case deckJsonInvalid(_ jsonDecodeError: String)
}

extension ApkgError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .cardTableInvalid(sqliteError):
            return "[ApkgError.cardTableInvalid]\n\(sqliteError)"
        case let .noteTableInvalid(sqliteError):
            return "[ApkgError.noteTableInvalid]\n\(sqliteError)"
        case let .revlogTableInvalid(sqliteError):
            return "[ApkgError.revlogTableInvalid]\n\(sqliteError)"
        case let .noteModelTableInvalid(sqliteError):
            return "[ApkgError.noteModelTableInvalid]\n\(sqliteError)"
        case let .deckTableInvalid(sqliteError):
            return "[ApkgError.deckTableInvalid]\n\(sqliteError)"
        case let .noteModelJsonInvalid(jsonDecodeError):
            return "[ApkgError.noteModelJsonInvalid]\n\(jsonDecodeError)"
        case let .deckJsonInvalid(jsonDecodeError):
            return "[ApkgError.deckJsonInvalid]\n\(jsonDecodeError)"
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

public protocol AnkiIdentifiable {
    var id: Int64 { get }
}

public func ankiListToDict<T: AnkiIdentifiable>(_ list: [T]) -> [Int64:T] {
    return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
}

public struct AnkiCard: AnkiIdentifiable {
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
        self.ivl = ivl
        self.due = due
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

public struct AnkiNote: AnkiIdentifiable {
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

public struct AnkiRevlog: AnkiIdentifiable {
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

public final class AnkiNoteModel: Decodable {
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
    public var flds: [AnkiNoteField]
    public var tmpls: [AnkiNoteTemplate]
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
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try unwrapOrThrow(Int64(try values.decode(String.self, forKey: .id)),
                                        err: ApkgError.noteModelJsonInvalid("Old note \"id\" not convertible to Int64"))
            self.name = try values.decode(String.self, forKey: .name)
            self.mod = try values.decode(Int64.self, forKey: .mod)
            self.css = try values.decode(String?.self, forKey: .css)
            self.did = try values.decode(String?.self, forKey: .did).map {
                try unwrapOrThrow(Int64($0), err: ApkgError.noteModelJsonInvalid("Old note \"did\" not convertible to Int64"))
            }
            self.flds = try values.decode([AnkiNoteField].self, forKey: .flds)
            self.tmpls = try values.decode([AnkiNoteTemplate].self, forKey: .tmpls)
            self.type = try values.decode(Int64.self, forKey: .type)
        } catch {
            throw ApkgError.noteModelJsonInvalid(error.localizedDescription)
        }
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

enum AnkiPackageFormat: String {
    case anki2 = "collection.anki2"
    case anki21 = "collection.anki21"
    case anki21b = "collection.anki21b"
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
    
    static func parseNoteModelsOld(_ noteModelsJson: [String], is21: Bool) throws -> [[Int64: AnkiNoteModel]] {
        let decoder = JSONDecoder()
        
        return try noteModelsJson.map { noteModelJson in
            let noteModelEntry: [String: AnkiNoteModel]
            
            let noteModelData = try unwrapOrThrow(noteModelJson.data(using: .utf8), err: ApkgError.noteModelJsonInvalid("UTF8 parsing failed"))
            
            do {
                if (is21) {
                    noteModelEntry = try decoder.decode([String: AnkiNoteModel].self, from: noteModelData)
                } else {
                    let noteModelEntryOld = try decoder.decode([String: AnkiNoteModelOld].self, from: noteModelData)
                    
                    noteModelEntry = Dictionary(uniqueKeysWithValues: noteModelEntryOld.map { ($0.key, $0.value.toNew()) })
                }
            } catch let error {
                throw ApkgError.noteModelJsonInvalid(error.localizedDescription)
            }
            
            return try Dictionary(uniqueKeysWithValues: noteModelEntry.map {
                guard let intKey = Int64($0.key) else {
                    throw ApkgError.noteModelJsonInvalid("Note \"id\" not convertible to Int64")
                }
                
                return (intKey, $0.value)
            })
        }
    }
    
    static func parseNoteModels(_ db: Connection) throws -> [Int64: AnkiNoteModel] {
        var ankiNoteModels = [Int64: AnkiNoteModel]()
        
        let notetypesTable = Table("notetypes")
        let fieldsTable = Table("fields")
        let templatesTable = Table("templates")
        
        let notetypesId = SQLite.Expression<Int64>("id")
        let notetypesName = SQLite.Expression<String>("name")
        let notetypesMod = SQLite.Expression<Int64>("mtime_secs")
        let fieldsNtid = SQLite.Expression<Int64>("ntid")
        let fieldsOrd = SQLite.Expression<Int64>("ord")
        let fieldsName = SQLite.Expression<String>("name")
        let templatesConfig = SQLite.Expression<Data>("config")
        
        let noteModelFieldsQuery = notetypesTable
            .join(fieldsTable, on: notetypesTable[notetypesId] == fieldsTable[fieldsNtid])
            .select(notetypesTable[notetypesId], notetypesTable[notetypesName], notetypesTable[notetypesMod], fieldsTable[fieldsName], fieldsTable[fieldsOrd])
        
        for row in try db.prepare(noteModelFieldsQuery) {
            let notetypesIdVal = row[notetypesTable[notetypesId]]
            let notetypesNameVal = row[notetypesTable[notetypesName]]
            let notetypesModVal = row[notetypesTable[notetypesMod]]
            let fieldsNameVal = row[fieldsTable[fieldsName]]
            let fieldsOrdVal = row[fieldsTable[fieldsOrd]]
            
            if let noteModel = ankiNoteModels[notetypesIdVal] {
                noteModel.flds.append(AnkiNoteField(ord: fieldsOrdVal, name: fieldsNameVal))
            } else {
                ankiNoteModels[notetypesIdVal] = AnkiNoteModel(id: notetypesIdVal, name: notetypesNameVal, mod: notetypesModVal, css: nil, did: nil, flds: [], tmpls: [], type: 0)
                ankiNoteModels[notetypesIdVal]!.flds.append(AnkiNoteField(ord: fieldsOrdVal, name: fieldsNameVal))
            }
        }
        
        let noteModelTemplatesQuery = notetypesTable
            .join(templatesTable, on: notetypesTable[notetypesId] == templatesTable[fieldsNtid])
            .select(notetypesTable[notetypesId], notetypesTable[notetypesName], notetypesTable[notetypesMod], templatesTable[fieldsOrd], templatesTable[fieldsName], templatesTable[templatesConfig])
        
        for row in try db.prepare(noteModelTemplatesQuery) {
            let notetypesIdVal = row[notetypesTable[notetypesId]]
            let notetypesNameVal = row[notetypesTable[notetypesName]]
            let notetypesModVal = row[notetypesTable[notetypesMod]]
            
            let templatesNameVal = row[templatesTable[fieldsName]]
            let templatesOrdVal = row[templatesTable[fieldsOrd]]
            let templatesConfigVal = row[templatesTable[templatesConfig]]
            
            let config = try Config(serializedBytes: templatesConfigVal)
            
            if let noteModel = ankiNoteModels[notetypesIdVal] {
                noteModel.tmpls.append(AnkiNoteTemplate(ord: templatesOrdVal, name: templatesNameVal, qfmt: config.qFormat, afmt: config.aFormat))
            } else {
                ankiNoteModels[notetypesIdVal] = AnkiNoteModel(id: notetypesIdVal, name: notetypesNameVal, mod: notetypesModVal, css: nil, did: nil, flds: [], tmpls: [], type: 0)
                ankiNoteModels[notetypesIdVal]!.tmpls.append(AnkiNoteTemplate(ord: templatesOrdVal, name: templatesNameVal, qfmt: config.qFormat, afmt: config.aFormat))
            }
        }
        
        return ankiNoteModels
    }
    
    static func parseDecksOld(_ decksJson: [String]) throws -> [[Int64: AnkiDeck]] {
        let decoder = JSONDecoder()
        
        return try decksJson.map { deckJson in
            guard let deckData = deckJson.data(using: .utf8) else {
                throw ApkgError.deckJsonInvalid("UTF8 parsing failed")
            }
            
            do {
                let deckDict = try decoder.decode([String: AnkiDeck].self, from: deckData)
                return try Dictionary(uniqueKeysWithValues: deckDict.map {
                    guard let intKey = Int64($0.key) else {
                        throw ApkgError.deckJsonInvalid("Deck \"id\" not convertible to Int64")
                    }
                    
                    return (intKey, $0.value)
                })
            } catch {
                throw ApkgError.deckJsonInvalid(error.localizedDescription)
            }
        }
    }
    
    static func parseDecks(_ db: Connection) throws -> [Int64: AnkiDeck] {
        let id = SQLite.Expression<Int64>("id")
        let name = SQLite.Expression<String>("name")
        let mtime_secs = SQLite.Expression<Int64>("mtime_secs")
        
        let decksQuery = Table("decks").select(id, name, mtime_secs).order(id)
        
        return try Dictionary(uniqueKeysWithValues: db.prepareRowIterator(decksQuery).map { row in
            return (row[id], AnkiDeck(id: row[id], name: row[name], mod: row[mtime_secs], desc: ""))
        })
    }
    
    static func parseNotes(_ db: Connection, length: Int64? = nil, offset: Int64? = nil) throws -> [AnkiNote] {
        do {
            let id = SQLite.Expression<Int64>("id")
            let guid = SQLite.Expression<String>("guid")
            let mid = SQLite.Expression<Int64>("mid")
            let mod = SQLite.Expression<Int64>("mod")
            let flds = SQLite.Expression<String>("flds")
            
            var notesQuery = Table("notes").select(id, guid, mid, mod, flds).order(id)
            
            if let length = length {
                if let offset = offset {
                    notesQuery = notesQuery.limit(Int(length), offset: Int(offset))
                } else {
                    notesQuery = notesQuery.limit(Int(length))
                }
            }
            
            return try db.prepareRowIterator(notesQuery).map { row in
                let fldsStr = row[flds]
                let separator = String(UnicodeScalar(0x1f))
                let fldsList = fldsStr.components(separatedBy: separator)
                
                return AnkiNote(id: row[id], guid: row[guid], mid: row[mid], mod: row[mod], flds: fldsList)
            }
        } catch {
            throw ApkgError.noteTableInvalid(error.localizedDescription)
        }
    }
    
    static func parseCards(_ db: Connection, length: Int64? = nil, offset: Int64? = nil) throws -> [AnkiCard] {
        do {
            let id = SQLite.Expression<Int64>("id")
            let nid = SQLite.Expression<Int64>("nid")
            let did = SQLite.Expression<Int64>("did")
            let ord = SQLite.Expression<Int64>("ord")
            let mod = SQLite.Expression<Int64>("mod")
            let type = SQLite.Expression<Int64>("type")
            let queue = SQLite.Expression<Int64>("queue")
            let due = SQLite.Expression<Int64>("due")
            let ivl = SQLite.Expression<Int64>("ivl")
            let factor = SQLite.Expression<Int64>("factor")
            let reps = SQLite.Expression<Int64>("reps")
            let lapses = SQLite.Expression<Int64>("lapses")
            let left = SQLite.Expression<Int64>("left")
            let flags = SQLite.Expression<Int64>("flags")
            
            var cardsQuery = Table("cards")
                .select(id, nid, did, ord, mod, type, queue, due, ivl, factor, reps, lapses, left, flags)
                .order(id)
            
            if let length = length {
                if let offset = offset {
                    cardsQuery = cardsQuery.limit(Int(length), offset: Int(offset))
                } else {
                    cardsQuery = cardsQuery.limit(Int(length))
                }
            }
            
            return try db.prepareRowIterator(cardsQuery).map { row in
                return AnkiCard(
                    id: row[id],
                    nid: row[nid],
                    did: row[did],
                    ord: row[ord],
                    mod: row[mod],
                    type: row[type],
                    queue: row[queue],
                    due: row[due],
                    ivl: row[ivl],
                    factor: row[factor],
                    reps: row[reps],
                    lapses: row[lapses],
                    left: row[left],
                    flags: row[flags])
            }
        } catch {
            throw ApkgError.cardTableInvalid(error.localizedDescription)
        }
    }
    
    static func parseRevlog(_ db: Connection, length: Int64? = nil, offset: Int64? = nil) throws -> [AnkiRevlog] {
        do {
            let id = SQLite.Expression<Int64>("id")
            let cid = SQLite.Expression<Int64>("cid")
            let ease = SQLite.Expression<Int64>("ease")
            let ivl = SQLite.Expression<Int64>("ivl")
            let lastIvl = SQLite.Expression<Int64>("lastIvl")
            let factor = SQLite.Expression<Int64>("factor")
            let time = SQLite.Expression<Int64>("time")
            let type = SQLite.Expression<Int64>("type")
            
            var revlogQuery = Table("revlog").select(id, cid, ease, ivl, lastIvl, factor, time, type).order(id)
            
            if let length = length {
                if let offset = offset {
                    revlogQuery = revlogQuery.limit(Int(length), offset: Int(offset))
                } else {
                    revlogQuery = revlogQuery.limit(Int(length))
                }
            }
            
            return try db.prepareRowIterator(revlogQuery).map { row in
                return AnkiRevlog(
                    id: row[id],
                    cid: row[cid],
                    ease: row[ease],
                    ivl: row[ivl],
                    lastIvl: row[lastIvl],
                    factor: row[factor],
                    time: row[time],
                    type: row[type])
            }
        } catch {
            throw ApkgError.revlogTableInvalid(error.localizedDescription)
        }
    }
    
    static func parseCollectionsOld(_ db: Connection, is21: Bool) throws -> [AnkiCollection] {
        let models = SQLite.Expression<String>("models")
        let noteModelsJson: [String]
        do {
            noteModelsJson = try db.prepareRowIterator(Table("col").select(models)).map { $0[models] }
        } catch {
            throw ApkgError.noteTableInvalid(error.localizedDescription)
        }
        
        let decks = SQLite.Expression<String>("decks")
        let decksJson: [String]
        do {
            decksJson = try db.prepareRowIterator(Table("col").select(decks)).map { $0[decks] }
        } catch {
            throw ApkgError.deckTableInvalid(error.localizedDescription)
        }
        
        let colCount = noteModelsJson.count
        var collections = [AnkiCollection]()
        
        let noteModelsDict = try parseNoteModelsOld(noteModelsJson, is21: is21)
        let decksDict = try parseDecksOld(decksJson)
        
        for i in 0..<colCount {
            collections.append(AnkiCollection(decks: decksDict[i], noteModels: noteModelsDict[i]))
        }
        
        return collections
    }
    
    static func unicaseCollation(_ lhs: String, _ rhs: String) -> ComparisonResult {
        return lhs.compare(rhs, options: .caseInsensitive)
    }
    
    static func parseCollections21b(_ db: Connection) throws -> [AnkiCollection] {
        let noteModels = try parseNoteModels(db)
        let decks = try parseDecks(db)
        
        return [AnkiCollection(decks: decks, noteModels: noteModels)]
    }
    
    static func parseCollections(_ db: Connection, format: AnkiPackageFormat) throws -> [AnkiCollection] {
        try db.createCollation("unicase", unicaseCollation)
        
        switch format {
        case .anki2: return try parseCollectionsOld(db, is21: false)
        case .anki21: return try parseCollectionsOld(db, is21: true)
        case .anki21b: return try parseCollections21b(db)
        }
    }
    
    static func parseMediaMapping(_ workDir: URL, format: AnkiPackageFormat) throws -> [String: String] {
        if format != .anki21b {
            let mediaData = try Data(contentsOf: workDir.appendingPathComponent("media"))
            let decoder = JSONDecoder()
            return try decoder.decode([String: String].self, from: mediaData)
        } else {
            try decompressZstdFile(atPath: workDir.appendingPathComponent("media"), toDestination: workDir.appendingPathComponent("media_dec"))
            let mediaData = try Data(contentsOf: workDir.appendingPathComponent("media_dec"))
            
            let mediaEntries = try MediaEntries(serializedBytes: mediaData)
            
            return Dictionary(uniqueKeysWithValues: mediaEntries.entries.enumerated().map {
                if $1.hasLegacyZipFilename {
                    return (String($1.legacyZipFilename), $1.name)
                } else {
                    return (String($0), $1.name)
                }
            })
        }
    }
    
    static func findPackageFormat(_ workDir: URL) -> AnkiPackageFormat? {
        let fileManager = FileManager()
        
        var dbPath = workDir.appendingPathComponent(AnkiPackageFormat.anki21b.rawValue)
        if fileManager.fileExists(atPath: dbPath.path) {
            return .anki21b
        }
        
        dbPath = workDir.appendingPathComponent(AnkiPackageFormat.anki21.rawValue)
        if fileManager.fileExists(atPath: dbPath.path) {
            return .anki21
        }
        
        dbPath = workDir.appendingPathComponent(AnkiPackageFormat.anki2.rawValue)
        if fileManager.fileExists(atPath: dbPath.path) {
            return .anki2
        }
        
        return nil
    }
    
    static func decompressZstdFile(atPath path: URL, toDestination destinationPath: URL) throws {
        // Read the compressed data from the file
        let compressedData = try Data(contentsOf: path)
        
        // Get the decompressed size from the frame header
        var decompressedSize: CUnsignedLongLong = 0
        try compressedData.withUnsafeBytes {
            decompressedSize = ZSTD_getFrameContentSize($0.baseAddress, $0.count)
            guard decompressedSize != ZSTD_CONTENTSIZE_ERROR else {
                throw NSError(domain: "ZSTDError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid compressed data"])
            }
        }
        
        if (decompressedSize != ZSTD_CONTENTSIZE_UNKNOWN) {
            // Allocate a buffer for the decompressed data
            var decompressedData = Data(count: Int(decompressedSize))
            
            // Decompress the data
            let result = decompressedData.withUnsafeMutableBytes { decompressedBuffer in
                compressedData.withUnsafeBytes { compressedBuffer in
                    ZSTD_decompress(decompressedBuffer.baseAddress, Int(decompressedSize), compressedBuffer.baseAddress, compressedData.count)
                }
            }
            // Check if decompression was successful
            guard result == decompressedSize else {
                throw NSError(domain: "ZSTDError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Decompression failed"])
            }
            
            // Write the decompressed data to the destination file
            try decompressedData.write(to: destinationPath)
        } else {
            var decompressedData = Data()
            
            // Define the input and output buffer sizes
            let inputBufferSize = 1024 * 1024 // 1 MB
            let outputBufferSize = ZSTD_DStreamOutSize()
            
            // Allocate input and output buffers
            var inputBuffer = Data(count: inputBufferSize)
            var outputBuffer = Data(count: outputBufferSize)
            
            // Initialize the decompression stream
            var stream = ZSTD_inBuffer()
            var remainingData = compressedData
            
            let dctx = ZSTD_createDCtx();
            
            while !remainingData.isEmpty {
                // Fill the input buffer
                let chunkSize = min(inputBufferSize, remainingData.count)
                inputBuffer.replaceSubrange(0..<chunkSize, with: remainingData.subdata(in: 0..<chunkSize))
                remainingData.removeSubrange(0..<chunkSize)
                
                stream.src = inputBuffer.withUnsafeBytes { $0.baseAddress }
                stream.size = chunkSize
                stream.pos = 0
                
                // Decompress the data in chunks
                while stream.pos < stream.size {
                    var outStream = ZSTD_outBuffer()
                    outStream.dst = outputBuffer.withUnsafeMutableBytes { $0.baseAddress }
                    outStream.size = outputBufferSize
                    outStream.pos = 0
                    
                    let result = ZSTD_decompressStream(dctx, &outStream, &stream)
                    guard result >= 0 else {
                        throw NSError(domain: "ZSTDError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Decompression failed"])
                    }
                    
                    // Append the decompressed chunk to the result
                    decompressedData.append(outputBuffer.subdata(in: 0..<outStream.pos))
                }
            }
            
            // Write the decompressed data to the destination file
            try decompressedData.write(to: destinationPath)
        }
    }
    
    
    static func extractDb(_ fileUrl: URL, workDir: URL, fileManager: FileManager) throws -> (Connection, AnkiPackageFormat) {
        try fileManager.unzipItem(at: fileUrl, to: workDir)
        
        guard let format = findPackageFormat(workDir) else {
            throw ApkgError.collectionDatabaseNotFound
        }
        
        if format == .anki21b {
            let decompressed_db_path = workDir.appendingPathComponent("collection.anki21b_dec")
            try decompressZstdFile(atPath: workDir.appendingPathComponent(AnkiPackageFormat.anki21b.rawValue), toDestination: decompressed_db_path)
            
            return try (Connection(decompressed_db_path.absoluteString), format)
        } else {
            return try (Connection(workDir.appendingPathComponent(format.rawValue).absoluteString), format)
        }
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
        
        let (db, format) = try extractDb(fileUrl, workDir: workDir, fileManager: fileManager)
        
        let collections = try parseCollections(db, format: format)
        let notes = try parseNotes(db)
        let cards = try parseCards(db)
        let revlog = try parseRevlog(db)
        let mediaMapping = try parseMediaMapping(workDir, format: format)
        
        try fileManager.removeItem(at: workDir)
        
        return AnkiPackage(collections: collections,
                           notes: ankiListToDict(notes),
                           cards: ankiListToDict(cards),
                           revlog: ankiListToDict(revlog),
                           mediaMapping: mediaMapping)
    }
    
    public static func streamReader(_ fileUrl: URL) throws -> AnkiStreamReader {
        let fileManager = FileManager()
        let workDir = fileManager.temporaryDirectory.appendingPathComponent("apkg_contents")
        
        // Erase any workdir remaining after a previous import
        do {
            try fileManager.removeItem(at: workDir)
        } catch {
            // Do nothing
        }
        
        let (db, format) = try extractDb(fileUrl, workDir: workDir, fileManager: fileManager)
        
        let collections = try parseCollections(db, format: format)
        let mediaMapping = try parseMediaMapping(workDir, format: format)
        
        return try AnkiStreamReader(db: db, collections: collections, mediaMapping: mediaMapping)
    }
}
