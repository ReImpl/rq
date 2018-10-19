//
//  NetworkSession.swift
//
//  Created by kernel on 1/10/18.
//  Copyright © 2018 ReImpl. All rights reserved.
//

import Foundation

@objc
public protocol MultipartFormParameter { }

public class MultipartFormValueParameter: NSObject, MultipartFormParameter {
	public let name: String
	public let value: String
	
	public init(name: String, value: String) {
		self.name = name
		self.value = value
	}
}

public class MultipartFormFileParameter: NSObject, MultipartFormParameter {
	public let name: String
	public let pathUrl: URL
	public let contentType: String
	
	public init(name: String, pathUrl: URL, contentType: String) {
		self.name = name
		self.pathUrl = pathUrl
		self.contentType = contentType
	}
}

// MARK: - MultipartFormDataRequest

public extension Request {
	
	// SEE: https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.2
	//
	public func multipartFormData(file: MultipartFormFileParameter?, params: [MultipartFormValueParameter]? = nil) throws -> (body: Data, headers: Request.HeadersDict) {
		var thisHeaders: Request.HeadersDict = [:]
		
		if let superClassHeaders = headers {
			thisHeaders = superClassHeaders
		}
		
		let separator = randomString(of: 16)
		
		thisHeaders["Content-Type"] = "multipart/form-data; boundary=\(separator)"
		thisHeaders["Cache-Control"] = "no-cache"
		
		var bodyHeader = "Content-Type: multipart/form-data; boundary=\(separator)\r\n\r\n"
		
		if let params = params {
			for p in params {
				bodyHeader += "--\(separator)\r\n"
				bodyHeader += "Content-Disposition: form-data; name=\"\(p.name)\"\r\n\r\n"
				
				bodyHeader += "\(p.value)\r\n"
			}
		}
		
		let fileContents: Data?
		
		if let file = file {
			bodyHeader += "--\(separator)\r\n"
			bodyHeader += "Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.pathUrl.lastPathComponent)\"\r\n"
			bodyHeader += "Content-Type: \(file.contentType)\r\n\r\n"
			
			fileContents = try Data(contentsOf: file.pathUrl)
		} else {
			fileContents = nil
		}
		
		var bodyFooter = "\r\n"
		bodyFooter += "--\(separator)--"
		
		let header = bodyHeader.data(using: .utf8)!
		let footer = bodyFooter.data(using: .utf8)!
		
		var body = Data(capacity:
			header.count + (fileContents?.count ?? 0) + footer.count)
		body.append(header)
		if let contents = fileContents {
			body.append(contents)
		}
		body.append(footer)
		
		return (body: body, headers: thisHeaders)
	}
	
}

private func randomString(of length: Int) -> String {
	let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	
	return String((0..<length).map { _ -> Character in
		return letters.randomElement()!
	})
}

