# Rain Weather Flutter

A Flutter weather application refactored from the original Android project. This app provides real-time weather information with location services, weather forecasts, and beautiful UI components.

> **中文文档**: [README.md](README.md) | **English Documentation**: This file

## Features

### Core Functionality
- **Real-time Weather Data**: Fetches current weather conditions from weatherol.cn API
- **Smart Location Services**: Baidu Location + GPS automatic location detection and IP-based location fallback
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
- **flutter_bmflocation**: Baidu Location SDK for high-precision location services
- **geolocator**: GPS location services
- **sqflite**: Local database storage
- **fl_chart**: Interactive charts
- **permission_handler**: Permission management

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

### v1.6.0 (Latest)

**Weather Alert System**
- 🚨 New weather alert functionality supporting various alert types including heavy rain, typhoons, and heat waves
- 🚨 Real-time alert notifications to keep users informed of weather changes
- 🚨 Alert settings page allowing users to customize alert types and notification methods
- 🚨 Alert history records for reviewing past weather alerts

**Page Activation Monitoring**
- 📱 New page activation monitoring service for optimized app performance
- 📱 Smart page lifecycle management to reduce unnecessary network requests
- 📱 Enhanced app responsiveness and battery life

**UI/UX Improvements**
- 🎨 Optimized weather alert card design for better information readability
- 🎨 Improved alert icons and color schemes for enhanced visual recognition
- 🎨 Unified alert page design language maintaining overall app consistency

### v1.5.0

**Baidu Location Integration**
- 🎯 Integrated Baidu Location SDK for higher precision location services
- 🎯 Support for both iOS and Android platforms
- 🎯 Seamless integration with existing location services with automatic fallback
- 🎯 Complete location permission management and privacy policy consent flow

**Startup Flow Optimization**
- ⚡ Removed custom SplashScreen, using native splash screen
- ⚡ App starts directly into main interface, reducing wait time
- ⚡ Optimized initialization process for faster startup
- ⚡ Smoother user experience

**Enhanced Location Services**
- 📍 Baidu Location provides more accurate location information
- 📍 Support for high-precision mode (GPS + network positioning)
- 📍 Smart error handling and fallback strategies
- 📍 Detailed location logs and debugging information

### v1.4.0
- 🎨 **Small Card Icon Redesign**: Diversified color scheme for life index and detail card icons
- 🎨 **Semantic Color Design**: Detail card icons use meaningful colors based on their function
- 🎨 **Dark Theme Optimization**: Enhanced icon background opacity for better readability in dark mode
- 🎨 **Consistent Styling**: All small cards now match the today's tips card design

**Card Spacing Optimization**
- 📏 **Material Design 3 Compliance**: Updated card spacing to M3 recommended minimum (12dp)
- 📏 **Public Style Management**: Created unified card spacing styles for all pages
- 📏 **Modern Visual Design**: More compact and contemporary visual effects
- 📏 **Enhanced Information Density**: Improved user experience with better space utilization

**Theme Adaptation Improvements**
- 🌓 **Dark Theme Enhancement**: Further reduced small card background opacity in dark mode
- 🌓 **Better Contrast**: Ensured better contrast and readability on dark backgrounds
- 🌓 **Comprehensive Theme Support**: Improved theme adaptation for all card components

### v1.3.0
- 🎨 **Header Design Optimization**: Unified deep blue header background for today and city weather screens
- 🎨 **Consistent Visual Design**: Both light and dark themes use dark header backgrounds for visual consistency
- 🎨 **Enhanced Readability**: White text and icons on dark header background for better visibility
- 🎨 **Visual Hierarchy**: Added gradient effects and shadows to header areas for enhanced depth

**Weather Animation Improvements**
- 🌈 **Unified Color Scheme**: Light theme weather animations now use dark theme color palette
- 🌈 **Fixed Heavy Rain Colors**: Resolved overly dark small cloud colors in heavy rain, storm, and extreme rain animations
- 🌈 **Realistic Fog/Haze**: Updated fog and haze animations to use near-white gray colors for more realistic appearance
- 🌈 **Better Contrast**: All weather animations now have better visual effects on dark header backgrounds

**Test Page Enhancements**
- 🧪 **Consistent Card Design**: Weather animation test page cards now use deep blue background
- 🧪 **Unified Typography**: Test page card text uses white color, consistent with header styling
- 🧪 **Improved UX**: Enhanced visual consistency and user experience for test pages

**Technical Improvements**
- ⚡ **Optimized Color Management**: Improved header area color management system
- 🔧 **Dedicated Color Configs**: Added header-specific text and icon color configurations
- 🛡️ **Enhanced Theme Support**: Improved weather animation display across different themes
- 📦 **Unified Design Language**: Consistent design language across header areas

### v1.2.0
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