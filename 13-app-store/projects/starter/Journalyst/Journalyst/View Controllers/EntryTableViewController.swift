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
import AVFoundation

class EntryTableViewController: UITableViewController {
  
  // MARK: - Outlets
  @IBOutlet private var textView: UITextView!
  @IBOutlet private var collectionView: UICollectionView!
  @IBOutlet private var entryCell: UITableViewCell!
  
  // MARK: - Properties
  var dataSource: UICollectionViewDiffableDataSource<Int, UIImage>?
  
  var entry: Entry? {
    didSet {
      guard let entry = entry else { return }
      let dateFormatter = DateFormatter()
      dateFormatter.setLocalizedDateFormatFromTemplate("MMM dd yyyy, hh:mm")
      title = dateFormatter.string(from: entry.dateCreated)
    }
  }

  let photoPicker = PhotoPicker()

  static func loadFromStoryboard() -> EntryTableViewController? {
      let storyboard = UIStoryboard(name: "Main", bundle: .main)
      return storyboard.instantiateViewController(withIdentifier: "EntryDetail") as? EntryTableViewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    textView.text = entry?.log ?? ""
    let dataSource = imageDataSource()
    dataSource.supplementaryViewProvider = supplementaryDataSource()
    collectionView.dataSource = dataSource
    self.dataSource = dataSource
    reloadSnapshot(animated: false)
    validateState()
    NotificationCenter.default.addObserver(self, selector: #selector(handleEntryUpdated(notification:)), name: .JournalEntryUpdated, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleUserDefaultChanged(notification:)), name: UserDefaults.didChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWindowSizeChanged), name: .WindowSizeChanged, object: nil)
    updateEntryCellColor()

    let interaction = UIDropInteraction(delegate: self)
    textView.interactions.append(interaction)

    collectionView.dropDelegate = self
    collectionView.dragDelegate = self
  
    #if targetEnvironment(macCatalyst)
    view.backgroundColor = .secondarySystemBackground
    collectionView.showsHorizontalScrollIndicator = true
    #endif
  }
  
  override var canBecomeFirstResponder: Bool {
    return false
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated)
    entry?.log = textView.text
    if let entry = entry {
      DataService.shared.updateEntry(entry)
    }
  }
  
  // MARK: - Notifications
  @objc func handleUserDefaultChanged(notification: Notification) {
    updateEntryCellColor()
  }

  @objc func handleEntryUpdated(notification: Notification) {
    guard let userInfo = notification.userInfo, let entry = userInfo[DataNotificationKeys.entry] as? Entry else {
      return
    }
    self.entry = entry
    reloadSnapshot(animated: true)
  }

  @objc func handleWindowSizeChanged() {
    collectionView.reloadData()
  }
  
  // MARK: - Actions
  @IBAction func share(_ sender: Any?) {
    guard let textToShare = textView.text, !textToShare.isEmpty else { return }
    presentShare(text: textToShare, images: entry?.images, sourceBarItem: navigationItem.rightBarButtonItem)
  }
  
  @IBAction private func addImage(_ sender: Any?) {
    textView.resignFirstResponder()
    let actionSheet = UIAlertController(title: "Add Photo", message: "Add a photo to your entry", preferredStyle: .actionSheet)
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
        self.selectPhotoFromSource(.camera)
      }))
    }
    actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { _ in
      self.selectPhotoFromSource(.photoLibrary)
    }))
    if let view = sender as? UIView,
      let popoverController = actionSheet.popoverPresentationController {
      popoverController.sourceRect = CGRect(x: view.frame.midX, y: view.frame.midY, width: 0, height: 0)
      popoverController.sourceView = view
    }
    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
    present(actionSheet, animated: true, completion: nil)
  }
  
  private func selectPhotoFromSource(_ sourceType: UIImagePickerController.SourceType) {
    let imagePickerController = UIImagePickerController()
    imagePickerController.sourceType = sourceType
    imagePickerController.allowsEditing = false
    imagePickerController.delegate = self
    present(imagePickerController, animated: true, completion: nil)
  }
  
  private func validateState() {
    navigationItem.rightBarButtonItem?.isEnabled = !textView.text.isEmpty
  }
  
  private func updateEntryCellColor() {
    let overrideColorPreference = UserDefaults.standard.bool(forKey: "entry_color_preference")
    let overrideColor = UIColor.white
    if overrideColorPreference {
      entryCell.contentView.backgroundColor = overrideColor
      textView.textColor = UIColor.black
    } else {
      entryCell.contentView.backgroundColor = nil
      textView.textColor = UIColor.label
    }
  }
  
}

// MARK: - Table Data Source
extension EntryTableViewController {
  private func imageDataSource() -> UICollectionViewDiffableDataSource<Int, UIImage> {
    let reuseIdentifier = "ImageCollectionViewCell"
    return UICollectionViewDiffableDataSource(collectionView: collectionView) { (collectionView, indexPath, image) -> ImageCollectionViewCell? in
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ImageCollectionViewCell
      cell?.image = image
      return cell
    }
  }
  
  private func supplementaryDataSource() -> UICollectionViewDiffableDataSource<Int, Int>.SupplementaryViewProvider {
    let provider: UICollectionViewDiffableDataSource<Int, Int>.SupplementaryViewProvider = { (collectionView, kind, indexPath) -> UICollectionReusableView? in
      let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
      reusableView.layer.borderColor = UIColor(named: "PrimaryTint")!.cgColor
      reusableView.layer.borderWidth = 1.0 / UIScreen.main.scale
      let hoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(self.hovering(_:)))
      reusableView.addGestureRecognizer(hoverGesture)
      return reusableView
    }
    return provider
  }
  
  @objc private func hovering(_ recognizer: UIHoverGestureRecognizer) {
    guard let view = recognizer.view else { return }
    switch recognizer.state {
    case .began, .changed:
      view.backgroundColor = UIColor(named: "PrimaryTint")
      view.tintColor = .white
    case .ended:
      view.backgroundColor = nil
      view.tintColor = UIColor(named: "PrimaryTint")
    default:
      break
    }
  }
  
  private func reloadSnapshot(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, UIImage>()
    snapshot.appendSections([0])
    snapshot.appendItems(entry?.images ?? [])
    dataSource?.apply(snapshot, animatingDifferences: animated)
  }
}

// MARK: - Image Picker Delegate
extension EntryTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let image = info[.originalImage] as? UIImage else { return }
    entry?.images.append(image)
    dismiss(animated: true) {
      self.reloadSnapshot(animated: true)
    }
  }
}

// MARK: - Text View Delegate
extension EntryTableViewController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    validateState()
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    entry?.log = textView.text
  }
}

// MARK: - UIDropInteractionDelegate
extension EntryTableViewController: UIDropInteractionDelegate {

  func dropInteraction(
    _ interaction: UIDropInteraction,
    canHandle session: UIDropSession) -> Bool {

    session.canLoadObjects(ofClass: UIImage.self)
  }

  func dropInteraction(
    _ interaction: UIDropInteraction,
    sessionDidUpdate session: UIDropSession) -> UIDropProposal {

    UIDropProposal(operation: .copy)
  }

  func dropInteraction(
    _ interaction: UIDropInteraction,
    performDrop session: UIDropSession) {

    session.loadObjects(ofClass: UIImage.self) {
      [weak self] imageItems in

      guard let self = self else { return }
      let images = imageItems as! [UIImage]
      self.entry?.images.append(contentsOf: images)
      self.reloadSnapshot(animated: true)
    }
  }

}

// MARK: - UICollectionViewDropDelegate
extension EntryTableViewController: UICollectionViewDropDelegate {

  func collectionView(
    _ collectionView: UICollectionView,
    canHandle session: UIDropSession) -> Bool {

    session.canLoadObjects(ofClass: UIImage.self)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    dropSessionDidUpdate session: UIDropSession,
    withDestinationIndexPath destinationIndexPath: IndexPath?)
    -> UICollectionViewDropProposal {

      if session.localDragSession != nil {
        return UICollectionViewDropProposal(
          operation: .move,
          intent: .insertAtDestinationIndexPath)
      } else {
        return UICollectionViewDropProposal(
          operation: .copy,
          intent: .insertAtDestinationIndexPath)
      }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    performDropWith coordinator:
    UICollectionViewDropCoordinator) {

    let destinationIndex = coordinator.destinationIndexPath?.item ?? 0

    for item in coordinator.items {
      if coordinator.session.localDragSession != nil,
        let sourceIndex = item.sourceIndexPath?.item {

        self.entry?.images.remove(at: sourceIndex)
      }

      item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) {
        (object, error) in
        guard let image = object as? UIImage, error == nil else {
          print(error ?? "Error: object is not UIImage")
          return
        }
        DispatchQueue.main.async {
          self.entry?.images.insert(image, at: destinationIndex)
          self.reloadSnapshot(animated: true)
        }
      }
    }

  }

}

// MARK: - UICollectionViewDragDelegate
extension EntryTableViewController: UICollectionViewDragDelegate {

  func collectionView(
    _ collectionView: UICollectionView,
    itemsForBeginning session: UIDragSession,
    at indexPath: IndexPath) -> [UIDragItem] {

    guard let entry = entry, !entry.images.isEmpty else {
      return []
    }

    let image = entry.images[indexPath.item]
    let provider = NSItemProvider(object: image)
    return [UIDragItem(itemProvider: provider)]
  }
}
