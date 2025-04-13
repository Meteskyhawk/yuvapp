# Cartridge Management App

A Flutter application for managing cartridge inventory in YUV Lab environments. This app allows tracking of cartridges across multiple slots, monitors inventory levels, and provides visual indicators for actions required.

## Features

- **Home Screen**: 
  - Inventory level monitoring for all cartridges
  - Drag and drop reordering of cartridges
  - Update slot positions and quantities
  - Visual indicators for inventory status

- **Carousel View**:
  - Visual representation of the carousel setup
  - Highlights empty slots and duplicated cartridges
  - Identifies cartridges that need attention (low quantities)

- **Synchronization**:
  - Regular data synchronization with backend
  - Pull-to-refresh for immediate updates
  - Offline-first approach for reliable operation

## Technology Stack

- **Flutter**: Cross-platform UI framework
- **Bloc Pattern**: For state management
- **SQLite**: Local database for persistent storage
- **API Integration**: For remote data synchronization

## Setup Instructions

1. Clone the repository
2. Ensure Flutter is installed (version ^3.5.4)
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Architecture

The application follows a clean architecture approach:
- **Data Layer**: Models, repositories, and data sources
- **Logic Layer**: BLoC pattern for business logic
- **Presentation Layer**: UI components and screens

## Screenshots

[Add screenshots of key screens here]
