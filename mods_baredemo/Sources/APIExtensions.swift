//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import ZzApache
import ApachePortableRuntime
import Apache2


// MARK: - Raw Request

// This could be used, but remember that you usually get a pointer to the
// struct, not the struct itself. Hence you would need to do this:
//
//   let method = req?.pointee.oMethod
//
extension request_rec {

  var oMethod      : String { return String(cString: method)        }
  var oURI         : String { return String(cString: uri)           }
  var oUnparsedURI : String { return String(cString: unparsed_uri)  }
  var oHandler     : String { return String(cString: handler)       }
  var oTheRequest  : String { return String(cString: the_request)   }
  var oProtocol    : String { return String(cString: self.protocol) }
  var oHostname    : String { return String(cString: hostname)      }
  var oPathInfo    : String { return String(cString: path_info)     }

  var oFilename : String? {
    guard let s = filename else { return nil };
    return String(cString: s)
  }
  var oCanonicalFilename : String? {
    guard let s = canonical_filename else { return nil };
    return String(cString: s)
  }
  var oContentEncoding : String? {
    guard let s = content_encoding else { return nil }
    return String(cString: s)
  }
  var oUser : String? {
    guard let s = user else { return nil }
    return String(cString: s)
  }
  var oApAuthType : String? {
    guard let s = ap_auth_type else { return nil }
    return String(cString: s)
  }
  var oArgs : String? {
    guard let s = args else { return nil }
    return String(cString: s)
  }
  
  var oContentType : String? {
    set {
      newValue?.withCString { cstr in
        ap_set_content_type(&self, apr_pstrdup(self.pool, cstr))
      }
    }
    get {
      guard let s = content_type else { return nil }
      return String(cString: s)
    }
  }
}

/* This breaks swiftc, again.
extension request_rec : CustomStringConvertible {
  public var description : String {
    return "<Req: \(oMethod) \(uri)>"
  }
}
*/

// MARK: - Table Wrapper

class ZzTable {
  
  let table : OpaquePointer!
  
  init(_ table: OpaquePointer!) {
    self.table = table
  }
  
  subscript(_ key : String) -> String? {
    // case-insensitive!
    // set - needs a pool
    set {
      if let v = newValue {
        apr_table_set(table, key, v)
      }
      else {
        apr_table_unset(table, key)
      }
    }
    get {
      guard let v = apr_table_get(table, key) else { return nil }
      return String(cString: v)
    }
  }
  
  var isEmpty : Bool {
    return apr_is_empty_table(table) != 0
  }
  
  func removeAll() {
    apr_table_clear(table)
  }
  
  func removeValue(forKey key: String) {
    apr_table_unset(table, key)
  }
}


// MARK: - Request

typealias RequestRecPtr = UnsafeMutablePointer<request_rec>!

extension ZzApacheRequest {
  
  /* Again, this crashes swiftc. whether class or struct. We cannot
     make this a pure Swift wrapper :-/
  var raw : UnsafeMutablePointer<request_rec>!
  init(raw: UnsafeMutablePointer<request_rec>!) { self.raw = raw }
  */
  
  var method            : String  { return raw.pointee.oMethod            }
  var uri               : String  { return raw.pointee.oURI               }
  var unparsedURI       : String  { return raw.pointee.oUnparsedURI       }
  var handler           : String  { return raw.pointee.oHandler           }
  var theRequest        : String  { return raw.pointee.oTheRequest        }
  var `protocol`        : String  { return raw.pointee.oProtocol          }
  var hostname          : String  { return raw.pointee.oHostname          }
  var filename          : String? { return raw.pointee.oFilename          }
  var canonicalFilename : String? { return raw.pointee.oCanonicalFilename }
  var contentEncoding   : String? { return raw.pointee.oContentEncoding   }
  var user              : String? { return raw.pointee.oUser              }
  var apAuthType        : String? { return raw.pointee.oApAuthType        }
  var pathInfo          : String  { return raw.pointee.oPathInfo          }
  var args              : String? { return raw.pointee.oArgs              }
  
  var contentType : String? {
    set { raw.pointee.oContentType = newValue }
    get { return raw.pointee.oContentType }
  }
  
  var headersIn     : ZzTable { return ZzTable(raw.pointee.headers_in)      }
  var headersOut    : ZzTable { return ZzTable(raw.pointee.headers_out)     }
  var errHeadersOut : ZzTable { return ZzTable(raw.pointee.err_headers_out) }
  var trailersIn    : ZzTable { return ZzTable(raw.pointee.trailers_in)     }
  var trailersOut   : ZzTable { return ZzTable(raw.pointee.trailers_out)    }
  var subprocessEnv : ZzTable { return ZzTable(raw.pointee.subprocess_env)  }
  var notes         : ZzTable { return ZzTable(raw.pointee.notes)           }
  var bodyTable     : ZzTable { return ZzTable(raw.pointee.body_table)      }
  
  var status        : apr_status_t       { return raw.pointee.status       }
  var requestTime   : Apache2.apr_time_t { return raw.pointee.request_time }
  var finfo         : apr_finfo_t        { return raw.pointee.finfo        }
  
  var pool          : OpaquePointer!     { return raw.pointee.pool         }

  /* TODO:
   struct ap_conf_vector_t *per_dir_config;
   struct ap_conf_vector_t *request_config;
   */
  
  var description : String {
    return "<Req: \(method) \(uri)>"
  }
}

extension ZzApacheRequest { // Output
  
  func puts(_ s: String) {
    ap_rputs(s, raw)
  }
  
}

extension ZzApacheRequest { // Misc wrappers for http_core
  
  var allowOptions        : Int32      { return ap_allow_options  (raw)    }
  var allowOverrides      : Int32      { return ap_allow_overrides(raw)    }
  var serverPort          : apr_port_t { return ap_get_server_port(raw)    }
  var requestBodyLimit    : apr_off_t  { return ap_get_limit_req_body(raw) }
  var xmlRequestBodyLimit : apr_size_t { return ap_get_limit_xml_body(raw) }
  
  var isRecursionLimitExceeded : Bool {
    return ap_is_recursion_limit_exceeded(raw) != 0
  }
  
  // docs say: don't use this ;-> (cause Userdir)
  var documentRoot    : String { return String(cString: ap_document_root(raw)) }
 
  var remoteLoginName : String? {
    guard let s = ap_get_remote_logname(raw) else { return nil }
    return String(cString: s)
  }
  
  var serverName : String { return String(cString: ap_get_server_name(raw)) }
  
  var serverNameForURL : String {
    return String(cString: ap_get_server_name_for_url(raw))
  }
  
  func doesConfigDefineExist(_ name: String) -> Bool {
    return ap_exists_config_define(name) != 0
  }
}

extension ZzApacheRequest { // Auth wrappers for http_core
  
  var authType : String? {
    guard let s = ap_auth_type(raw) else { return nil }
    return String(cString: s)
  }

  var authName : String? { // the realm
    guard let s = ap_auth_name(raw) else { return nil }
    return String(cString: s)
  }
  
  var satisfies : Int32 { // SATISFY_ANY, SATISFY_ALL, SATISFY_NOSPEC
    return ap_satisfies(raw)
  }
}

extension ZzApacheRequest { // Logging
  
  func log(file:    String = #file,
           line:    Int    = #line,
           level:   Int32  = APLOG_WARNING,
           status:  apr_status_t? = nil,
           _ s: String)
  {
    let lStatus = status ?? self.status
    
    apz_log_rerror_(file, Int32(line), -1 /*TBD*/, level, lStatus, raw, s)
  }
}


// MARK: - Module

extension module {

  init(name: String) {
    self.init()
    
    // Replica of STANDARD20_MODULE_STUFF (could also live as a C support fn)
    version       = ZzApache.MODULE_MAGIC_NUMBER_MAJOR
    minor_version = Apache2.MODULE_MAGIC_NUMBER_MINOR
    module_index  = -1
    self.name     = UnsafePointer(strdup(name)) // leak
    dynamic_load_handle = nil
    next          = nil
    magic         = MODULE_MAGIC_COOKIE
    rewrite_args  = nil
  }
  
}


// MARK: - Config Helpers

protocol ApacheModuleConfig : class {

  func merge(with new: Self) -> Self?
  
}

extension ApacheModuleConfig {

  static func merge(base: Self?, new: Self?) -> Self? {
    // print("merge dir cfg: \(base) \(new)")
    if base == nil { return new  }
    if new  == nil { return base }
    return base!.merge(with: new!)
  }
  
  static func merge(_ pool: OpaquePointer?,
                    _ base: UnsafeMutableRawPointer?,
                    _ new:  UnsafeMutableRawPointer?)
              -> UnsafeMutableRawPointer?
  {
    let baseCfg = Self.fromOpaque(base)
    let newCfg  = Self.fromOpaque(new)
    let merged  = Self.merge(base: baseCfg, new: newCfg)
    // TODO: dealloc in pool
    return merged?.passRetained()
  }
  
  static func fromOpaque(_ ptr : UnsafeMutableRawPointer?) -> Self? {
    guard let ptr = ptr else { return nil }
    return Unmanaged<Self>.fromOpaque(ptr).takeUnretainedValue()
  }
  
  func passRetained() -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(self).toOpaque()
  }
  
}

final class ApacheDictionaryConfig
            : ApacheModuleConfig, CustomStringConvertible
{
  
  var values = [ String : String ]()
  
  func merge(with new: ApacheDictionaryConfig) -> ApacheDictionaryConfig? {
    let merged = ApacheDictionaryConfig()
    merged.values = values
    for (k, v) in new.values {
      merged.values.updateValue(v, forKey: k)
    }
    // print("merge \(self) + \(new) dir cfg: \(merged)")
    return merged
  }
  
  subscript(_ key : String) -> String? {
    get { return values[key] }
    set { values[key] = newValue }
  }
  
  
  // MARK: - Logging
  
  var description : String {
    return "<ApacheConfig: \(values)>"
  }


  // MARK: - Callbacks
  
  static func create(_ pool: OpaquePointer?,
                     _ dirname: UnsafeMutablePointer<Int8>?)
              -> UnsafeMutableRawPointer?
  {
    //let path = dirname != nil ? String(cString: dirname!) : nil
    
    let cfg = ApacheDictionaryConfig()
    // print("create dir cfg, path: \(path ?? "-")")
    
    // TODO: dealloc in pool
    
    return cfg.passRetained()
  }
}


// MARK: - Optional Functions

// DBD test
// Apache optional functions have the prefix `apr_OFN_`, e.g.
// `apr_OFN_ap_dbd_acquire_t`.
// Note: func types with UnsafeMutablePointer<request_rec>? coredump swiftc,
//       e.g.: apr_OFN_ap_dbd_acquire_t

// our funcs need to declare the type, there is no automagic macro way ...
func APR_RETRIEVE_OPTIONAL_FN<T>(_ name: String) -> T? {
  guard let fn = apr_dynamic_fn_retrieve(name) else { return nil }
  return unsafeBitCast(fn, to: T.self) // TBD: is there a better way?
}


// MARK: - Semantic UI

let semanticUI =
  "<script" +
  "  src='https://code.jquery.com/jquery-3.1.1.min.js'" +
  "  integrity='sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8='" +
  "  crossorigin='anonymous'></script>" +
  "<link rel='stylesheet'" +
  "  href='https://cdn.jsdelivr.net/semantic-ui/2.2.7/semantic.min.css' />" +
  "<script" +
  "  src='https://cdn.jsdelivr.net/semantic-ui/2.2.7/semantic.min.js'></script>"
