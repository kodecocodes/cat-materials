/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

extension Notification.Name {
  static var JournalEntriesUpdated = Notification.Name("com.yourcompany.Journalyst.EntriesUpdated")
  static var JournalEntryUpdated = Notification.Name("com.yourcompany.Journalyst.EntryUpdated")
}

enum DataNotificationKeys {
  static let entry = "entry"
}

class DataService {
  static let shared = DataService()

  private var entries: [Entry] = [Entry()]

  var allEntries: [Entry] {
    return entries
  }

  func entry(forID entryID: String) -> Entry? {
    return entries.first { $0.id == entryID }
  }

  func addEntry(_ entry: Entry) {
    entries.append(entry)
    postUpdate()
  }

  func updateEntry(_ entry: Entry) {
    var hasChanges: Bool = false
    entries = entries.map { ent -> Entry in
      if ent.id == entry.id && ent != entry {
        hasChanges = true
        return entry
      } else {
        return ent
      }
    }

    if hasChanges {
      NotificationCenter.default.post(
        name: .JournalEntryUpdated,
        object: nil,
        userInfo: [DataNotificationKeys.entry: entry])
      postUpdate()
    }
  }

  func removeEntry(atIndex index: Int) {
    entries.remove(at: index)
    postUpdate()
  }

  private func postUpdate() {
    NotificationCenter.default.post(name: .JournalEntriesUpdated, object: nil)
  }
}
