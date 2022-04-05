/// Copyright (c) 2022 Razeware LLC
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

extension Notification.Name {
  static var WindowSizeChanged = Notification.Name("com.yourcompany.Journalyst.WindowSizeChanged")
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let scene = scene as? UIWindowScene {
      scene.sizeRestrictions?.minimumSize = CGSize(width: 768.0, height: 768.0)
      scene.sizeRestrictions?.maximumSize
        = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }
    if let userActivity = connectionOptions.userActivities.first {
      if !configure(window: window, with: userActivity) {
        print("Failed to restore from \(userActivity)")
      }
    }
  }

  func windowScene(
    _ windowScene: UIWindowScene,
    didUpdate previousCoordinateSpace: UICoordinateSpace,
    interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
    traitCollection previousTraitCollection: UITraitCollection
  ) {
    NotificationCenter.default.post(name: .WindowSizeChanged, object: nil)
  }

  func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
    guard activity.activityType == Entry.OpenDetailActivityType,
      let entryID = activity.userInfo?[Entry.OpenDetailIdKey] as? String,
      let entry = DataService.shared.entry(forID: entryID),
      let entryDetailViewController = EntryTableViewController.loadFromStoryboard(),
      let splitViewController = window?.rootViewController as? UISplitViewController else {
        return false
    }

    entryDetailViewController.entry = entry
    splitViewController.showDetailViewController(entryDetailViewController, sender: self)
    return true
  }
}
