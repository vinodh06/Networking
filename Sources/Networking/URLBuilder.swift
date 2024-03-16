//
//  URLBuilder.swift
//
//  Created by Vinodh Kumar on 24/03/15.
//

import Foundation

/// A result builder for building URL components.
@resultBuilder
public struct URLBuilderResultBuilder {

    /// Constructs a block of URL components.
    ///
    /// - Parameter components: The components to include in the block.
    /// - Returns: An array of URL components.
    public static func buildBlock(_ components: URLComponent...) -> [URLComponent] {
        return components.compactMap { $0 }
    }
}

/// Represents a component of a URL.
public enum URLComponent {
    case scheme(String)
    case host(String)
    case path(String)
    case queryItem(String, String)
}

/// A builder class for constructing URLs.
public class URLBuilder {
    private var urlComponents = URLComponents()
    public var components: [URLComponent] = []

    /// Initializes a new URLBuilder instance with the specified components.
    ///
    /// - Parameter builder: A closure that constructs an array of URL components.
    public init(@URLBuilderResultBuilder _ builder: () -> [URLComponent]) {
        self.components = builder()
    }

    /// Appends a scheme component to the URL.
    ///
    /// - Parameter scheme: The scheme to append.
    /// - Returns: The URLBuilder instance for method chaining.
    @discardableResult
    public func scheme(_ scheme: String) -> Self {
        components.append(.scheme(scheme))
        return self
    }

    /// Appends a host component to the URL.
    ///
    /// - Parameter host: The host to append.
    /// - Returns: The URLBuilder instance for method chaining.
    @discardableResult
    public func host(_ host: String) -> Self {
        components.append(.host(host))
        return self
    }

    /// Appends a path component to the URL.
    ///
    /// - Parameter path: The path to append.
    /// - Returns: The URLBuilder instance for method chaining.
    @discardableResult
    public func path(_ path: String) -> Self {
        components.append(.path(path))
        return self
    }

    /// Appends a query item component to the URL.
    ///
    /// - Parameters:
    ///   - name: The name of the query item.
    ///   - value: The value of the query item.
    /// - Returns: The URLBuilder instance for method chaining.
    @discardableResult
    public func queryItem(_ name: String, _ value: String) -> Self {
        components.append(.queryItem(name, value))
        return self
    }

    /// Constructs a URL from the accumulated components.
    ///
    /// - Returns: The constructed URL, or nil if construction fails.
    public func build() -> URL? {
        for component in components {
            switch component {
            case .scheme(let scheme):
                urlComponents.scheme = scheme
            case .host(let host):
                urlComponents.host = host
            case .path(let path):
                if urlComponents.path.isEmpty {
                    urlComponents.path = "/" + path
                } else {
                    urlComponents.path += "/" + path
                }
            case .queryItem(let name, let value):
                var queryItems = urlComponents.queryItems ?? []
                queryItems.append(URLQueryItem(name: name, value: value))
                urlComponents.queryItems = queryItems
            }
        }

        return urlComponents.url
    }
}


