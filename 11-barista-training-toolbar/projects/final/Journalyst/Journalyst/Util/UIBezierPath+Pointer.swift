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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

extension UIBezierPath {
  static var plusPath: UIBezierPath {
    let plusPath = UIBezierPath()
    let lineWidth: CGFloat = 1.5
    let size: Double = 5
    let fullPi = CGFloat.pi
    let halfPi = fullPi / 2

    let offsetX: CGFloat = 10
    let offsetY: CGFloat = 10

    plusPath.move(to: CGPoint(x: -lineWidth + offsetX, y: lineWidth + offsetY))
    plusPath.addLine(to: CGPoint(x: -lineWidth + offsetX, y: size + offsetY))

    let centerOne = CGPoint(x: offsetX, y: size + offsetY)
    plusPath
      .addArc(
        withCenter: centerOne, radius: lineWidth, startAngle: fullPi, endAngle: 0, clockwise: false
      )

    plusPath.addLine(to: CGPoint(x: lineWidth + offsetX, y: lineWidth + offsetY))
    plusPath.addLine(to: CGPoint(x: size + offsetX, y: lineWidth + offsetY))

    let centerTwo = CGPoint(x: size + offsetX, y: 0 + offsetY)
    plusPath
      .addArc(
        withCenter: centerTwo, radius: lineWidth, startAngle: halfPi, endAngle: fullPi * lineWidth, clockwise: false
      )

    plusPath.addLine(to: CGPoint(x: lineWidth + offsetX, y: -lineWidth + offsetY))
    plusPath.addLine(to: CGPoint(x: lineWidth + offsetX, y: -size + offsetY))

    let centerThree = CGPoint(x: offsetX, y: -size + offsetY)
    plusPath
      .addArc(
        withCenter: centerThree, radius: lineWidth, startAngle: 0, endAngle: fullPi, clockwise: false
      )
    plusPath.addLine(to: CGPoint(x: -lineWidth + offsetX, y: -lineWidth + offsetY))
    plusPath.addLine(to: CGPoint(x: -size + offsetX, y: -lineWidth + offsetY))

    let centerFour = CGPoint(x: -size + offsetX, y: 0 + offsetY)
    plusPath
      .addArc(
        withCenter: centerFour, radius: lineWidth, startAngle: fullPi * lineWidth, endAngle: halfPi, clockwise: false
      )

    plusPath.close()
    return plusPath
  }
}
