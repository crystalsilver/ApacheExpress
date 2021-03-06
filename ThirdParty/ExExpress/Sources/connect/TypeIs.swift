//
//  TypeIs.swift
//  Noze.io
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//


// TODO: the API is both crap nor really the same like Node

public func typeIs(_ message: IncomingMessage, _ types: [ String ])
            -> String?
{
  let ctypeO = message.getHeader("Content-Type") as? String
  guard let ctype = ctypeO else { return nil }
  return typeIs(ctype, types)
}

public func typeIs(_ type: String, _ types: [ String ]) -> String? {
  let lcType = type.lowercased()
  
  for matchType in types {
    if does(type: lcType, match: matchType) {
      return matchType
    }
  }
  
  return nil
}

private func does(type lcType: String, match matchType: String) -> Bool {
  let lcMatch = matchType.lowercased()
  
  if lcType == lcMatch { return true }
  
  // FIXME: completely naive implementation :->
  
  if lcMatch.hasSuffix("*") {
    let idx = lcMatch.index(before: lcMatch.endIndex)
    let lcPatMatch = lcMatch.substring(to: idx)
    return lcType.hasPrefix(lcPatMatch)
  }
  
  if lcType.contains(lcMatch) {
    return true
  }
  
  return false
}
