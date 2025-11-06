# Offline-First POS Product Catalog

A Flutter mobile application demonstrating offline-first architecture for a Point of Sale (POS) product catalog. This app showcases robust offline capabilities, ensuring users can browse products even without an internet connection.

## Overview

This project was built to explore offline-first mobile app development patterns using Flutter. The app fetches product data from a remote API, caches it locally using SQLite, and provides a seamless experience whether online or offline.

## Features

- 🔄 **Offline-First Architecture**: Browse products even without internet connectivity
- 🔁 **Auto-Sync**: Automatically syncs products when connection is restored
- 📱 **Responsive UI**: Adaptive grid layout for mobile and tablet devices
- 🔍 **Product Details**: Tap any product to view detailed information
- 🎨 **Modern Design**: Clean, Material Design 3 interface
- ⚡ **Real-time Status**: Visual indicators for sync status and connectivity
- 🔐 **API Authentication**: Secure bearer token authentication

## Tech Stack

- **Framework**: Flutter 3.9+
- **State Management**: Provider
- **Database**: SQLite with Prisma ORM
- **HTTP Client**: `http` package
- **Connectivity**: `connectivity_plus` for network monitoring
- **Environment**: `flutter_dotenv` for configuration management

## Architecture

### Architecture Overview
This app follows a clean architecture pattern with clear separation of concerns:

- **API Layer** (`lib/services/api_service.dart`): Handles HTTP requests with authentication and retry logic
- **Database Layer** (`lib/services/database_service.dart`): Manages local SQLite storage using Prisma ORM
- **Repository Layer** (`lib/repositories/product_repository.dart`): Abstracts data operations
- **Provider Layer** (`lib/providers/product_provider.dart`): Manages application state and business logic
- **UI Layer** (`lib/widgets/`): Reusable Flutter widgets for the product catalog

### Data Flow

1. **Online Sync**: API → Parse JSON → Store in DB → Display in UI
2. **Offline Mode**: Load from DB → Display cached products
3. **Product Selection**: Tap product → Show detailed dialog

## Getting Started

### Prerequisites

- Flutter SDK 3.9 or higher
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for running on devices/emulators)
- Optional: VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mobile-dev-challenge
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables** (optional)
   
   Create a `.env` file in the root directory:
   ```env
   API_BASE_URL=https://challenge-test.ordering.sg/api/products
   API_BEARER_TOKEN=chicken-good
   ```
   
   If no `.env` file is provided, the app will use default values.

4. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### Initial Sync

1. Launch the app
2. Tap the sync button (floating action button) to fetch products from the API
3. Products will be cached locally for offline access

### Offline Mode

- Turn off your device's internet connection
- The app will automatically load cached products
- Status banner will indicate "Offline Mode" with product count
- All product browsing features remain available

### Viewing Products

- **Grid View**: Products are displayed in a responsive grid (2 columns on mobile, 3 on tablet)
- **Product Details**: Tap any product card to view detailed information in a dialog
- **Pull to Refresh**: Pull down on the product list to manually trigger a sync

## Project Structure

```
lib/
├── config/              # Configuration files (API settings)
├── constants/           # App-wide constants
├── models/              # Data models and enums
├── providers/           # State management (Provider pattern)
├── repositories/        # Data access layer
├── services/            # Business logic services
├── utils/               # Utility functions
└── widgets/             # Reusable UI components
```

## Testing

Run all tests:
```bash
flutter test
```

The test suite includes:
- Unit tests for utility functions (price formatting, etc.)
- Widget tests for UI components
- Integration tests for repository and API services

## API Integration

The app integrates with a product catalog API:

- **Endpoint**: `https://challenge-test.ordering.sg/api/products`
- **Authentication**: Bearer token authentication
- **Response Format**: JSON with `{"data": [...]}` structure
- **Error Handling**: Comprehensive error handling with retry logic and user-friendly messages

## Database Schema

The app uses SQLite with the following schema:

```prisma
model Product {
  id    Int    @id
  name  String
  price String
}
```

## Key Features Implementation

### Offline-First Design
- Products are loaded from local database on app startup
- API sync updates the local cache
- Seamless fallback to cached data when network is unavailable

### Connectivity Monitoring
- Real-time connectivity status detection
- Automatic sync when connection is restored
- Visual indicators for online/offline status

### Error Handling
- Retry logic for failed API requests
- Graceful degradation with cached data
- User-friendly error messages
- Comprehensive logging for debugging

## Development Notes

- **Price Storage**: Prices are stored as strings to match the API format
- **State Management**: Uses Provider pattern for reactive UI updates
- **Resource Management**: Proper disposal of streams, timers, and database connections
- **Code Quality**: Follows Flutter best practices with comprehensive error handling

## Future Enhancements

Potential improvements for future iterations:
- Search and filter functionality
- Product categories
- Image support for products
- Batch operations for product management
- Analytics and usage tracking

## License

This project is open source and available for learning purposes.

---

Built with ❤️ using Flutter
