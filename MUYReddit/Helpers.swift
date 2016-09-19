//
//  Helpers.swift
//  MUYReddit
//
//  Created by Nicolas Ameghino on 9/6/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import Foundation

enum Either<L, R> {
    case left(L)
    case right(R)
}

public func decode<T>(_ k: String, _ d: [String : Any]) throws -> T  {
    guard let v = d[k] else {
        throw NSError(domain: "JSONToObjectMapperErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "key \(k) does not exist"])
    }
    
    guard let r = v as? T else {
        throw NSError(domain: "JSONToObjectMapperErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "could not extract \(k) as \(T.self)"])
    }
    return r
}

/// Read as "take <key> from <dictionary>"
infix operator <- : DecoderPrecedence
precedencegroup DecoderPrecedence {
    higherThan: CastingPrecedence
}

func <-<T>(lhs: String, rhs: [String : Any]) throws -> T {
    return try decode(lhs, rhs)
}

