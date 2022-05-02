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

import UIKit
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  #if targetEnvironment(macCatalyst)
  private let shareItem =
    NSSharingServicePickerToolbarItem(itemIdentifier: .shareEntry)
  #endif
  private var activityItemsConfigurationSubscriber: AnyCancellable?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
      if !configure(window: window, with: userActivity) {
        print("Failed to restore from \(userActivity)")
      }
    }
    #if targetEnvironment(macCatalyst)
    if
      let scene = scene as? UIWindowScene,
      let titlebar = scene.titlebar {
      let toolbar = NSToolbar(identifier: "Toolbar")
      titlebar.toolbar = toolbar
      toolbar.delegate = self
      activityItemsConfigurationSubscriber = NotificationCenter.default
        .publisher(for: .ActivityItemsConfigurationDidChange)
        .receive(on: RunLoop.main)
        .map {
          $0.userInfo?[NotificationKey.activityItemsConfiguration]
            as? UIActivityItemsConfiguration
        }
        .assign(to: \.activityItemsConfiguration, on: shareItem)
      toolbar.allowsUserCustomization = true
      toolbar.autosavesConfiguration = true
    }
    #endif
  }

  func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
    guard activity.title == Entry.OpenDetailPath,
      let entryID = activity.userInfo?[Entry.OpenDetailIdKey] as? String,
      let entry = DataService.shared.entry(forID: entryID),
      let entryDetailViewController = EntryTableViewController.loadFromStoryboard(),
      let splitViewController = window?.rootViewController as? UISplitViewController else {
        return false
    }

    entryDetailViewController.entry = entry
    splitViewController.showDetailViewController(entryDetailViewController, sender: self)
    return true
  }
}

#if targetEnvironment(macCatalyst)
// MARK: NSToolbarItem.Identifier
extension NSToolbarItem.Identifier {
  static let addEntry =
    NSToolbarItem.Identifier(rawValue: "AddEntry")
  static let deleteEntry =
    NSToolbarItem.Identifier(rawValue: "DeleteEntry")
  static let shareEntry =
    NSToolbarItem.Identifier(rawValue: "ShareEntry")
}

// MARK: NSToolbarDelegate
extension SceneDelegate: NSToolbarDelegate {
  func toolbarAllowedItemIdentifiers(
    _ toolbar: NSToolbar
  ) -> [NSToolbarItem.Identifier] {
    return [.toggleSidebar, .addEntry, .deleteEntry, .shareEntry, .flexibleSpace]
  }

  func toolbarDefaultItemIdentifiers(
    _ toolbar: NSToolbar
  ) -> [NSToolbarItem.Identifier] {
    return [.toggleSidebar, .addEntry, .shareEntry]
  }

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    var item: NSToolbarItem?
    switch itemIdentifier {
    case .addEntry:
      item = NSToolbarItem(itemIdentifier: .addEntry)
      item?.image = UIImage(systemName: "plus")
      item?.label = "Add"
      item?.toolTip = "Add Entry"
      item?.target = self
      item?.action = #selector(addEntry)
    case .deleteEntry:
      item = NSToolbarItem(itemIdentifier: .deleteEntry)
      item?.image = UIImage(systemName: "trash")
      item?.label = "Delete"
      item?.toolTip = "Delete Entry"
      item?.target = self
      item?.action = #selector(deleteEntry)
    case .shareEntry:
      return shareItem
    case .toggleSidebar:
      item = NSToolbarItem(itemIdentifier: itemIdentifier)
    default:
      item = nil
    }
    return item
  }

  @objc private func addEntry() {
    guard
      let splitViewController = window?.rootViewController as? UISplitViewController,
      let navigationController
        = splitViewController.viewControllers.first
        as? UINavigationController,
      let mainTableViewController
        = navigationController.topViewController
        as? MainTableViewController else {
      return
    }
    DataService.shared.addEntry(Entry())
    let index = DataService.shared.allEntries.count - 1
    mainTableViewController.selectEntryAtIndex(index)
  }
  @objc private func deleteEntry() {
    guard
      let splitViewController =
        window?.rootViewController as? UISplitViewController,
      let navigationController =
        splitViewController.viewControllers.first
        as? UINavigationController,
      let mainTableViewController =
        navigationController.topViewController
        as? MainTableViewController,
      let secondaryViewController =
        splitViewController.viewControllers.last
        as? UINavigationController,
      let entryTableViewController =
        secondaryViewController.topViewController
        as? EntryTableViewController,
      let entry = entryTableViewController.entry,
      let index = DataService.shared.allEntries
        .firstIndex(of: entry) else { return }
    DataService.shared.removeEntry(atIndex: index)
    mainTableViewController.selectEntryAtIndex(index)
  }
}
#endif
