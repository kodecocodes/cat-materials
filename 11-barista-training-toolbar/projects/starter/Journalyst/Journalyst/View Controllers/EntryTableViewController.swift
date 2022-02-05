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

class EntryTableViewController: UITableViewController {
  let colorPreference = "entry_color_preference"
  let namePreference = "name_preference"
  let signaturePreference = "signature_preference"

  // MARK: - Outlets
  @IBOutlet private weak var textView: UITextView!
  @IBOutlet private weak var collectionView: UICollectionView!
  @IBOutlet private var entryCell: UITableViewCell!
  // MARK: - Properties
  var dataSource: UICollectionViewDiffableDataSource<Int, UIImage>?

  private var shareText: String? {
    guard var textToShare = textView.text, !textToShare.isEmpty else { return nil }
    if let namePreference = UserDefaults.standard.string(forKey: namePreference),
      UserDefaults.standard.bool(forKey: signaturePreference) {
      textToShare += "\n\n -\(namePreference)"
    }
    return textToShare
  }

  var entry: Entry? {
    didSet {
      guard let entry = entry else { return }
      let dateFormatter = DateFormatter()
      dateFormatter.setLocalizedDateFormatFromTemplate("MMM dd yyyy, hh:mm")
      title = dateFormatter.string(from: entry.dateCreated)
    }
  }

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
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleEntryUpdated(notification:)),
      name: .JournalEntryUpdated,
      object: nil)
    UserDefaults.standard
      .addObserver(self,
      forKeyPath: colorPreference,
      options: .new,
      context: nil)
    updateEntryCellColor()

    collectionView.dropDelegate = self
    collectionView.dragDelegate = self

    #if targetEnvironment(macCatalyst)
    view.backgroundColor = .secondarySystemBackground
    collectionView.showsHorizontalScrollIndicator = true
    #endif
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    guard let text = textView?.text, var entry = entry else { return }
    entry.log = text
    DataService.shared.updateEntry(entry)
  }

  // MARK: - Notifications
  // swiftlint:disable:next block_based_kvo
  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    if keyPath == colorPreference {
      updateEntryCellColor()
    }
  }

  @objc func handleEntryUpdated(notification: Notification) {
    guard let userInfo = notification.userInfo, let entry = userInfo[DataNotificationKeys.entry] as? Entry else {
      return
    }
    self.entry = entry
    reloadSnapshot(animated: true)
  }

  // MARK: - Actions
  @IBAction func share(_ sender: Any?) {
    guard let shareText = shareText else { return }
    let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
    if let popoverController = activityController.popoverPresentationController {
      if let navigationButton = sender as? UIBarButtonItem {
        popoverController.barButtonItem = navigationButton
      }
    }
    present(activityController, animated: true, completion: nil)
  }

  @IBAction private func addImage(_ sender: Any?) {
    textView.resignFirstResponder()
    let actionSheet = UIAlertController(
      title: "Add Photo",
      message: "Add a photo to your entry",
      preferredStyle: .actionSheet)
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
        self.selectPhotoFromSource(.camera)
      })
    }
    actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default) { _ in
      self.selectPhotoFromSource(.photoLibrary)
    })
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
    let overrideColorPreference = UserDefaults.standard.bool(forKey: colorPreference)
    if overrideColorPreference {
      entryCell.contentView.backgroundColor = .systemFill
    } else {
      entryCell.contentView.backgroundColor = nil
    }
  }

  @objc private func hovering(_ recognizer: UIHoverGestureRecognizer) {
    #if targetEnvironment(macCatalyst)
    switch recognizer.state {
    case .began, .changed:
      NSCursor.pointingHand.set()
    case .ended:
      NSCursor.arrow.set()
    default:
      break
    }
    #endif
  }
}

// MARK: - Table Data Source
extension EntryTableViewController {
  private func imageDataSource() -> UICollectionViewDiffableDataSource<Int, UIImage> {
    let reuseIdentifier = "ImageCollectionViewCell"
    return UICollectionViewDiffableDataSource(
      collectionView: collectionView) { collectionView, indexPath, image -> ImageCollectionViewCell? in
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: reuseIdentifier, for: indexPath) as? ImageCollectionViewCell
      cell?.image = image
      return cell
    }
  }

  private func supplementaryDataSource() -> UICollectionViewDiffableDataSource<Int, Int>.SupplementaryViewProvider {
    let provider: UICollectionViewDiffableDataSource<Int, Int>.SupplementaryViewProvider
      = { collectionView, kind, indexPath -> UICollectionReusableView? in
      let reusableView = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
      reusableView.layer.borderColor = UIColor(named: "PrimaryTint")?.cgColor
      reusableView.layer.borderWidth = 1.0 / UIScreen.main.scale

      let hoverGesture = UIHoverGestureRecognizer(
        target: self,
        action: #selector(self.hovering(_:)))

      reusableView.addGestureRecognizer(hoverGesture)
      if let button = reusableView.viewWithTag(1) as? UIButton {
        button.pointerStyleProvider = { button, effect, shape -> UIPointerStyle? in
          var rect = button.bounds
          rect = button.convert(rect, to: effect.preview.target.container)
          return UIPointerStyle(effect: effect, shape: .roundedRect(rect))
        }
      }

      return reusableView
    }
    return provider
  }

  private func reloadSnapshot(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, UIImage>()
    snapshot.appendSections([0])
    snapshot.appendItems(entry?.images ?? [])
    dataSource?.apply(snapshot, animatingDifferences: animated)
  }
}

// MARK: - Image Picker Delegate
extension EntryTableViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    guard let image = info[.originalImage] as? UIImage else { return }
    entry?.images.append(image)
    dismiss(animated: true) {
      self.reloadSnapshot(animated: true)
    }
  }
}

extension EntryTableViewController: UINavigationControllerDelegate {
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
    canHandle session: UIDropSession
  ) -> Bool {
    session.canLoadObjects(ofClass: UIImage.self)
  }

  func dropInteraction(
    _ interaction: UIDropInteraction,
    sessionDidUpdate session: UIDropSession
  ) -> UIDropProposal {
    UIDropProposal(operation: .copy)
  }

  func dropInteraction(
    _ interaction: UIDropInteraction,
    performDrop session: UIDropSession
  ) {
    session.loadObjects(ofClass: UIImage.self) {[weak self] imageItems in
      guard let self = self else { return }
      if let images = imageItems as? [UIImage] {
        self.entry?.images.append(contentsOf: images)
        self.reloadSnapshot(animated: true)
      }
    }
  }
}

// MARK: - UICollectionViewDropDelegate
extension EntryTableViewController: UICollectionViewDropDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    canHandle session: UIDropSession
  ) -> Bool {
    session.canLoadObjects(ofClass: UIImage.self)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    dropSessionDidUpdate session: UIDropSession,
    withDestinationIndexPath destinationIndexPath: IndexPath?
  )
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
    performDropWith coordinator: UICollectionViewDropCoordinator
  ) {
    let destinationIndex = coordinator.destinationIndexPath?.item ?? 0

    for item in coordinator.items {
      if coordinator.session.localDragSession != nil,
        let sourceIndex = item.sourceIndexPath?.item {
        self.entry?.images.remove(at: sourceIndex)
      }

      item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) {object, error in
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
    at indexPath: IndexPath
  ) -> [UIDragItem] {
    guard let entry = entry, !entry.images.isEmpty else {
      return []
    }

    let image = entry.images[indexPath.item]
    let provider = NSItemProvider(object: image)
    return [UIDragItem(itemProvider: provider)]
  }
}

extension EntryTableViewController: UIGestureRecognizerDelegate {
}
