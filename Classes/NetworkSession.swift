//
//  NetworkSession.swift
//
//  Created by kernel on 1/10/18.
//  Copyright © 2018 ReImpl. All rights reserved.
//

import Foundation

public final class NetworkSession {
	
	public required init(baseUrl url: URL) {
		baseUrl = url
	}
	
	//
	// NOTE: 
	// Default "Content-Type: application/json"
	// unless specified otherwise.
	//
	public func sendRequest<R: Request>(_ request: R, completion: @escaping (R.ResponseType?, Error?) -> Void) {
		let urlRequest = request.urlRequest(with: baseUrl)
		
		let notifyQueue = OperationQueue.current ?? OperationQueue.main
		let notifyComplete = { (res: R.ResponseType?, error: Error?) in
			notifyQueue.addOperation {
				completion(res, error)
			}
		}
		
		let task = session.dataTask(with: urlRequest) { [weak self] (data: Data?, urlResponse: URLResponse?, error: Error?) in
			autoreleasepool {
				let networkResponse = NetworkResponseData(
					data: data,
					urlResponse: urlResponse,
					error: error
				)
				self?.processResponseData(networkResponse, for: request, completion: notifyComplete)
			}
		}
		
		task.resume()
	}
	
	// MARK: Internal
	
	private struct NetworkResponseData {
		let data: Data?
		let urlResponse: URLResponse?
		let error: Error?
	}
	
	private func processResponseData<R: Request>(_ responseData: NetworkResponseData, for req: R, completion: @escaping (R.ResponseType?, Error?) -> Void) {
		let data = responseData.data
		let error = responseData.error
		
		guard error == nil else {
			print("ERR. Network request failed with error: \(error!)")
			
			completion(nil, error)
			return
		}

		//
		// WARN: - 
		// only Content-Type: application/json should be parsed with JSONDecoder
		//
		
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		decoder.dateDecodingStrategy = .millisecondsSince1970
		
		// String(data: data, encoding: .utf8)
		guard let responseData = data,
			let response = try? decoder.decode(R.ResponseType.self, from: responseData) else {
				//					print(String(data: data!, encoding: .utf8)!)
				//					print("Decoding into: \(R.ResponseType.self)")
				//					let _ = try! decoder.decode(R.ResponseType.self, from: data!)
				completion(nil, error)
				
				return
		}
		
		completion(response, nil)
	}
	
	private lazy var session: URLSession = {
		let cfg = URLSessionConfiguration.ephemeral
		
		cfg.timeoutIntervalForRequest = 30
		cfg.timeoutIntervalForResource = 120
		
		return URLSession(configuration: cfg, delegate: nil, delegateQueue: OperationQueue())
	}()
	
	private let baseUrl: URL
	
}

// MARK: - Request (Public)

public enum HTTPMethod {
	case get([URLQueryItem]?)
	case post(Data?)
	case put(Data?)
}

public protocol Request {
	
	associatedtype ResponseType: Response
	
	var method: HTTPMethod { get }
	var endpoint: String { get }
	
	typealias HeadersDict = [String: String]
	var headers: Request.HeadersDict? { get }
	
}

public protocol Response: Decodable { }

// MARK: - Internal

extension Request {
	
	func urlRequest(with baseUrl: URL) -> URLRequest {
		let url = completeUrl(with: baseUrl)
		let (name, body) = methodNameAndBody(from: method)
		
		var req = URLRequest(url: url)
		
		req.httpMethod = name
		req.httpBody = body
		
		if let headers = headers {
			for (key, val) in headers {
				req.setValue(val, forHTTPHeaderField: key)
			}
		}
		
		if let contentType = req.value(forHTTPHeaderField: "Content-Type") {
			print("Using request's value: Content-Type: \(contentType)")
		} else {
			print("Defaulting request to Content-Type: application/json")
			
			req.setValue("application/json", forHTTPHeaderField: "Content-Type")
		}
		
		return req
	}
	
	func completeUrl(with baseUrl: URL) -> URL {
		var comps = URLComponents(string: endpoint)!
		
		if case .get(let queryItems) = method {
			comps.queryItems = queryItems
		}
		
		return comps.url(relativeTo: baseUrl)!
	}
	
	func methodNameAndBody(from method: HTTPMethod) -> (String, Data?) {
		let name: String
		let body: Data?
		
		switch method {
		case .get:
			name = "GET"
			body = nil
		case .post(let data):
			name = "POST"
			body = data
		case .put(let data):
			name = "PUT"
			body = data
		}
		
		return (name, body)
	}
	
}

