# Networking Library

The `Networking` library provides utilities for handling network requests and responses in Swift applications.

## Features

- **URLBuilder**: Build URLs with ease using a fluent interface.
- **NetworkService**: Perform HTTP requests and handle responses.
- **Errors**: Define custom error types for network-related errors.
- **Dependencies**: Manage dependencies and client configurations.
- **Download Functionality**: Asynchronously download data from a URL with progress reporting.

## Installation

You can integrate the `Networking` library into your project using Swift Package Manager.

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/vinodh06/Networking.git", from: "0.0.2")
]
```

Then, add `"Networking"` to the dependencies of your target:

```swift
targets: [
    .target(name: "YourTarget", dependencies: ["Networking"])
]
```

Run `swift build` to download and build the dependencies.

## Usage

### URLBuilder

```swift
import Networking

// Create a URLBuilder instance
let urlBuilder = URLBuilder()
    .setScheme("https")
    .setHost("api.example.com")
    .setPath("/users")
    .setQueryItems(["page": "1", "limit": "10"])

// Build the URL
let url = urlBuilder.build()
```

### NetworkService

```swift
import Networking

// Perform a GET request
NetworkService.request(
    for: urlBuilder,
    method: .GET,
    headers: [
        HTTPHeader.contentType(value: "application/json")
    ]
) { result in
    switch result {
    case .success(let data):
        // Handle successful response
    case .failure(let error):
        // Handle error
    }
}
```

### Download Function

```swift
import Networking

do {
    // Call the download function passing a URLBuilder instance
    let stream = try Networking.download(for: urlBuilder)

    // Iterate over download events asynchronously
    var receivedData = Data()
    for try await event in stream {
        switch event {
        case .progress(let progress):
            // Handle progress updates
            print("Download progress: \(progress * 100)%")
            // Update UI or perform other tasks based on progress

        case .response(let data):
            // Append received data
            receivedData.append(data)
            // Process or save the downloaded data
        }
    }

    // Download completed
    print("Download completed. Total data received: \(receivedData.count) bytes")
} catch {
    // Handle any errors that occur during the download process
    print("Error: \(error)")
}
```

### Errors

```swift
enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    // Add more error cases as needed
}
```

## Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please create an issue or a pull request on GitHub.

