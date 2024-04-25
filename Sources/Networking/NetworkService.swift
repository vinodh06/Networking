import Foundation

/// Represents HTTP methods.
public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

/// Represents HTTP headers.
public enum HTTPHeader {
    case authorization(token: String)
    case contentType(value: String)
    case custom(name: String, value: String)

    /// Constructs a tuple representing the header field name and value.
    var headerField: (name: String, value: String) {
        switch self {
        case let .authorization(token):
            return ("Authorization", "Bearer \(token)")
        case let .contentType(value):
            return ("Content-Type", value)
        case let .custom(name, value):
            return (name, value)
        }
    }
}

/// Represents network errors.
public enum NetworkError: Error {
    case clientError(String)
    case decodingError(String)
    case genericError(String)
    case invalidURL
    case invalidResponse(String)
    case redirectionError(String)
    case serverError(String)

    /// Localized description for error handling.
    public var localizedDescription: String {
        switch self {
        case .clientError(let string),
            .decodingError(let string),
            .genericError(let string),
            .invalidResponse(let string),
            .redirectionError(let string),
            .serverError(let string):
            return string
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

/// Enum representing events that can occur during the download process.
public enum DownloadEvent: Equatable {
    /// Event indicating the reception of response data.
    case response(Data)
    /// Event indicating the progress of the download (expressed as a percentage).
    case progress(Double)
}

/// A service for making network requests.
public enum NetworkService {

    /// Fetches data from a URL using the specified method, headers, and body.
    ///
    /// - Parameters:
    ///   - urlBuilder: The URL builder for constructing the request URL.
    ///   - method: The HTTP method to use for the request.
    ///   - headers: The HTTP headers to include in the request.
    ///   - body: The HTTP body of the request, if any.
    /// - Throws: `NetworkError` if an error occurs during the request.
    /// - Returns: Response data.
    public static func request(
        for urlBuilder: URLBuilder,
        method: HTTPMethod = .GET,
        headers: [HTTPHeader] = [],
        body: Data? = nil
    ) async throws -> Data {

        // Construct the request URL
        guard let url = urlBuilder.build() else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // Set headers
        for header in headers {
            let (fieldName, fieldValue) = header.headerField
            request.setValue(fieldValue, forHTTPHeaderField: fieldName)
        }

        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle the response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse("Invalid response received")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 300..<400:
            throw NetworkError.redirectionError("Redirection Error, status code: \(httpResponse.statusCode)")
        case 400..<500:
            throw NetworkError.clientError("Client Error, status code: \(httpResponse.statusCode)")
        case 500..<600:
            throw NetworkError.serverError("Server Error, status code: \(httpResponse.statusCode)")
        default:
            throw NetworkError.genericError("Generic Error, status code: \(httpResponse.statusCode)")
        }
    }

    /// Function to initiate a download process for a given URL.
    ///
    /// - Parameters:
    ///   - urlBuilder: A URLBuilder instance responsible for constructing the download URL.
    /// - Throws: An error if the URL cannot be constructed or if any other error occurs during the download process.
    /// - Returns: An `AsyncThrowingStream` that asynchronously yields download events (`DownloadEvent`).
    public static func download(
        for urlBuilder: URLBuilder
    ) throws -> AsyncThrowingStream<DownloadEvent, Error> {
        // Attempt to construct the download URL
        guard let url = urlBuilder.build() else {
            throw NetworkError.invalidURL
        }
        // Create a URLRequest with the constructed URL
        var request = URLRequest(url: url)

        // Return an AsyncThrowingStream that performs the download operation
        return AsyncThrowingStream<DownloadEvent, Error> { [request = request] continuation in
            // Asynchronously execute the download operation within a Task
            Task {
                do {
                    if #available(iOS 15.0, *) {
                        // Use the new async/await URLSession API for iOS 15 and later
                        let (bytes, response) = try await URLSession.shared.bytes(for: request)
                        var data = Data()
                        var receivedBytes: Int64 = 0
                        let totalBytes = response.expectedContentLength

                        // Iterate over each byte received asynchronously
                        for try await byte in bytes {
                            data.append(byte)
                            receivedBytes += 1

                            // Calculate download progress and yield progress event
                            if totalBytes > 0 {
                                let progress = Double(receivedBytes) / Double(totalBytes)
                                continuation.yield(.progress(progress))
                            }
                        }

                        // Yield response data event and finish the continuation
                        continuation.yield(.response(data))
                        continuation.finish()
                    } else {
                        // Fallback on earlier versions if async/await URLSession API is not available
                        continuation.finish(throwing: "Unsupported in this OS version" as? Error)
                        return
                    }
                } catch {
                    // Handle any errors that occur during the download process
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension NetworkService {
    /// Fetches and decodes data from a URL using the specified method, headers, and body.
    ///
    /// - Parameters:
    ///   - urlBuilder: The URL builder for constructing the request URL.
    ///   - method: The HTTP method to use for the request.
    ///   - headers: The HTTP headers to include in the request.
    ///   - body: The HTTP body of the request, if any.
    /// - Throws: `NetworkError` if an error occurs during the request or decoding process.
    /// - Returns: Decoded data of type `T`.
    public static func request<T: Decodable>(
        for urlBuilder: URLBuilder,
        method: HTTPMethod = .GET,
        headers: [HTTPHeader] = [],
        body: Data? = nil
    ) async throws -> T {
        let data = try await NetworkService.request(
           for: urlBuilder,
           method: method,
           headers: headers,
           body: body
       )

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error {
            throw NetworkError.decodingError("Failed to decode response data: \(error.localizedDescription)")
        }
    }
}

