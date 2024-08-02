 # ApkgIOSwift
 
A (very basic) swift package for reading/loading Anki package files (.apkg).
 
For now, this package simply offers a mapping between some Swift structs and the internal data structures of .apkg files. It is almost a 1-to-1 mapping, therefore some understanding of the inner structure of .apkg files is required. Reading this wiki page from AnkiDroid is recommended: https://github.com/ankidroid/Anki-Android/wiki/Database-Structure

Notes:
 - Some fields related to the Anki internal app settings/features such as the review UI/UX settings or fields for data sync are not retrieved.
 - This package does not support (yet) saving .apkg files, only loading.
 - Only recent .apkg files containing a "collection.anki21" database file can be loaded.
 - This package has been quickly made for a side project. I don't recommend using it for any serious application, at least for now.

## Usage

Please check the test for how to use this package.

## Planned features and progress

 - [ ] Stream loading, necessary for loading large .apkg files without running out of memory.
 - [ ] Saving .apkg files.
 - [x] Support multiple versions of .apkg files.
     - `collection.anki21` supported
     - `collection.anki2` supported
 - [x] Better error reporting
     - *Note: currently partial implementation, but no panic errors anymore*
