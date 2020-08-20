/// Copyright (c) 2020 Razeware LLC
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

class RootSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let splitViewController = self
    if let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as? UINavigationController {
      navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
    }
    splitViewController.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  func splitViewController(_ splitViewController: UISplitViewController,
                           collapseSecondary secondaryViewController: UIViewController,
                           onto primaryViewController: UIViewController) -> Bool {
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
    let newKeyCommand = UIKeyCommand(input: "N",
                                     modifierFlags: .control,
                                     action: #selector(addEntry(sender:)))
    newKeyCommand.discoverabilityTitle = "Add Entry"
    let upKeyCommand = UIKeyCommand(input: "[",
                                    modifierFlags: [.command, .shift],
                                    action: #selector(goToPrevious(sender:)))
    upKeyCommand.discoverabilityTitle = "Previous Entry"
    let downKeyCommand = UIKeyCommand(input: "]",
                                      modifierFlags: [.command, .shift],
                                      action: #selector(goToNext(sender:)))
    downKeyCommand.discoverabilityTitle = "Next Entry"
   
    let deleteKeyCommand = UIKeyCommand(input: "\u{8}",
                                        modifierFlags: [],
                                     action: #selector(removeEntry(sender:)))
    deleteKeyCommand.discoverabilityTitle = "Delete Entry"

    return [newKeyCommand, upKeyCommand, downKeyCommand, deleteKeyCommand]
  }
  
  @objc private func addEntry(sender: UIKeyCommand) {
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
  
  @objc private func removeEntry(sender: UIKeyCommand) {
    guard let navigationController = viewControllers.first as? UINavigationController,
      let mainTableViewController = navigationController.topViewController as? MainTableViewController else { return }
    mainTableViewController.deleteCurentEntry()
  }
  
}
