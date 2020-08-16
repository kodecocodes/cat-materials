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
  var entries: [Entry] = [Entry()]
  var dataSource: EntryDataSource?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let dataSource = self.diaryDataSource()
    tableView.dataSource = dataSource
    self.dataSource = dataSource
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    populateMockData()
  }
  
  // MARK: - Actions
  @IBAction private func addEntry(_ sender: Any) {
    entries.append(Entry())
    reloadSnapshot(animated: true)
  }
  
  // MARK: - Navigation
  @IBSegueAction func entryViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> EntryTableViewController? {
    guard let cell = sender as? EntryTableViewCell,
      let indexPath = tableView.indexPath(for: cell) else { return nil }
    let entryTableViewController = EntryTableViewController(coder: coder)
    entryTableViewController?.entry = dataSource?.itemIdentifier(for: indexPath)
    return entryTableViewController
  }
  
}

// MARK: - Table Data Source
extension MainTableViewController {
  private func diaryDataSource() -> EntryDataSource {
    let reuseIdentifier = "EntryTableViewCell"
    return EntryDataSource(tableView: tableView) { (tableView, indexPath, entry) -> EntryTableViewCell? in
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? EntryTableViewCell
      cell?.entry = entry
      return cell
    }
  }
  
  private func populateMockData() {
    reloadSnapshot(animated: false)
  }
  
  private func reloadSnapshot(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Entry>()
    snapshot.appendSections([0])
    snapshot.appendItems(entries)
    dataSource?.apply(snapshot, animatingDifferences: animated)
  }
}

// MARK: - Table View Delegate
extension MainTableViewController {
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .delete
  }
  
  override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
      self?.entries.remove(at: indexPath.row)
      self?.reloadSnapshot(animated: true)
    }
    deleteAction.image = UIImage(systemName: "trash")
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
}
