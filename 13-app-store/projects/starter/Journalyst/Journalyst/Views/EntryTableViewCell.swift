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

class EntryTableViewCell: UITableViewCell {
  @IBOutlet private var dateLabel: UILabel!
  @IBOutlet private var summaryLabel: UILabel!
  @IBOutlet private var timeLabel: UILabel!
  @IBOutlet private var imagesImageView: UIImageView!
  
  static var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("MMM dd yyyy")
    return formatter
  }()
  
  static var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
  }()
  
  var entry: Entry? {
    didSet {
      guard let entry = entry else { return }
      dateLabel.text = EntryTableViewCell.dateFormatter.string(from: entry.dateCreated)
      summaryLabel.text = entry.log
      summaryLabel.isHidden = entry.log == nil
      timeLabel.text = EntryTableViewCell.timeFormatter.string(from: entry.dateCreated)
      imagesImageView?.isHidden = entry.images.isEmpty
      accessoryView = entry.isFavorite ? UIImageView(image: UIImage(systemName: "star.fill")) : nil
      #if targetEnvironment(macCatalyst)
      summaryLabel.isHidden = true
      #endif
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    #if targetEnvironment(macCatalyst)
    setupForMac()
    #endif
  }
  
  private func setupForMac() {
    dateLabel.textColor = .label
    dateLabel.highlightedTextColor = .white
    timeLabel.textColor = .secondaryLabel
    timeLabel.highlightedTextColor = .white
    addHoverGesture()
  }
  
  private func addHoverGesture() {
    let hoverGesture
      = UIHoverGestureRecognizer(target: self,
                                 action: #selector(hovering(_:)))
    contentView.addGestureRecognizer(hoverGesture)
  }
  
  @objc private func hovering(_ recognizer: UIHoverGestureRecognizer) {
    guard !isSelected else {
      backgroundColor = nil
      return
    }
    switch recognizer.state {
    case .began, .changed:
      backgroundColor = .systemGray
    default:
      backgroundColor = nil
    }
  }
}
