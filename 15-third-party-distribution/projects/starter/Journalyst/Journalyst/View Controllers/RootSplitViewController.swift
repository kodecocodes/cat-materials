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

#if targetEnvironment(macCatalyst)
extension NSTouchBar.CustomizationIdentifier {
  static let journalyst = NSTouchBar.CustomizationIdentifier(
    "com.yourcompany.journalyst.main")
}

extension NSTouchBarItem.Identifier {
  static let newEntry = NSTouchBarItem.Identifier("com.yourcompany.Journalyst.addEntry")
  static let entryOptions = NSTouchBarItem.Identifier("com.yourcompany.journalyst.entryOptions")
}
#endif

class RootSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
  override func viewDidLoad() {
    super.viewDidLoad()
    let splitViewController = self
    let navigationController =
      splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as? UINavigationController
    splitViewController.delegate = self
    navigationController?.topViewController?.navigationItem.leftBarButtonItem =
      splitViewController.displayModeButtonItem
    splitViewController.primaryBackgroundStyle = .sidebar
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  func splitViewController(
    _ splitViewController: UISplitViewController,
    collapseSecondary secondaryViewController: UIViewController,
    onto primaryViewController: UIViewController
  ) -> Bool {
    guard let secondaryNavigationController = secondaryViewController as? UINavigationController,
      let entryTableViewController = secondaryNavigationController.topViewController as? EntryTableViewController else {
      return false
    }
    if entryTableViewController.entry == nil {
      return true
    }
    return false
  }

  // MARK: - Keyboard Commands
  override var canBecomeFirstResponder: Bool {
    return true
  }

  override var keyCommands: [UIKeyCommand]? {
    let newKeyCommand = UIKeyCommand(
      input: "N",
      modifierFlags: .control,
      action: #selector(addEntry(sender:)))
    newKeyCommand.discoverabilityTitle = "Add Entry"
    let upKeyCommand = UIKeyCommand(
      input: "[",
      modifierFlags: [.command, .shift],
      action: #selector(goToPrevious(sender:)))
    upKeyCommand.discoverabilityTitle = "Previous Entry"
    let downKeyCommand = UIKeyCommand(
      input: "]",
      modifierFlags: [.command, .shift],
      action: #selector(goToNext(sender:)))
    downKeyCommand.discoverabilityTitle = "Next Entry"

    let deleteKeyCommand = UIKeyCommand(
      input: "\u{8}",
      modifierFlags: [.command],
      action: #selector(removeEntry(sender:)))
    deleteKeyCommand.discoverabilityTitle = "Delete Entry"

    return [newKeyCommand, upKeyCommand, downKeyCommand, deleteKeyCommand]
  }

  @IBAction @objc private func addEntry(sender: UIKeyCommand) {
    DataService.shared.addEntry(Entry())
  }

  @objc private func goToPrevious(sender: UIKeyCommand) {
    guard let navigationController = viewControllers.first as? UINavigationController,
      let mainTableViewController = navigationController.topViewController as? MainTableViewController else { return }
    mainTableViewController.goToPrevious()
  }

  @objc private func goToNext(sender: UIKeyCommand) {
    guard let navigationController = viewControllers.first as? UINavigationController,
      let mainTableViewController = navigationController.topViewController as? MainTableViewController else { return }
    mainTableViewController.goToNext()
  }

  @IBAction @objc private func removeEntry(sender: UIKeyCommand) {
    guard let navigationController = viewControllers.first as? UINavigationController,
      let mainTableViewController = navigationController.topViewController as? MainTableViewController else { return }
    mainTableViewController.deleteCurentEntry()
  }

  override func validate(_ command: UICommand) {
    switch command.action {
    case #selector(removeEntry):
      if let mainNavigationController = viewController(for: .primary) as? UINavigationController,
        let mainTableViewController = mainNavigationController.topViewController as? MainTableViewController,
        let selectedIndexPath = mainTableViewController.tableView.indexPathForSelectedRow {
        let entry = DataService.shared.allEntries[selectedIndexPath.row]
        command.title = "Delete \(entry.dateCreated)"
      } else {
        command.title = "Delete Entry"
      }
    default:
      break
    }
  }

  #if targetEnvironment(macCatalyst)
  override func makeTouchBar() -> NSTouchBar? {
    let bar = NSTouchBar()
    bar.delegate = self
    bar.defaultItemIdentifiers = [.newEntry, .entryOptions]
    bar.principalItemIdentifier = .entryOptions
    bar.customizationIdentifier = .journalyst
    bar.customizationAllowedItemIdentifiers = [.newEntry, .entryOptions]
    return bar
  }
  #endif
}

#if targetEnvironment(macCatalyst)
extension RootSplitViewController: NSTouchBarDelegate {
  func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
    switch identifier {
    case .newEntry:
      let button = NSButtonTouchBarItem(
        identifier: identifier,
        title: "New Entry",
        target: self,
        action: #selector(addEntry))
      button.customizationLabel = "Add a new entry"
      return button
    case .entryOptions:
      let copy = NSButtonTouchBarItem(
        identifier: .init(identifier.rawValue + ".next"),
        title: "Next Entry",
        target: self,
        action: #selector(goToNext))
      let favorite = NSButtonTouchBarItem(
        identifier: .init(identifier.rawValue + ".previous"),
        title: "Previous Entry",
        target: self,
        action: #selector(goToPrevious))
      let delete = NSButtonTouchBarItem(
        identifier: .init(identifier.rawValue + ".delete"),
        title: "Delete",
        target: self,
        action: #selector(removeEntry))

      let spacer = NSTouchBarItem(identifier: .fixedSpaceLarge)

      let group = NSGroupTouchBarItem(
        identifier: identifier,
        items: [spacer, copy, favorite, spacer, delete])
      group.customizationLabel = "Entry Options"
      return group
    default:
      return nil
    }
  }
}
#endif
