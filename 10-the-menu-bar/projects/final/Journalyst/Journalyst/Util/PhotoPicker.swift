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

class PhotoPicker: NSObject {

  typealias PhotoCompletion = (UIImage?, Error?) -> Void
  fileprivate var completion: PhotoCompletion?
  lazy var picker: UIImagePickerController = {
    let picker = UIImagePickerController()
    picker.allowsEditing = false
    picker.delegate = self
    return picker
  }()

  func present(in viewController: UIViewController,
               title: String?  = NSLocalizedString("Add Photo", comment: ""),
               message: String?  = nil,
               sourceView: UIView?  = nil,
               completion: @escaping PhotoCompletion) {
    self.completion = completion

    let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      alert.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { _ in
        self.presentCamera(in: viewController)
      }))
    }
    alert.addAction(UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""), style: .default, handler: { _ in
      self.presentPhotoLibrary(in: viewController)
    }))
    alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))

    if let view = sourceView,
      let popoverController = alert.popoverPresentationController {
      popoverController.sourceRect = CGRect(x: view.frame.midX, y: view.frame.midY, width: 0, height: 0)
      popoverController.sourceView = view
    }
    viewController.present(alert, animated: true, completion: nil)
  }

}

fileprivate extension PhotoPicker {

  func presentCamera(in viewController: UIViewController) {
    picker.sourceType = .camera
    viewController.present(picker, animated: true, completion: nil)
  }

  func presentPhotoLibrary(in viewController: UIViewController) {
    picker.sourceType = .photoLibrary
    viewController.present(picker, animated: true, completion: nil)
  }

}

extension PhotoPicker: UIImagePickerControllerDelegate {

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    if let image = info[.editedImage] as? UIImage {
      self.completion?(image, nil)
    }
    picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }

}

extension PhotoPicker: UINavigationControllerDelegate {
}
