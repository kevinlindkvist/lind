//
//  Dictionary+Helpers.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/3/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public func union<Key, Value>(_ dictionary1: [Key:Value], _ dictionary2: [Key:Value]) -> [Key:Value] {
    var u: [Key:Value] = [:]
    dictionary1.forEach { (key, value) in
      u[key] = value
    }
    dictionary2.forEach { (key, value) in
      u[key] = value
    }
    return u
}

func ==(lhs: [String: Int], rhs: [String: Int] ) -> Bool {
  return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}
