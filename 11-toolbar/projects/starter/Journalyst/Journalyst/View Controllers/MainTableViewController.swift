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

class MainTableViewController: UITableViewController {
  
  // MARK: - Properties
  var dataSource: UITableViewDiffableDataSource<Int, Entry>?
  var entryTableViewController: EntryTableViewController? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let dataSource = self.diaryDataSource()
    tableView.dataSource = dataSource
    self.dataSource = dataSource
    if let splitViewController = splitViewController,
      let splitNavigationController = splitViewController.viewControllers.last as? UINavigationController,
      let topViewController = splitNavigationController.topViewController as? EntryTableViewController {
      entryTableViewController = topViewController
    }

    tableView.dragDelegate = self

    NotificationCenter.default.addObserver(self, selector: #selector(handleEntriesUpdate), name: .JournalEntriesUpdated, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    populateData()
  }
  
  // MARK: - Actions
  @IBAction private func addEntry(_ sender: Any) {
    DataService.shared.addEntry(Entry())
  }
  
  func selectEntryAtIndex(_ index: Int) {
    var indexToSelect = index
    if index >= DataService.shared.allEntries.count {
      indexToSelect = DataService.shared.allEntries.count - 1
    }
    guard indexToSelect >= 0 else {
      return
    }
    let indexPath = IndexPath(row: indexToSelect, section: 0)
    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
    let cell = tableView.cellForRow(at: indexPath)
    performSegue(withIdentifier: "ShowEntrySegue", sender: cell)
  }
  
  // MARK: - Navigation
  @IBSegueAction func entryViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> UINavigationController? {
    guard let cell = sender as? EntryTableViewCell,
      let indexPath = tableView.indexPath(for: cell),
      let navigationController = UINavigationController(coder: coder),
      let entryTableViewController = navigationController.topViewController as? EntryTableViewController else { return nil }
    entryTableViewController.entry = dataSource?.itemIdentifier(for: indexPath)
    self.entryTableViewController = entryTableViewController
    return navigationController
  }
}

// MARK: - Table Data Source
extension MainTableViewController {
  private func diaryDataSource() -> UITableViewDiffableDataSource<Int, Entry> {
    let reuseIdentifier = "EntryTableViewCell"
    return UITableViewDiffableDataSource(tableView: tableView) { (tableView, indexPath, entry) -> EntryTableViewCell? in
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? EntryTableViewCell
      cell?.entry = entry
      return cell
    }
  }
  
  private func populateData() {
    reloadSnapshot(animated: false)
    if let entryTableViewController = entryTableViewController,
      let entry = DataService.shared.allEntries.first,
      entryTableViewController.entry == nil {
      tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
      entryTableViewController.entry = entry
    }
  }
  
  private func reloadSnapshot(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Entry>()
    snapshot.appendSections([0])
    snapshot.appendItems(DataService.shared.allEntries)
    dataSource?.apply(snapshot, animatingDifferences: animated)
  }

  @objc func handleEntriesUpdate() {
    reloadSnapshot(animated: true)
  }

}

// MARK: - Table View Delegate
extension MainTableViewController {
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .delete
  }
  
  override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completion) in
      DataService.shared.removeEntry(atIndex: indexPath.row)
    }
    deleteAction.image = UIImage(systemName: "trash")
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
}

// MARK: UITableViewDragDelegate
extension MainTableViewController: UITableViewDragDelegate {

  func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    let entry = DataService.shared.allEntries[indexPath.row]
    let userActivity = entry.openDetailUserActivity
    let itemProvider = NSItemProvider()
    itemProvider.registerObject(userActivity, visibility: .all)

    let dragItem = UIDragItem(itemProvider: itemProvider)
    dragItem.localObject = entry

    return [dragItem]
  }
}
