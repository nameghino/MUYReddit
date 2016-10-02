//
//  Networking.swift
//  MUYReddit
//
//  Created by Nicolas Ameghino on 9/6/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import Foundation
import UIKit

public typealias TaskIdentifier = String

public protocol JSONInittable {
    associatedtype JSONContainer
    init(container: JSONContainer)
}

public protocol Resource : JSONInittable { }

public enum Result<R> {
    case success(R)
    case error(Error)
}

public enum NetworkError : Error {
    case generic(String)
    case wrapped(Error)
    case cocoa(NSError)
}

public protocol Networking {
    //    associatedtype ResourceType
    func request<ResourceType: Resource>(request: URLRequest, fireImmediately: Bool, callback: @escaping (Result<ResourceType>) -> Void) -> URLSessionTask
}

extension Networking {
    func request<ResourceType: Resource>(request: URLRequest, fireImmediately: Bool = true, callback: @escaping (Result<ResourceType>) -> Void) -> URLSessionTask {

        print("🔼 request: \(request)")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                let r = Result<ResourceType>.error(NetworkError.wrapped(error!))
                callback(r)
                return
            }
            guard let data = data else {
                let r = Result<ResourceType>.error(NetworkError.generic("no data received"))
                callback(r)
                return
            }
            
            do {
                let object = try JSONSerialization.jsonObject(with: data, options: [])
                guard let container = object as? ResourceType.JSONContainer else {
                    let r = Result<ResourceType>.error(NetworkError.generic("unexpected json structure"))
                    callback(r)
                    return
                }
                
                let resource = ResourceType(container: container)
                let result = Result<ResourceType>.success(resource)
                callback(result)
            } catch (let error) {
                let r = Result<ResourceType>.error(NetworkError.wrapped(error))
                callback(r)
                return
            }
        }
        
        if fireImmediately {
            task.resume()
        }
        
        return task
        
    }
}
