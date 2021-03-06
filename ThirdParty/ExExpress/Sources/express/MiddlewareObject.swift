//
//  MiddlewareObject.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/**
 * MiddlewareObject is the 'object variant' of a Middleware callback.
 *
 * All MiddlewareObject's provide a `handle(request:response:next:)` method.
 *
 * And you can generate a Middleware function for a MiddlewareObject by using
 * the `.middleware` property. Like so:
 *
 *     app.use(otherApp.middleware)
 *
 * Finally, you can also use the as a http-module request handler. Same thing:
 *
 *     http.createServer(onRequest: app.requestHandler)
 *
 */
public protocol MiddlewareObject {
  
  func handle(request  req: IncomingMessage,
              response res: ServerResponse,
              next     cb:  @escaping Next) throws
  
}

public protocol MountableMiddlewareObject : MiddlewareObject {
  
  func emitOnMount(parent: Express)
  
}

fileprivate let allowedDefaultMethods = [
  "GET", "HEAD", "POST", "OPTIONS", "DELETE", "PUT", "PATCH"
]

public extension MiddlewareObject {
  
  public var middleware: Middleware {
    return { req, res, next in
      try self.handle(request: req, response: res, next: next)
    }
  }

  public var requestHandler: RequestEventCB {
    return { req, res in
      let errorToThrow : Error?
      
      do {
        try self.handle(request: req, response: res) { _ in
          // essentially the final handler
          
          if req.method == "OPTIONS" {
            // This assumes option headers have been set via cors middleware or
            // sth similar.
            // Just respond with OK and we are done, right?
            
            if res.getHeader("Allow") == nil {
              res.setHeader("Allow",
                            allowedDefaultMethods.joined(separator: ", "))
            }
            if res.getHeader("Server") == nil {
              res.setHeader("Server", "ApacheExpress/1.33.7")
            }
            
            res.writeHead(200)
            try res.end()
          }
          else {
            console.warn("No middleware called end: " +
                         "\(self) \(req.method) \(req.url)")
            res.writeHead(404)
            try res.end()
          }
        }
        errorToThrow = nil
      }
      catch (let _error) {
        errorToThrow = _error
      }
      
      // finally
      if let app = self as? Express {
        // break potential retain cycles
        app.clearAttachedState(request: req, response: res)
      }
      
      if let error = errorToThrow {
        throw error
      }
    }
  }
}
