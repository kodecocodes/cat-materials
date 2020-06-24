/// Copyright (c) 2019 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

extension Notification.Name {
  static var WindowSizeChanged = Notification.Name("com.raywenderlich.Journalyst.WindowSizeChanged")
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    if let scene = scene as? UIWindowScene {
      scene.sizeRestrictions?.minimumSize = CGSize(width: 768.0, height: 768.0)
      scene.sizeRestrictions?.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }
    if let userActivity = connectionOptions.userActivities.first {
      if !configure(window: window, with: userActivity) {
        print("Failed to restore from \(userActivity)")
      }
    }
    #if targetEnvironment(macCatalyst)
    if let scene = scene as? UIWindowScene, let titlebar = scene.titlebar {
      let toolbar = NSToolbar(identifier: "Toolbar")
      toolbar.allowsUserCustomization = true
      toolbar.autosavesConfiguration = true
      toolbar.delegate = self
      titlebar.titleVisibility = .hidden
      titlebar.toolbar = toolbar
    }
    #endif
  }
  
  func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
    NotificationCenter.default.post(name: .WindowSizeChanged, object: nil)
  }
  
  func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
    guard activity.activityType == Entry.OpenDetailActivityType,
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
extension NSToolbarItem.Identifier {
  static let addEntry =
    NSToolbarItem.Identifier(rawValue: "AddEntry")
  static let deleteEntry =
    NSToolbarItem.Identifier(rawValue: "DeleteEntry")
  static let shareEntry =
    NSToolbarItem.Identifier(rawValue: "ShareEntry")
}

extension SceneDelegate: NSToolbarDelegate {
  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [.addEntry, .deleteEntry, .shareEntry, .flexibleSpace]
  }
  
  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [.addEntry, .flexibleSpace, .shareEntry]
  }
  
  func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    
    var item: NSToolbarItem? = nil
    if itemIdentifier == .addEntry {
      let barButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                          target: self,
                                          action: #selector(addEntry))
      item = toolbarItem(itemIdentifier: .addEntry,
                         barButtonItem: barButtonItem,
                         toolTip: "Add Entry",
                         label: "Add")
      item?.target = self
      item?.action = #selector(addEntry)
    } else if itemIdentifier == .deleteEntry {
      let barButtonItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                          target: self,
                                          action: #selector(deleteEntry))
      item = toolbarItem(itemIdentifier: .deleteEntry,
                         barButtonItem: barButtonItem,
                         toolTip: "Delete Entry",
                         label: "Delete")
      item?.target = self
      item?.action = #selector(deleteEntry)
    } else if itemIdentifier == .shareEntry {
      let barButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                          target: self,
                                          action: #selector(shareEntry(_:)))
      item = toolbarItem(itemIdentifier: .shareEntry,
                         barButtonItem: barButtonItem,
                         toolTip: "Share Entry",
                         label: "Share")
    }
    return item
  }
  
  @objc private func addEntry() {
    DataService.shared.addEntry(Entry())
  }
  
  @objc private func deleteEntry() {
    guard let splitViewController = window?.rootViewController as? UISplitViewController,
      let navigationController = splitViewController.viewControllers.first as? UINavigationController,
      let mainTableViewController = navigationController.topViewController as? MainTableViewController,
      let secondaryViewController = splitViewController.viewControllers.last as? UINavigationController,
      let entryTableViewController = secondaryViewController.topViewController
        as? EntryTableViewController,
      let entry = entryTableViewController.entry,
      let index = DataService.shared.allEntries.firstIndex(of: entry)
    else { return }
    
    DataService.shared.removeEntry(atIndex: index)
    mainTableViewController.selectEntry(at: index)
  }
  
  @objc private func shareEntry(_ sender: UIBarButtonItem) {
    guard let splitViewController =
      window?.rootViewController as? UISplitViewController,
      let navigationController =
      splitViewController.viewControllers.last
        as? UINavigationController,
      let entryTableViewController =
      navigationController.topViewController
        as? EntryTableViewController else {
        return
    }
    entryTableViewController.share(sender)
  }
  
  private func toolbarItem(itemIdentifier: NSToolbarItem.Identifier, barButtonItem: UIBarButtonItem, toolTip: String? = nil, label: String?) -> NSToolbarItem {
    let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
    item.isBordered = true
    item.toolTip = toolTip
    item.paletteLabel = label ?? ""
    if let label = label {
      item.label = label
    }
    return item
  }
}
#endif
