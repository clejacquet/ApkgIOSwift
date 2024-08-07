import Foundation
import XCTest
import ApkgIO

final class AnkiIOTests : XCTestCase {
    func testBasicExample() {
        // Replace with an actual path to a .apkg file
        let str = "my.apkg"
        
        do {
            let ankiPackage = try AnkiPackage.parse(URL(filePath: str))
            
            print("There are \(ankiPackage.collections.count) collections in this .apkg file")
            print("In total, it contains \(ankiPackage.cards.count) cards and \(ankiPackage.revlog.count) reviews")
            
            if let collection = ankiPackage.collections.first {
                print("The first collection contains \(collection.decks.count) decks")
            }
            
            if let card = ankiPackage.cards.first {
                let note = ankiPackage.notes[card.value.nid]!
                print("The first card's note has \(note.flds.count) fields")
            }
            
            if let review = ankiPackage.revlog.first {
                print("The first review's card is \(review.value.cid)")
                print("The first review's ease is \(review.value.ease)")
            }
        } catch {
            print(error.localizedDescription)
            XCTAssertTrue(false)
        }
        
    }
    
    func testStreamExample() {
        // Replace with an actual path to a .apkg file
        let str = "my.apkg"
        
        do {
            let ankiStreamReader = try AnkiPackage.streamReader(URL(filePath: str))
            
            var cards = [AnkiCard]()
            try ankiStreamReader.readAllCardBatched(50) { cardBatch, _ in
                cards.append(contentsOf: cardBatch)
                print("[Cards Download] Progress: \(cards.count) / \(ankiStreamReader.cardsCount)")
            }
            
            var notes = [AnkiNote]()
            try ankiStreamReader.readAllNotesBatched(50) { noteBatch, _ in
                notes.append(contentsOf: noteBatch)
                print("[Notes Download] Progress: \(notes.count) / \(ankiStreamReader.notesCount)")
            }
            
            var revlog = [AnkiRevlog]()
            try ankiStreamReader.readAllRevlogBatched(50) { revlogBatch, _ in
                revlog.append(contentsOf: revlogBatch)
                print("[Revlog Download] Progress: \(revlog.count) / \(ankiStreamReader.revlogCount)")
            }
            
            print("There are \(ankiStreamReader.collections.count) collections in this .apkg file")
            print("In total, it contains \(cards.count) cards and \(revlog.count) reviews")
            
            if let collection = ankiStreamReader.collections.first {
                print("The first collection contains \(collection.decks.count) decks")
            }
            
            let notesDict = ankiListToDict(notes)
            
            if let card = cards.first {
                let note = notesDict[card.nid]!
                print("The first card's note has \(note.flds.count) fields")
            }
            
            if let review = revlog.first {
                print("The first review's card is \(review.cid)")
                print("The first review's ease is \(review.ease)")
            }
        } catch {
            print(error.localizedDescription)
            XCTAssertTrue(false)
        }
        
    }
}
