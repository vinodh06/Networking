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

/// A service for making network requests.
public enum NetworkService {

    /// Fetches data from a URL using the specified method, headers, and body.
    ///
    /// - Parameters:
    ///   - urlBuilder: The URL builder for constructing the request URL.
    ///   - method: The HTTP method to use for the request.
    ///   - headers: The HTTP headers to include in the request.
    ///   - body: The HTTP body of the request, if any.
    /// - Returns: The decoded response data.
    public static func fetch<T: Decodable>(
        for urlBuilder: URLBuilder,
        method: HTTPMethod = .GET,
        headers: [HTTPHeader] = [],
        body: Data? = nil
    ) async throws -> T {

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
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch let error {
                throw NetworkError.decodingError("Failed to decode response data: \(error.localizedDescription)")
            }
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
}

