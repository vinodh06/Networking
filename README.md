# Networking

`Networking` is a Swift package for making network requests using URLSession.

## Features

- Supports various HTTP methods (GET, POST, PUT, DELETE).
- Allows customization of HTTP headers.
- Handles network errors and response decoding.

## Installation

You can install `Networking` using Swift Package Manager.

```swift
dependencies: [
    .package(url: "https://github.com/vinodh06/Networking.git", from: "0.0.1")
]
```

## Usage

```swift
import Networking

// Example usage
let urlBuilder = URLBuilder {
    scheme("https")
    host("api.example.com")
    path("users")
}
do {
    let user: User = try await NetworkService.fetch(for: urlBuilder)
    print("User: \(user)")
} catch {
    print("Error: \(error)")
}
```

## Contributing

Pull requests and issues are welcome. For major changes, please open an issue first to discuss what you would like to change.

