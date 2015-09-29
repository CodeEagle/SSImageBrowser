//: Playground - noun: a place where people can play

import UIKit
import XCPlayground
var str = "Hello, playground"

var a:Set<UIView> = Set<UIView>()
var b:Set<UIView> = Set<UIView>()
let view = UIView()
view.tag = 1
a.insert(view)
b.insert(view)
let v2 = UIView()
v2.tag = 10
v2.addSubview(view)
b.insert(v2)

for aview in a {
    aview.removeFromSuperview()
}
let c = b.exclusiveOr(a)
c.first?.tag
v2.subviews.count
for index in 0...0 {
    print("a", append)
}
