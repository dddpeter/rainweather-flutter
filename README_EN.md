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

### v1.13.1 (2025-01-20)

**Stability Optimization**
- 🛡️ **Enhanced AI Component Error Handling**: Fixed potential red screen issues when no cache is available
- 🔄 **Widget State Management Optimization**: Avoid triggering state updates during build process, resolving InheritedElement assertion failures
- 🎯 **Provider Null Safety Enhancement**: Added null safety checks and default value fallbacks for all Provider access
- ⚡ **AI Generation Trigger Optimization**: Use Selector to precisely monitor state changes and prevent duplicate triggers

**Cache Strategy Optimization**
- 💾 **AI Cache Duration Adjustment**: Reduced AI request cache from 1 hour to 5 minutes to minimize duplicate generation
- 🚀 **Startup Experience Optimization**: Always display cached data first, then silently refresh latest content in background
- 📦 **Database Cache Update**: Unified AI summary and 15-day forecast cache validity period to 5 minutes
- 🎨 **Smart Cache Judgment**: Automatically select display strategy based on cache freshness

**Error Handling Improvements**
- 🛠️ **Exception Fallback Mechanism**: Added try-catch protection to all critical components
- 📝 **Friendly Error Messages**: Display user-friendly default messages in exceptional situations
- 🔍 **Detailed Error Logging**: Complete log output for easier troubleshooting
- 💪 **Robustness Enhancement**: No crashes even with network exceptions or cache failures

### v1.13.0 (Latest - 2025-01-19)

**Brand Upgrade**
- ✨ **App Name Update**: Upgraded from "知雨天气2" to "智雨天气"
- 🎨 **Enhanced Brand Identity**: More concise and memorable app name
- 📱 **Full Platform Update**: Unified name across Android, iOS, Web, Windows, Linux
- 🎯 **Improved User Experience**: Clearer brand recognition

### v1.12.6 (2025-01-18)

**AI Content Optimization**
- ✨ **Typewriter Effect**: All AI-generated content supports line-by-line typewriter effect for better user experience
- 💾 **Cache Optimization**: Cached content displays instantly without typewriter effect for fast response
- 📝 **Prompt Optimization**: AI prompts for commute advice, health advisor, and extreme weather alerts are more professional and practical
- 🌙 **Lunar Calendar Interpretation**: New AI interpretation feature for lunar calendar and traditional almanac

**Lunar Calendar Features**
- 🗓️ **Lunar Detail Page Redesign**: Redesigned lunar calendar detail page with more compact and beautiful layout
- 🎨 **Direction Layout**: Changed to 2x2 vertical card layout for intuitive display of God of Wealth, God of Joy, God of Fortune directions
- ⭐ **Constellation & Star**: Display in one row with lucky/unlucky format like "虚(凶)", color-coded
- 📖 **AI Interpretation**: Added AI interpretation for Peng Zu Bai Ji and Yi Ji, with 10-day caching
- 📅 **Calendar Optimization**: Reduced font size and spacing, marked auspicious days with orange background

**Layout Optimization**
- 📱 **24-Hour Weather**: Card spacing reduced from 8px to 2px, width from 72 to 58 for more compact display
- 🎨 **Life Index**: Removed AI interpretation entry, restored clean design
- 🔧 **Code Refactoring**: Optimized main.dart structure, extracted AppInitializationService, AppRouteObserver, MainAppBar
- 🎯 **Unified Standards**: All AI cards use consistent Material Design 3 styling

**Bug Fixes**
- 🐛 **Text Decoration Fix**: Fixed global theme causing automatic text underlines
- 🎨 **Theme Configuration**: Set all TextTheme decoration to none in theme
- 📝 **Text Display**: All text components no longer show unexpected underline decorations

### v1.12.3 (2025-01-14)

**AI Smart Assistant Comprehensive Optimization**
- ✨ **Startup Optimization**: AI summary loads from cache first, avoiding "generating" flicker
- 🚗 **Commute Reminders**: Show today's historical reminders even outside commute hours for review
- 📱 **Card Interaction**: Commute reminders show 4 lines (1 title + 3 content), tap to jump to comprehensive reminder page
- 🏝️ **Floating Island**: Static opacity increased to 60% for better visibility for elderly users (from 15%)
- 🌓 **Theme Quick Switch**: Added light/dark theme toggle icon in upper left of today screen
- 🎯 **Interaction Simplification**: Removed multi-layer expansion logic, one-step access to details

### v1.12.1 (2025-01-12)

**Temperature Trend Charts Comprehensive Optimization**
- 📊 **7-Day Temperature Chart**: Added weather icons and temperature values at data points for intuitive daily weather display
- 📈 **24-Hour Temperature Chart**: Added weather icons and temperature values with horizontal scrolling support
- 📉 **15-Day Temperature Chart**: Added weather icons and temperature values with horizontal scrolling and vertical grid lines
- 🎨 **Visual Optimization**: Hidden X/Y axis lines, added vertical grid lines, temperature values with stroke effect
- 🌤️ **Smart Icons**: Automatically displays day/night weather icons based on time
- 📱 **Layout Optimization**: Increased chart height, adjusted top spacing to ensure complete icon display
- 🎯 **Interaction Optimization**: 24-hour and 15-day charts support horizontal scrolling for smooth data viewing

### v1.12.0 (2025-01-11)

**AI Smart Assistant Independent Card Design**
- 🎨 AI smart assistant separated from header card into independent card
- 🌌 Deep purple to deep blue gradient background, tech-inspired design
- ✨ Golden amber icons and text, more prominent on dark background
- 📱 Spacing design aligned with city weather header for better coordination

**Header Background Image Effect**
- 🌌 Added camping scene background image to today's weather and city weather headers
- 🎨 Background image transparency control without affecting text readability
- 🏕️ Creates natural, warm outdoor atmosphere
- 📱 Fixed deep blue background with subtle texture effect

**Weather Icon System Comprehensive Upgrade**
- 🎯 Fully replaced emoji icons with Chinese PNG icons
- 🌙 Day/night mode support with automatic night icon switching
- 📱 Complete coverage of 71 weather types
- 🔧 Automatic fallback handling for icon loading failures

**Air Quality Card Componentization**
- 📱 Extracted as independent reusable component `AirQualityCard`
- 🎨 Unified card style and spacing design
- 🔄 Supports reuse in today's weather and city weather pages
- 📐 Follows Material Design 3 standards

**Card Style Unification Optimization**
- 🎨 All cards follow unified Material Design 3 design standards
- 📐 Unified standards for border radius, spacing, shadows, and transparency
- 🌈 Enhanced visual hierarchy with gradient backgrounds and shadow effects
- 🎯 Clear color constraints to avoid contrast issues

**Visual Effect Enhancement**
- 🌈 Multi-layer gradient background effects
- ✨ Smart transparency hierarchy design
- 🎨 Golden glow and shadow effects
- 📱 Responsive layout adaptation

### v1.11.0 (2025-10-10)

**Material Design 3 Enhancement**
- 🎨 Comprehensive MD3 card design standards with unified styling
- 📐 Unified inner card transparency (light 0.15/0.2, dark 0.25/0.3)
- 🚫 Color constraint: Avoid blue tones in inner cards (poor contrast on dark background)
- 🎯 Unified border radius: 4px (inner cards), 8px (outer cards)
- 🔲 Removed borders from inner cards, using transparency for visual hierarchy

**AI Features Optimization**
- 🤖 AI assistant color optimization (blue → amber gold #FFB300)
- ✨ Smart AI badge display (only shows on AI-generated suggestions)
- 🧠 Dynamic commute advice title generation (auto-generated based on weather)
- 🎯 AI badge position optimization (moved from card header to content)

**Commute Alert System**
- 🚗 Real-time theme switching for commute alert component
- 🎨 Complete design unification between commute and weather alerts
- 📊 Optimized expand/collapse interaction (collapsed shows first item summary)
- 🔄 Semantic expand icons (collapsed: right arrow →, expanded: down arrow ↓)
- 🟢 "Info" level color changed to green (avoiding blue contrast issues)

**Card Layout Optimization**
- 📋 Today's tips card moved forward (before 24h forecast/details)
- 🏷️ Count badge always visible (including "1 item")
- 🎯 Clothing advice and afternoon period use green (avoiding blue)

**Interaction Experience**
- 👆 Weather alert cards clickable to navigate to detail page
- 👆 Commute alert cards clickable to expand when collapsed
- 🎯 Clearer header tap interactions
- 📱 Removed expand/collapse icon from weather alerts, using "More" text

**Documentation Enhancement**
- 📖 Added comprehensive MD3 design standards section
- 📐 Detailed card style specifications (with code examples)
- 🎨 Color usage principles and constraints
- 📋 Applicable components list (13 components)

### v1.10.0

**UI/UX Improvements**
- 🎨 Bottom navigation bar Material Design 3 style optimization
- 📐 Unified card corner radius to 8dp standard (Material Design 3)
- 🌙 Enhanced selected state visibility in dark mode (24% opacity)
- 📱 Widget layout optimization for all screen sizes

**Feature Enhancements**
- 🔄 Main cities page refresh without re-locating, saves battery
- 📍 Location icon tap triggers re-location only
- 💧 Improved rain alert logic for better accuracy
- 🔧 Fixed infinite refresh issue
- 📏 Widget text single-line display without wrapping

### v1.9.0

**Home Screen Widget**
- 🏠 New Android home screen weather widget feature
- 🖼️ Support for real weather icons (25 weather types)
- 🎨 Adaptive dark/light theme with frosted glass background
- 📅 Display 5-day weather forecast (tomorrow to day 6)
- 🔄 Auto-refresh weather data in background every 5 minutes
- 📱 Optimized for small screens with adaptive layout

**Feature Improvements**
- 🔧 Fixed issue requiring two taps on add city button
- 🔄 Auto-refresh weather on first entry to main cities screen
- 📐 Widget adapts to all screen sizes without whitespace
- 🌡️ Unified temperature display using Celsius (℃) symbol

### v1.6.0

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