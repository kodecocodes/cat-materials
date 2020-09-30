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
  // MARK: - Outlets
  @IBOutlet private var textView: UITextView!
  @IBOutlet private var collectionView: UICollectionView!

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
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleEntryUpdated(notification:)), name: .JournalEntryUpdated, object: nil)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    entry?.log = textView?.text
    if let entry = entry {
      DataService.shared.updateEntry(entry)
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
  @IBAction private func share(_ sender: Any?) {
    guard !textView.text.isEmpty else { return }
    let activityController = UIActivityViewController(activityItems: [textView.text ?? ""], applicationActivities: nil)
    if let popoverController = activityController.popoverPresentationController {
      popoverController.barButtonItem = navigationItem.rightBarButtonItem
    }
    present(activityController, animated: true, completion: nil)
  }

  @IBAction private func addImage(_ sender: Any?) {
    guard let view = sender as? UIView else { return }

    textView.resignFirstResponder()
    photoPicker.present(in: self, sourceView: view) {image, _ in
      if let image = image, var entry = self.entry {
        entry.images.append(image)
        DataService.shared.updateEntry(entry)
      }
    }
  }

  private func validateState() {
    navigationItem.rightBarButtonItem?.isEnabled = !textView.text.isEmpty
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

// MARK: - Text View Delegate
extension EntryTableViewController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    validateState()
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    entry?.log = textView.text
  }
}
