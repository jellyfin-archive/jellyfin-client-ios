//
//  NetworkRequester.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import Foundation

struct NetworkRequestHeaderValue: Hashable {
    let header: String
    var value: String

    static let acceptEncoding = NetworkRequestHeaderValue(header: "Accept-Encoding", value: "gzip, deflate")
    static let acceptLanguage = NetworkRequestHeaderValue(header: "Accept-Language", value: "en-us")
    static let accept = NetworkRequestHeaderValue(header: "Accept", value: "*/*")
    static let contentType = NetworkRequestHeaderValue(header: "Content-Type", value: "application/json")
    static let authorization = NetworkRequestHeaderValue(header: "Authorization", value: "")
}

typealias NetworkRequesterHeader = Set<NetworkRequestHeaderValue>

enum NetworkRequesterResponse<T> {
    case success(T)
    case failed(Error)
}

enum NetworkRequesterError: Int, Error {
    case unknown
    case success = 200
    case badRequest = 400
    case unautherized = 401
    case notFound = 404
}

struct NetworkingError: LocalizedError {
    let code: Int
    let reason: String

    /// A localized message describing what error occurred.
    var errorDescription: String? { return reason }

    /// A localized message describing the reason for the failure.
    var failureReason: String? { return reason }
}

/// An object making it easier to make network calls
class NetworkRequester {

    static let defaultHeader: NetworkRequesterHeader = [.accept, .acceptEncoding, .acceptLanguage, .contentType]

    var sessionConfig: URLSessionConfiguration = .default
    var sessionDelegate: URLSessionDelegate?
    var session: URLSession?
    var timeoutInterval: TimeInterval = 20
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    func post<Body: Codable, Response: Codable>(at url: URL, header: NetworkRequesterHeader = NetworkRequester.defaultHeader, body: Body?, completion: @escaping (_ response: NetworkRequesterResponse<Response>) -> Void) {

        do {
            var bodyData: Data?
            if let body = body {
                bodyData = try jsonEncoder.encode(body)
            }
            makeRequestWith(httpMethod: "POST", at: url, header: header, body: bodyData, completion: completion)
        } catch let error {
            completion( .failed(error))
        }
    }

    func get<Response: Codable>(at url: URL, header: NetworkRequesterHeader = NetworkRequester.defaultHeader, completion: @escaping (_ response: NetworkRequesterResponse<Response>) -> Void) {
        makeRequestWith(httpMethod: "GET", at: url, header: header, body: nil, completion: completion)
    }

    func delete<Response: Codable>(at url: URL, header: NetworkRequesterHeader = NetworkRequester.defaultHeader, completion: @escaping (_ response: NetworkRequesterResponse<Response>) -> Void) {
        makeRequestWith(httpMethod: "DELETE", at: url, header: header, body: nil, completion: completion)
    }

    func makeRequestWith<T: Codable>(httpMethod: String, at url: URL, header: NetworkRequesterHeader, body: Data?, completion: @escaping (_ response: NetworkRequesterResponse<T>) -> Void) {

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.httpBody = body
        request.timeoutInterval = timeoutInterval

        for headerValue in header {
            request.setValue(headerValue.value, forHTTPHeaderField: headerValue.header)
        }

        let session = URLSession(configuration: sessionConfig, delegate: sessionDelegate, delegateQueue: nil)

        print("📲 \(httpMethod) data: \(String(describing: body))\n\nto: \(url.absoluteString)")

        let task = session.dataTask(with: request) { (data, response, error) in
            self.handleCodableResponse(data: data, response: response, error: error, completion: completion)
        }

        task.resume()
    }

    private func handleCodableResponse<T: Codable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (_ response: NetworkRequesterResponse<T>) -> Void) {

        handleResponse(data: data, response: response, error: error) { (response) in
            switch response {
            case .success(let data):
                do {
                    let object = try self.jsonDecoder.decode(T.self, from: data)
                    completion(.success(object))
                } catch let decodeError {
                    completion(.failed(decodeError))
                }
            case .failed(let error):
                completion(.failed(error))
            }
        }
    }

    private func handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (_ response: NetworkRequesterResponse<Data>) -> Void) {

        print("\n\nResponse: \(String(describing: response))\n\nError: \(String(describing: error))")

        if let error = error {
            completion( .failed( error))
            return
        }

        // Checking the http status code
        if let httpResponse = response as? HTTPURLResponse {

            guard let data = data else {
                let error = NetworkRequesterError.unknown
                completion( .failed( error))
                return
            }

            switch httpResponse.statusCode {
            case 200...299:
                // Sucsess

                completion(.success(data))
            default:
                // Error
                let responseText = String(data: data, encoding: .utf8) ?? ""
                print("Network error with code: ", httpResponse.statusCode)
                print("Response: ", responseText)
                completion( .failed( NetworkingError(code: httpResponse.statusCode, reason: responseText)))
            }
        } else {
            completion( .failed( NetworkRequesterError.unknown))
        }
    }

    func getData(from url: URL, completaion: @escaping (NetworkRequesterResponse<Data>) -> Void) -> URLSessionTask {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval

        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)

        print("📲 GET image \n\nat: \(url.absoluteString)")

        let task = session.dataTask(with: request) { (data, response, error) in
            self.handleResponse(data: data, response: response, error: error, completion: completaion)
        }

        task.resume()
        return task
    }

    func downloadFile<T: Codable>(from url: URL, header: NetworkRequesterHeader, body: T?) -> URLSessionDownloadTask? {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval

        for headerValue in header {
            request.setValue(headerValue.value, forHTTPHeaderField: headerValue.header)
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch let error {
                print("Error:", error)
            }
        }

        let session = self.session ?? URLSession(configuration: sessionConfig, delegate: sessionDelegate, delegateQueue: nil)

        guard session.delegate != nil else {
            print("Session Delegate is not set when downloading: \(url.absoluteString)\n\nSET THE DELEGATE IN ORDER TO HANDLE ON SUCCESS!")
            return nil
        }

        print("📲 Downloading file from: \(url.absoluteString)")

        let task = session.downloadTask(with: request)
        task.resume()
        return task
    }
}
