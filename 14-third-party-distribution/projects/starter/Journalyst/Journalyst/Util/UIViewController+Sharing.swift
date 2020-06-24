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

extension UIViewController {

  func presentShare(text: String?, images: [UIImage]?, sourceView: UIView? = nil, sourceBarItem: UIBarButtonItem? = nil) {
    var items: [Any] = []
    var textToShare = text ?? ""

    if let namePreference = UserDefaults.standard.string(forKey: "name_preference"),
      UserDefaults.standard.bool(forKey: "signature_preference") {
      textToShare += "\n\n -\(namePreference)"
    }

    if let images = images, !images.isEmpty {
      items.append(contentsOf: images)
    }

    let activityController = UIActivityViewController(activityItems: items,
                                                      applicationActivities: nil)
    if let sourceView = sourceView {
      activityController.popoverPresentationController?.sourceView = sourceView
    } else if let sourceBarItem = sourceBarItem {
      activityController.popoverPresentationController?.barButtonItem = sourceBarItem
    }

    present(activityController, animated: true, completion: nil)
  }

}
