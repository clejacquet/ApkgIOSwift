import Foundation
import SQLite


public class AnkiStreamReader {
    public let collections: [AnkiCollection]
    public let mediaMapping: [String: String]
    public let cardsCount: Int64
    public let notesCount: Int64
    public let revlogCount: Int64
    
    private let db: Connection
    private var cardsRead: Int64 = 0
    private var notesRead: Int64 = 0
    private var revlogRead: Int64 = 0
    
    public var remainingCards: Int64 { get {
        return cardsCount - cardsRead
    }}
    
    public var remainingNotes: Int64 { get {
        return notesCount - notesRead
    }}
    
    public var remainingRevlog: Int64 { get {
        return revlogCount - revlogRead
    }}
    
    init(db: Connection, collections: [AnkiCollection], mediaMapping: [String: String]) throws {
        self.db = db
        self.collections = collections
        self.mediaMapping = mediaMapping
        
        let query = """
            SELECT
                (SELECT COUNT(*) FROM cards) AS cards_count,
                (SELECT COUNT(*) FROM notes) AS notes_count,
                (SELECT COUNT(*) FROM revlog) AS revlog_count;
        """
        
        let cardsCountExpr = SQLite.Expression<Int64>("cards_count")
        let notesCountExpr = SQLite.Expression<Int64>("notes_count")
        let revlogCountExpr = SQLite.Expression<Int64>("revlog_count")
        
        let counts = try db.prepareRowIterator(query).map { row in
            return [row[cardsCountExpr], row[notesCountExpr], row[revlogCountExpr]]
        }.first!
        
        self.cardsCount = counts[0]
        self.notesCount = counts[1]
        self.revlogCount = counts[2]
    }
    
    public func readCards(_ count: Int64) throws -> [AnkiCard] {
        guard remainingCards > 0 else {
            return []
        }

        let offset = self.cardsRead
        let length = min(count, remainingCards)
        
        let cardsBatch = try AnkiPackage.parseCards(self.db, length: length, offset: offset)
        
        self.cardsRead += length
        
        return cardsBatch
    }
    
    public func readNotes(_ count: Int64) throws -> [AnkiNote] {
        guard remainingNotes > 0 else {
            return []
        }

        let offset = self.notesRead
        let length = min(count, remainingNotes)
        
        let notesBatch = try AnkiPackage.parseNotes(self.db, length: length, offset: offset)
        
        self.notesRead += length
        
        return notesBatch
    }
    
    public func readRevlog(_ count: Int64) throws -> [AnkiRevlog] {
        guard remainingRevlog > 0 else {
            return []
        }

        let offset = self.revlogRead
        let length = min(count, remainingRevlog)
        
        
        let revlogBatch = try AnkiPackage.parseRevlog(self.db, length: length, offset: offset)
        
        self.revlogRead += length
        
        return revlogBatch
    }
    
    public func readAllCardBatched(_ batchSize: Int64, callback: ([AnkiCard], Int64) -> ()) throws {
        while remainingCards > 0 {
            let offset = cardsRead
            let cardBatch = try readCards(batchSize)
            callback(cardBatch, offset)
        }
    }
    
    public func readAllNotesBatched(_ batchSize: Int64, callback: ([AnkiNote], Int64) -> ()) throws {
        while remainingNotes > 0 {
            let offset = notesRead
            let noteBatch = try readNotes(batchSize)
            callback(noteBatch, offset)
        }
    }
    
    public func readAllRevlogBatched(_ batchSize: Int64, callback: ([AnkiRevlog], Int64) -> ()) throws {
        while remainingRevlog > 0 {
            let offset = revlogRead
            let revlogBatch = try readRevlog(batchSize)
            callback(revlogBatch, offset)
        }
    }
}
