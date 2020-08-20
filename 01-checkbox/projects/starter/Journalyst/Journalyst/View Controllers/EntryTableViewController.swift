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
import AVFoundation

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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    textView.text = entry?.log ?? ""
    let dataSource = imageDataSource()
    dataSource.supplementaryViewProvider = supplementaryDataSource()
    collectionView.dataSource = dataSource
    self.dataSource = dataSource
    reloadSnapshot(animated: false)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated)
    entry?.log = textView.text
  }
  
  // MARK: - Actions
  @IBAction private func share(_ sender: Any?) {
    guard !textView.text.isEmpty else { return }
    let activityController = UIActivityViewController(activityItems: [textView.text ?? ""], applicationActivities: nil)
    present(activityController, animated: true, completion: nil)
  }
  
  @IBAction private func addImage(_ sender: UIButton?) {
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
    UIView.setAnimationsEnabled(false)
    textView.sizeToFit()
    self.tableView.beginUpdates()
    self.tableView.endUpdates()
    UIView.setAnimationsEnabled(true)
  }
}
