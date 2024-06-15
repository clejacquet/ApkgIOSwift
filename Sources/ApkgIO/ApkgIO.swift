import Foundation
import ZIPFoundation
import SQLite


public struct AnkiCard {
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

public struct AnkiNoteField: Decodable {
    enum CodingKeys: String, CodingKey {
        case ord
        case name
    }
    
    public let ord: Int64
    public let name: String
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.ord = try values.decode(Int64.self, forKey: .ord)
        self.name = try values.decode(String.self, forKey: .name)
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
    public let css: String
    public let did: Int64
    public let flds: [AnkiNoteField]
    public let tmpls: [AnkiNoteTemplate]
    public let type: Int64
    
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int64.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.mod = try values.decode(Int64.self, forKey: .mod)
        self.css = try values.decode(String.self, forKey: .css)
        self.did = try values.decode(Int64.self, forKey: .did)
        self.flds = try values.decode([AnkiNoteField].self, forKey: .flds)
        self.tmpls = try values.decode([AnkiNoteTemplate].self, forKey: .tmpls)
        self.type = try values.decode(Int64.self, forKey: .type)
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
}

public struct AnkiPackage {
    public let collections: [AnkiCollection]
    public let notes: [Int64: AnkiNote]
    public let cards: [Int64: AnkiCard]
    public let revlog: [Int64: AnkiRevlog]
    public let mediaMapping: [String: String]
    
    public static func parse(_ fileUrl: URL) throws -> AnkiPackage {
        let fileManager = FileManager()
        let destinationUrl = fileManager.temporaryDirectory.appendingPathComponent("apkg_contents")
        
        do {
            try fileManager.removeItem(at: destinationUrl)
        } catch {
            // Do nothing
        }
        
        try fileManager.unzipItem(at: fileUrl, to: destinationUrl)
        
        let dbPath = destinationUrl.appendingPathComponent("collection.anki21")
        
        var ankiPackage: AnkiPackage
        do {
            let db = try Connection(dbPath.absoluteString)
            
            let colQuery = try db.prepare("SELECT models, decks FROM col")
            
            let noteModelsJson = colQuery.map { row in
                row[0] as! String
            }
            
            let decksJson = colQuery.map { row in
                row[1] as! String
            }
            
            let colCount = noteModelsJson.count
            
            let decoder = JSONDecoder()
            
            let noteModelsDict = try noteModelsJson.map { noteModelJson in
                let noteModelsDict = try decoder.decode([String: AnkiNoteModel].self, from: noteModelJson.data(using: .utf8)!)
                return Dictionary(uniqueKeysWithValues: noteModelsDict.map { (Int64($0.key)!, $0.value) })
            }
            
            let decksDict = try decksJson.map { deckJson in
                let deckDict = try decoder.decode([String: AnkiDeck].self, from: deckJson.data(using: .utf8)!)
                return Dictionary(uniqueKeysWithValues: deckDict.map { (Int64($0.key)!, $0.value) })
            }
            
            let notes = try db.prepare("SELECT id, guid, mid, mod, flds FROM notes").map { row in
                let id = row[0] as! Int64
                let guid = row[1] as! String
                let mid = row[2] as! Int64
                let mod = row[3] as! Int64
                
                let fldsStr = row[4] as! String
                let separator = String(UnicodeScalar(0x1f))
                let flds = fldsStr.components(separatedBy: separator)
                
                return AnkiNote(id: id, guid: guid, mid: mid, mod: mod, flds: flds)
            }
            let notesDict = Dictionary(uniqueKeysWithValues: notes.map { ($0.id, $0) })
            
            let cards = try db.prepare("SELECT id, nid, did, ord, mod, type, queue, due, ivl, factor, reps, lapses, left, flags FROM cards").map { row in
                let id = row[0] as! Int64
                let nid = row[1] as! Int64
                let did = row[2] as! Int64
                let ord = row[3] as! Int64
                let mod = row[4] as! Int64
                let type = row[5] as! Int64
                let queue = row[6] as! Int64
                let due = row[7] as! Int64
                let ivl = row[8] as! Int64
                let factor = row[9] as! Int64
                let reps = row[10] as! Int64
                let lapses = row[11] as! Int64
                let left = row[12] as! Int64
                let flags = row[13] as! Int64
                
                return AnkiCard(id: id, nid: nid, did: did, ord: ord, mod: mod, type: type, queue: queue, due: due, ivl: ivl, factor: factor, reps: reps, lapses: lapses, left: left, flags: flags)
            }
            let cardsDict = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
            
            let revlog = try db.prepare("SELECT id, cid, ease, ivl, lastIvl, factor, time, type FROM revlog").map { row in
                let id = row[0] as! Int64
                let cid = row[1] as! Int64
                let ease = row[2] as! Int64
                let ivl = row[3] as! Int64
                let lastIvl = row[4] as! Int64
                let factor = row[5] as! Int64
                let time = row[6] as! Int64
                let type = row[7] as! Int64
                
                return AnkiRevlog(id: id, cid: cid, ease: ease, ivl: ivl, lastIvl: lastIvl, factor: factor, time: time, type: type)
            }
            let revlogDict = Dictionary(uniqueKeysWithValues: revlog.map { ($0.id, $0) })
            
            var collections = [AnkiCollection]()
            
            for i in 0..<colCount {
                collections.append(AnkiCollection(decks: decksDict[i], noteModels: noteModelsDict[i]))
            }
            
            let mediaData = try Data(contentsOf: destinationUrl.appendingPathComponent("media"))
            let mediaMapping = try decoder.decode([String: String].self, from: mediaData)
    
            ankiPackage = AnkiPackage(collections: collections, notes: notesDict, cards: cardsDict, revlog: revlogDict, mediaMapping: mediaMapping)
        }
        
        try fileManager.removeItem(at: destinationUrl)
        
        
        return ankiPackage
    }
}
