import Foundation
import XCTest
import ApkgIO

final class AnkiIOTests : XCTestCase {
    func testBasicExample() {
        // Replace with an actual path to a .apkg file
        let str = "my.apkg"
        
        do {
            // This is the only function of this package
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
}
