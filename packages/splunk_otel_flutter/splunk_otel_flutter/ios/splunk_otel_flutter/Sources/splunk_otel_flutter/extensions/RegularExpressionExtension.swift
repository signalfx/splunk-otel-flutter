//
/*
Copyright 2025 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import Foundation
import SplunkNetwork

extension GeneratedRegularExpression {
  func toNSRegularExpression() throws -> NSRegularExpression {
    var opts: NSRegularExpression.Options = []

    if let options = options {
      for opt in options {
        guard let opt = opt else { continue }
        switch opt {
        case .caseInsensitive:
          opts.insert(.caseInsensitive)
        case .allowCommentsAndWhitespace:
          opts.insert(.allowCommentsAndWhitespace)
        case .ignoreMetacharacters:
          opts.insert(.ignoreMetacharacters)
        case .dotMatchesLineSeparators:
          opts.insert(.dotMatchesLineSeparators)
        case .anchorsMatchLines:
          opts.insert(.anchorsMatchLines)
        case .useUnixLineSeparators:
          opts.insert(.useUnixLineSeparators)
        case .useUnicodeWordBoundaries:
          opts.insert(.useUnicodeWordBoundaries)
        @unknown default:
          break
        }
      }
    }

    return try NSRegularExpression(pattern: pattern, options: opts)
  }
}

extension Array where Element == GeneratedRegularExpression {
  func toIgnoreURLs() throws -> IgnoreURLs {
   
    let regexes = try map { try $0.toNSRegularExpression() }
    let patterns = Set(regexes.map { $0.pattern })

 
    return try IgnoreURLs(patterns: patterns)
  }
}
