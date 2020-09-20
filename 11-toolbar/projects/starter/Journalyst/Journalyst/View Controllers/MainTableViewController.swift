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

class MainTableViewController: UITableViewController {
  // MARK: - Properties
  var dataSource: EntryDataSource?
  var entryTableViewController: EntryTableViewController? = nil
  let photoPicker = PhotoPicker()

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
    tableView.tableFooterView = UIView()
    tableView.dragDelegate = self
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleEntriesUpdate),
      name: .JournalEntriesUpdated,
      object: nil
    )
  }

  override func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
    return IndexPath(row: 0, section: 0)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    populateData()
  }

  // MARK: - Actions
  @IBAction private func addEntry(_ sender: Any) {
    DataService.shared.addEntry(Entry())
  }

  // MARK: - Navigation
  @IBSegueAction func entryViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> UINavigationController? {
    guard let cell = sender as? EntryTableViewCell,
      let indexPath = tableView.indexPath(for: cell),
      let navigationController = UINavigationController(coder: coder),
      let entryTableViewController = navigationController.topViewController as?
        EntryTableViewController else { return nil }
    entryTableViewController.entry = dataSource?.itemIdentifier(for: indexPath)
    self.entryTableViewController = entryTableViewController
    return navigationController
  }
}

// MARK: - Table Data Source
extension MainTableViewController {
  private func diaryDataSource() -> EntryDataSource {
    let reuseIdentifier = "EntryTableViewCell"
    return EntryDataSource(tableView: tableView) { tableView, indexPath, entry -> EntryTableViewCell? in
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? EntryTableViewCell
      cell?.entry = entry

      let contextInteraction = UIContextMenuInteraction(delegate: self)
      cell?.addInteraction(contextInteraction)

      return cell
    }
  }

  private func populateData() {
    if let entryTableViewController = entryTableViewController,
      let entry = DataService.shared.allEntries.first,
      entryTableViewController.entry == nil {
      entryTableViewController.entry = entry
    }
    reloadSnapshot(animated: false)
  }

  private func reloadSnapshot(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Entry>()
    snapshot.appendSections([0])
    snapshot.appendItems(DataService.shared.allEntries)
    dataSource?.apply(snapshot, animatingDifferences: animated)

    if let selectedEntry = entryTableViewController?.entry {
      DataService.shared.allEntries.enumerated().forEach {index, obj in
        if selectedEntry == obj {
          self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
          return
        }
      }
    }
  }

  @objc func handleEntriesUpdate() {
    reloadSnapshot(animated: false)
  }

  override var canBecomeFirstResponder: Bool {
    return false
  }

  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      guard let key = press.key else { continue }
      switch key.keyCode {
      case .keyboardUpArrow,
        .keyboardLeftArrow: goToPrevious()
      case .keyboardDownArrow,
        .keyboardRightArrow: goToNext()
      default:
        super.pressesBegan(presses, with: event)
      }
    }
  }

  private func indexOfCurrentEntry() -> Int? {
    guard let entry = entryTableViewController?.entry else { return nil }
    return DataService.shared.allEntries.firstIndex(of: entry)
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

  func goToPrevious() {
    guard let index = indexOfCurrentEntry(),
      index > 0 else { return }
    let previousIndex = index - 1
    let indexPath = IndexPath(row: previousIndex, section: 0)
    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
    performSegue(withIdentifier: "ShowEntrySegue", sender: tableView.cellForRow(at: indexPath))
  }

  func goToNext() {
    guard let index = indexOfCurrentEntry(),
      index < DataService.shared.allEntries.count - 1 else { return }
    let nextIndex = index + 1
    let indexPath = IndexPath(row: nextIndex, section: 0)
    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
    performSegue(withIdentifier: "ShowEntrySegue", sender: tableView.cellForRow(at: indexPath))
  }

  func deleteCurentEntry() {
    guard let index = indexOfCurrentEntry() else { return }
    DataService.shared.removeEntry(atIndex: index)
    var indexPath = IndexPath(
      row: index,
      section: 0)
    guard tableView.numberOfRows(inSection: 0) > 0 else {
      performSegue(withIdentifier: "ShowEntrySegue", sender: nil)
      return
    }
    if index == tableView.numberOfRows(inSection: 0) {
      indexPath = IndexPath(
        row: index - 1,
        section: 0)
    }
    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
    performSegue(withIdentifier: "ShowEntrySegue", sender: tableView.cellForRow(at: indexPath))
  }
}

// MARK: - Table View Delegate
extension MainTableViewController {
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .delete
  }

  override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
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

// MARK: UIContextMenuInteractionDelegate
extension MainTableViewController: UIContextMenuInteractionDelegate {
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    let locationInTableView = interaction.location(in: tableView)
    guard let indexPath = tableView.indexPathForRow(at: locationInTableView) else { return nil }
    let entry = DataService.shared.allEntries[indexPath.row]
    return UIContextMenuConfiguration(
      identifier: nil,
      previewProvider: nil) { suggestedActions -> UIMenu? in
        var rootChildren: [UIMenuElement] = []
        let openInNewWindowAction = self.addopenInNewWindowAction(entry: entry)
        rootChildren.append(openInNewWindowAction)
        let newEntryAction = self.addNewEntryAction()
        rootChildren.append(newEntryAction)
        let imageAction = self.addImageAction(entry: entry, indexPath: indexPath)
        rootChildren.append(imageAction)
        let favoriteAction = self.addFavouriteAction(entry: entry)
        rootChildren.append(favoriteAction)
        let shareMenu = self.addShareMenu(entry: entry, indexPath: indexPath)
        rootChildren.append(shareMenu)
        let deleteAction = self.addDeleteAction(indexPath: indexPath)
        rootChildren.append(deleteAction)
        if !suggestedActions.isEmpty {
          if let suggestedMenu = self.addSuggestedMenu(suggestedActions: suggestedActions) {
            rootChildren.append(suggestedMenu)
          }
        }
        let menu = UIMenu(title: "", image: nil, identifier: nil, options: [], children: rootChildren)
        return menu
    }
  }

  func addopenInNewWindowAction(entry: Entry) -> UIAction {
    let openInNewWindowAction = UIAction(
      title: "Open in New Window",
      image: UIImage(systemName: "uiwindow.split.2x1"),
      identifier: nil,
      discoverabilityTitle: nil,
      attributes: [],
      state: .off) { _ in
        self.createNewWindow(for: entry)
    }
    return openInNewWindowAction
  }

  func addNewEntryAction() -> UIAction {
    let newEntryAction = UIAction(
    title: "New Entry",
    image: UIImage(systemName: "square.and.pencil"),
    identifier: nil,
    discoverabilityTitle: nil,
    attributes: [],
    state: .off) { _ in
      self.createEntry()
    }
    return newEntryAction
  }

  func addImageAction(entry: Entry, indexPath: IndexPath) -> UIAction {
    let imageAction = UIAction(
      title: "Add Image",
      image: UIImage(systemName: "photo"),
      identifier: nil,
      discoverabilityTitle: nil,
      attributes: [],
      state: .off) { _ in
        self.addImage(to: entry, indexPath: indexPath)
    }
    return imageAction
  }

  func addFavouriteAction(entry: Entry) -> UIAction {
    let favoriteTitle = entry.isFavorite ? "Remove from Favorites" : "Add to Favorites"
    let favoriteImageName = entry.isFavorite ? "star.slash" : "star"
    let favoriteAction = UIAction(
      title: favoriteTitle,
      image: UIImage(systemName: favoriteImageName),
      identifier: nil,
      discoverabilityTitle: nil,
      attributes: [],
      state: .off) { _ in
        self.toggleFavorite(for: entry)
    }
    return favoriteAction
  }

  func addShareMenu(entry: Entry, indexPath: IndexPath) -> UIMenu {
    let copyAction = UIAction(
      title: "Copy",
      image: UIImage(systemName: "doc.on.doc"),
      identifier: nil,
      discoverabilityTitle: nil,
      attributes: [],
      state: .off) { _ in
        self.copy(contentsOf: entry)
    }

    let moreAction = UIAction(
      title: "More",
      image: UIImage(systemName: "ellipsis"),
      identifier: nil,
      discoverabilityTitle: nil,
      attributes: [],
      state: .off) { _ in
        self.share(entry, at: indexPath)
    }

    let shareMenu = UIMenu(
      title: "Share",
      image: UIImage(systemName: "square.and.arrow.up"),
      identifier: nil,
      options: [],
      children: [
      copyAction, moreAction
      ])
    return shareMenu
  }

  func addDeleteAction(indexPath: IndexPath) -> UIAction {
    let deleteAction = UIAction(
      title: "Delete",
      image: UIImage(systemName: "trash"),
      identifier: nil,
      discoverabilityTitle: nil,
      attributes: .destructive,
      state: .off) { _ in
        self.removeEntry(at: indexPath)
    }
    return deleteAction
  }

  func addSuggestedMenu(suggestedActions: [UIMenuElement]) -> UIMenu? {
    if !suggestedActions.isEmpty {
      let suggestedMenu = UIMenu(
        title: "Suggested",
        image: nil,
        identifier: nil,
        options: [],
        children: suggestedActions)
        return suggestedMenu
    }
    return nil
  }

  func createNewWindow(for entry: Entry) {
    UIApplication.shared.requestSceneSessionActivation(
      nil,
      userActivity: entry.openDetailUserActivity,
      options: .none,
      errorHandler: nil)
  }

  func createEntry() {
    DataService.shared.addEntry(Entry())
  }

  func addImage(to entry: Entry, indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    photoPicker.present(in: self, sourceView: cell) {image, _ in
      if let image = image {
        var newEntry = entry
        newEntry.images.append(image)
        DataService.shared.updateEntry(newEntry)
      }
    }
  }

  func toggleFavorite(for entry: Entry) {
    var newEntry = entry
    newEntry.isFavorite = !entry.isFavorite
    DataService.shared.updateEntry(newEntry)
  }

  func copy(contentsOf entry: Entry) {
    UIPasteboard.general.string = entry.log
  }

  func share(_ entry: Entry, at indexPath: IndexPath) {
    var items: [Any] = []
    if let log = entry.log {
      items.append(log)
    }
    if !entry.images.isEmpty {
      items.append(contentsOf: entry.images)
    }

    let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let popoverController = activityController.popoverPresentationController,
      let cell = tableView.cellForRow(at: indexPath) {
      popoverController.sourceView = cell
      popoverController.sourceRect = cell.bounds
      present(activityController, animated: true, completion: nil)
    }
  }

//  func share(_ entry: Entry, at indexPath: IndexPath) {
//    presentShare(text: entry.log, images: entry.images, sourceView: tableView.cellForRow(at: indexPath))
//  }

  func removeEntry(at indexPath: IndexPath) {
    DataService.shared.removeEntry(atIndex: indexPath.row)
  }
}
