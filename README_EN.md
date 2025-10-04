# Rain Weather Flutter

A Flutter weather application refactored from the original Android project. This app provides real-time weather information with location services, weather forecasts, and beautiful UI components.

> **中文文档**: [README.md](README.md) | **English Documentation**: This file

## Features

### Core Functionality
- **Real-time Weather Data**: Fetches current weather conditions from weatherol.cn API
- **Location Services**: Uses GPS to automatically detect user location
- **Weather Forecasts**: 24-hour hourly forecast and 15-day daily forecast
- **Temperature Charts**: Interactive charts showing temperature trends
- **Air Quality**: Displays air quality index (AQI) with color-coded levels
- **Main Cities**: Quick access to weather for major Chinese cities
- **Sun & Moon Info**: Precise sunrise/sunset times and moon phase information
- **Moon Phases**: Real-time moon phase emojis and moon age display
- **Life Index**: Clothing, health, and activity recommendations

### UI/UX Features
- **Material Design 3**: Strictly follows Google Material Design 3 guidelines
- **Theme System**: Complete light/dark theme support with smooth transitions
- **Unified Card Design**: Consistent Material Design card style across all pages
- **Responsive Design**: Adapts to different screen sizes
- **Pull-to-Refresh**: Easy data refresh with pull gesture
- **Loading States**: Smooth loading indicators and error handling
- **Rich Weather Icons**: 45 weather types with better emoji compatibility
- **Clear Visual Hierarchy**: Optimized font sizes and spacing design
- **Interactive Charts**: Touch-enabled temperature trend charts

### Technical Features
- **State Management**: Provider pattern for reactive UI updates
- **Local Caching**: SQLite database for offline data storage
- **Background Updates**: Periodic weather data refresh
- **Error Handling**: Comprehensive error handling and fallback states
- **JSON Serialization**: Automatic model serialization/deserialization

## Project Structure

```
lib/
├── constants/          # App constants and configuration
├── models/            # Data models with JSON serialization
├── providers/         # State management with Provider
├── screens/           # Main UI screens
├── services/          # Business logic and API services
├── widgets/           # Reusable UI components
└── utils/             # Utility functions
```

## Dependencies

### Core Dependencies
- **provider**: State management
- **dio**: HTTP client for API requests
- **geolocator**: Location services
- **sqflite**: Local database storage
- **fl_chart**: Interactive charts

### UI Dependencies
- **cached_network_image**: Image caching
- **flutter_svg**: SVG support
- **lottie**: Animation support

### Development Dependencies
- **json_serializable**: JSON model generation
- **build_runner**: Code generation

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd rainweather_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

The app uses the following API endpoints:
- **Weather API**: `https://www.weatherol.cn/api/home/getCurrAnd15dAnd24h?cityid=`
- **City Data**: Local `city.json` file with city mappings

## Architecture

### State Management
The app uses the Provider pattern for state management:

- **WeatherProvider**: Manages weather data, location, and UI state
- **Reactive Updates**: UI automatically updates when data changes
- **Error Handling**: Centralized error state management

### Data Flow
1. **Location Service**: Gets current GPS location
2. **Weather Service**: Fetches weather data from API
3. **Database Service**: Caches data locally
4. **Provider**: Manages state and notifies UI
5. **UI**: Displays data reactively

### Services
- **LocationService**: GPS location detection and permission handling
- **WeatherService**: API communication and data parsing
- **DatabaseService**: Local storage and caching

## API Integration

The app integrates with the weatherol.cn weather API:

### Endpoints
- **Current Weather**: `/getCurrAnd15dAnd24h?cityid={cityId}`
- **Response Format**: JSON with current, forecast24h, and forecast15d data

### Data Models
- **WeatherModel**: Complete weather data structure
- **CurrentWeather**: Current conditions
- **HourlyWeather**: 24-hour forecast
- **DailyWeather**: 15-day forecast
- **AirQuality**: Air quality information

## Permissions

### Android Permissions
- `ACCESS_FINE_LOCATION`: GPS location access
- `ACCESS_COARSE_LOCATION`: Network location access
- `ACCESS_BACKGROUND_LOCATION`: Background location updates
- `INTERNET`: Network access for API calls
- `WAKE_LOCK`: Background task execution

## Development

### Code Generation
Run code generation after model changes:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Testing
```bash
flutter test
```

### Building
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## Migration from Android

This Flutter app is a complete refactor of the original Android weather app with the following improvements:

### Enhanced Features
- **Modern UI**: Material Design 3 with dark theme
- **Better State Management**: Provider pattern vs manual state handling
- **Improved Error Handling**: Comprehensive error states and fallbacks
- **Cross-Platform**: Runs on both Android and iOS
- **Better Performance**: Flutter's efficient rendering engine

### Preserved Functionality
- **Same API**: Uses identical weather API endpoints
- **Same Data Structure**: Maintains compatibility with existing data
- **Same Features**: All original features preserved and enhanced
- **Same City Support**: Supports all original Chinese cities

## App Screens

### Today Weather
- Current weather conditions display
- Temperature, humidity, wind speed and other detailed information
- Air quality index (AQI)
- Sunrise and sunset times
- Feels-like temperature
- Compact weather detail cards with green and blue color scheme

### 24-Hour Forecast
- Hourly weather changes
- Interactive temperature trend chart
- Weather icons and descriptions
- Wind direction and speed information

### 15-Day Forecast
- 15-day weather forecast
- Interactive temperature trend chart
- Morning/afternoon weather comparison
- Sunrise and sunset times
- Compact card layout for better space utilization

### Main Cities
- Weather for major Chinese cities
- Quick city switching
- City weather comparison
- Unified card design with glass-morphism effect

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Changelog

### v1.2.0 (Latest)
- ✨ **Material Design 3 Optimization**: Complete upgrade to Material Design 3 guidelines
- 🌅 **Sun & Moon Cards**: New sunrise/sunset and moonrise/moonset information display
- 🌙 **Moon Phase Feature**: Real-time moon phase emoji display and moon age information
- 💡 **Life Index**: Clothing, health, and activity recommendation indices
- 🎨 **UI Improvements**: Unified card styling, optimized font sizes and spacing
- 🌈 **Weather Icons**: Expanded to 45 weather types with better compatibility
- 🔧 **Code Optimization**: Fixed theme adaptation issues and improved code quality

### v1.1.0
- 🎨 **Theme System**: Complete light/dark theme support
- 📱 **Responsive Design**: Optimized mobile experience
- 🔄 **State Management**: Refactored using Provider pattern

### v1.0.0
- 🚀 **Initial Release**: Basic weather functionality implementation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Original Android weather app for inspiration and API integration
- weatherol.cn for providing weather data API
- Flutter team for the excellent framework
- Open source community for various packages used