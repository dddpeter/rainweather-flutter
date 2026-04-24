---
name: RainWeather Design System
description: A modern Flutter weather forecasting application with intelligent location services and AI-enhanced features
colors:
  # Primary Colors - Blue Theme (Default)
  primary-blue-dark: "#012d78"
  primary-blue-light: "#4A90E2"
  accent-blue: "#8edafc"
  
  # Secondary Colors - Green Theme
  primary-green-dark: "#1B5E20"
  primary-green-light: "#4CAF50"
  accent-green: "#66BB6A"
  
  # Tertiary Colors - Amber Theme
  primary-amber-dark: "#E65100"
  primary-amber-light: "#FFB300"
  accent-amber: "#FFD54F"
  
  # Semantic Colors
  semantic-success: "#4CAF50"
  semantic-warning: "#FFB74D"
  semantic-error: "#D32F2F"
  semantic-info: "#4A90E2"
  
  # Neutral Colors - Dark Mode
  neutral-bg-dark: "#0A1B3D"
  neutral-surface-dark: "#1A2F5D"
  neutral-text-primary-dark: "#FFFFFF"
  neutral-text-secondary-dark: "#E8F4FD"
  neutral-text-tertiary-dark: "#B8D9F5"
  neutral-border-dark: "#2D4A7D"
  
  # Neutral Colors - Light Mode
  neutral-bg-light: "#C0D8EC"
  neutral-surface-light: "#FFFFFF"
  neutral-text-primary-light: "#001A4D"
  neutral-text-secondary-light: "#003366"
  neutral-text-tertiary-light: "#6B7280"
  neutral-border-light: "#B8D9F5"
  
  # Card Colors
  card-bg-dark: "rgba(255, 255, 255, 0.15)"
  card-bg-light: "#FFFFFF"
  card-border-dark: "rgba(255, 255, 255, 0.21)"
  card-border-light: "#E1F5FE"
  
  # Weather Semantic Colors
  weather-sunny: "#FFD54F"
  weather-cloudy: "#BDBDBD"
  weather-rainy: "#64B5F6"
  weather-snowy: "#E1F5FE"
  weather-foggy: "#9E9E9E"
  
  # Temperature Colors
  temp-high-dark: "#FF5722"
  temp-high-light: "#D32F2F"
  temp-low-dark: "#8edafc"
  temp-low-light: "#012d78"
  
  # Air Quality Colors
  aqi-excellent: "#4CAF50"
  aqi-good: "#8BC34A"
  aqi-light-pollution: "#FFC107"
  aqi-moderate-pollution: "#FF9800"
  aqi-heavy-pollution: "#F44336"
  aqi-severe-pollution: "#9C27B0"
  
  # AI Feature Colors
  ai-gold-dark: "#FFB300"
  ai-gold-medium: "#FFC947"
  ai-gold-light: "#FFE082"
  ai-text-dark: "#3E2723"
  
  # Special Accent Colors
  accent-orange: "#FFB74D"
  accent-green-bright: "#64DD17"
  accent-gold-auspicious-light: "#F9A825"
  accent-gold-auspicious-dark: "#FFD700"
  accent-red-ominous-light: "#D32F2F"
  accent-red-ominous-dark: "#E53935"

typography:
  display:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.5px"
  headline-large:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.3px"
  headline-medium:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.2px"
  headline-small:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.1px"
  title-large:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0px"
  title-medium:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0px"
  body-large:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0.1px"
  body-medium:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0.1px"
  body-small:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "0.2px"
  label-large:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0.1px"
  label-medium:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0.2px"
  label-small:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0.3px"
  caption:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "0.3px"
  temperature-display:
    fontFamily: "NotoSansSC, sans-serif"
    fontSize: "48px"
    fontWeight: 300
    lineHeight: 1.1
    letterSpacing: "-1px"

rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"

spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  xxxl: "48px"

components:
  button-primary:
    backgroundColor: "{colors.primary-blue-dark}"
    textColor: "{colors.neutral-text-primary-dark}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  card-standard:
    backgroundColor: "{colors.card-bg-dark}"
    rounded: "{rounded.sm}"
    padding: "16px"
  card-compact:
    backgroundColor: "{colors.card-bg-dark}"
    rounded: "{rounded.sm}"
    padding: "12px"
  card-small:
    backgroundColor: "{colors.card-bg-dark}"
    rounded: "{rounded.xs}"
    padding: "8px"
  chip-tag:
    backgroundColor: "{colors.accent-blue}"
    textColor: "{colors.neutral-text-primary-dark}"
    rounded: "{rounded.xs}"
    padding: "4px 8px"
---

# Design System: RainWeather

## 1. Overview

**Creative North Star: "The Intelligent Weather Companion"**

RainWeather is a sophisticated weather application that balances data density with visual clarity. The design philosophy centers on **functional elegance** — every visual element serves a purpose in communicating weather information quickly and accurately. The system embraces Material Design 3 principles while maintaining a distinct identity through its deep blue color palette and glassmorphic card treatments.

The interface prioritizes **progressive disclosure**: essential weather data appears immediately, while detailed insights unfold through interaction. This approach prevents cognitive overload while ensuring power users can access comprehensive meteorological data.

The aesthetic is **calm but authoritative**. Deep blues evoke trust and stability (appropriate for weather data), while amber accents highlight AI-generated insights and important alerts. The dark mode dominates the experience, reflecting the reality that users often check weather in low-light conditions (morning/evening).

**Key Characteristics:**
- Data-first layout with clear visual hierarchy
- Glassmorphic cards with subtle borders for depth without heavy shadows
- Amber accent color reserved exclusively for AI features and critical alerts
- Responsive grid system adapting from mobile to desktop seamlessly
- Noto Sans SC font family for optimal Chinese character rendering
- Fixed semantic colors for weather phenomena (sunny=gold, rain=blue, etc.)

## 2. Colors

The color system employs a **dual-mode strategy**: theme-adaptive UI colors shift between light/dark modes, while semantic weather colors remain constant for instant recognition.

### Primary

The primary palette centers on deep blues, evoking sky and water — natural associations for a weather app. The blue theme is default, with nine alternative color schemes available.

- **Deep Navy** (#012d78): Primary brand color in light mode. Used for headers, active states, and key interactive elements. Provides strong contrast against light backgrounds.
- **Medium Blue** (#4A90E2): Primary brand color in dark mode. Serves as the main accent against dark backgrounds. Appears in gradients, icons, and selected states.
- **Sky Blue** (#8edafc): Secondary accent used consistently across both modes. Represents low temperatures, clear skies, and calm conditions. Never used for text on white backgrounds (fails WCAG AA).

### Secondary

Green and amber themes provide alternative brand personalities while maintaining the same structural color relationships.

- **Forest Green** (#1B5E20 / #4CAF50): Alternative primary for eco-conscious users. Follows the same light/dark mode pattern as blue.
- **Amber Orange** (#E65100 / #FFB300): Warm alternative theme. Used sparingly in the default blue theme for warnings and AI features.

### Tertiary

Tertiary colors serve specific functional roles rather than branding.

- **AI Gold** (#FFB300 → #FFE082 gradient): Reserved exclusively for AI-generated content (smart summaries, commute advice, weather interpretations). The gradient creates visual distinction from standard UI elements.
- **Sunrise Orange** (#FFA726): Used for sunrise times and morning-related data.
- **Sunset Pink** (#E91E63): Used for sunset times and evening-related data.
- **Moon Purple** (#B39DDB): Used for lunar phase information and night-time indicators.

### Neutral

Neutral colors form the foundation of the interface, carefully calibrated for readability in both modes.

**Dark Mode Neutrals:**
- **Background** (#0A1B3D): Deep navy background. Provides excellent contrast for white text while feeling less harsh than pure black.
- **Surface** (#1A2F5D): Slightly lighter than background. Used for app bars, navigation, and elevated surfaces.
- **Text Primary** (#FFFFFF): Pure white for maximum readability. Used for headings, temperatures, and critical data.
- **Text Secondary** (#E8F4FD): Off-white with slight blue tint. Used for labels, secondary information, and disabled states.
- **Text Tertiary** (#B8D9F5): Muted blue-gray. Used for captions, timestamps, and least-important text. Must maintain 4.5:1 contrast ratio — avoid using on colored backgrounds.
- **Border** (#2D4A7D): Subtle divider color. Used for card borders, dividers, and separators.

**Light Mode Neutrals:**
- **Background** (#C0D8EC): Light blue-tinted background. Softer than pure white, reduces eye strain.
- **Surface** (#FFFFFF): Pure white for cards and elevated surfaces.
- **Text Primary** (#001A4D): Deep navy for maximum contrast. Equivalent to white in dark mode.
- **Text Secondary** (#003366): Medium-dark blue for secondary text.
- **Text Tertiary** (#6B7280): Gray for tertiary information.
- **Border** (#B8D9F5): Light blue border color.

**Card Backgrounds:**
- **Dark Mode Card** (rgba(255,255,255,0.15)): Semi-transparent white creating glassmorphic effect. Allows background gradient to show through subtly.
- **Light Mode Card** (#FFFFFF): Solid white with border for definition.
- **Weather Header Card** (#0A1B3D): Fixed deep blue for today's weather and city weather page headers. Does not change with theme mode — provides consistent brand anchor.

### Named Rules

**The Semantic Color Rule.** Weather phenomenon colors never change: sunny is always gold (#FFD54F), rain is always blue (#64B5F6), snow is always pale blue (#E1F5FE). Users build muscle memory for these associations — breaking them causes confusion.

**The AI Amber Rule.** Amber/gold colors (#FFB300 range) are reserved exclusively for AI-generated content. If it's not AI-generated, don't use amber. This creates instant visual distinction between algorithmic insights and raw data.

**The Contrast Hierarchy Rule.** Text tertiary (#B8D9F5 dark / #6B7280 light) must maintain 4.5:1 contrast against its background. Never place tertiary text on colored card backgrounds without verification. When in doubt, elevate to text secondary.

**The Fixed Header Rule.** The weather header card (#0A1B3D) remains constant regardless of theme mode. This provides a stable visual anchor as users switch between light and dark themes.

## 3. Typography

**Display Font:** Noto Sans SC (思源黑体) — chosen for exceptional Chinese character rendering, multiple weights, and cross-platform consistency.

**Character:** Clean, modern, and highly legible. Noto Sans SC provides excellent hinting at small sizes while maintaining elegance at display sizes. The typeface's neutral personality lets weather data take center stage.

### Hierarchy

The typography scale follows an 8-point base with strategic jumps for emphasis:

- **Display Large** (Bold 700, 32px, line-height 1.2, letter-spacing -0.5px): Page titles and major section headers. Used sparingly — typically once per screen. Negative letter-spacing tightens large text for visual cohesion.

- **Headline Large** (Bold 700, 28px, line-height 1.2, letter-spacing -0.3px): Major block titles like "15-Day Forecast" or "Air Quality". Creates clear section divisions.

- **Headline Medium** (SemiBold 600, 24px, line-height 1.3, letter-spacing -0.2px): Card titles and prominent data points. The workhorse heading size.

- **Headline Small** (SemiBold 600, 20px, line-height 1.3, letter-spacing -0.1px): Important numbers like temperature readings. Balances prominence with space efficiency.

- **Title Large** (SemiBold 600, 18px, line-height 1.3): Subsection titles within cards. Used for "Feels Like", "Humidity", etc.

- **Title Medium** (Medium 500, 16px, line-height 1.4): List item titles, button text, and interactive labels.

- **Body Large** (Regular 400, 16px, line-height 1.5, letter-spacing 0.1px): Primary body text. Maximum comfortable reading size for extended content like AI summaries. Line height of 1.5 ensures readability.

- **Body Medium** (Regular 400, 14px, line-height 1.5, letter-spacing 0.1px): Standard body text. The most common size for labels, descriptions, and secondary information. Optimal balance of readability and space efficiency.

- **Body Small** (Regular 400, 12px, line-height 1.4, letter-spacing 0.2px): Compact text for dense information displays. Used in 24-hour forecast rows, chart labels, and compact lists. Increased letter-spacing compensates for small size.

- **Label Large** (Medium 500, 16px, line-height 1.4): Interactive element labels. Slightly bolder than body text to indicate clickability.

- **Label Medium** (Medium 500, 14px, line-height 1.4): Button text, chip labels, and tab labels.

- **Label Small** (Medium 500, 12px, line-height 1.3, letter-spacing 0.3px): Small interactive labels. High letter-spacing maintains legibility at tiny sizes.

- **Caption** (Regular 400, 11px, line-height 1.4, letter-spacing 0.3px): Smallest text size. Used for disclaimers, timestamps, and auxiliary information. Never use for critical data.

- **Temperature Display** (Light 300, 48px, line-height 1.1, letter-spacing -1px): Oversized temperature numbers on main screens. Light weight prevents visual heaviness despite large size. Aggressive negative letter-spacing creates tight, impactful numerals.

### Named Rules

**The Weight Progression Rule.** Font weights follow a strict progression: 300 (display numbers only), 400 (body text), 500 (interactive labels), 600 (headings), 700 (major headings). Never skip weights — this creates visual rhythm.

**The Line Height Rule.** Body text uses 1.5 line-height for comfortable reading. Headings compress to 1.2-1.3 for tighter visual grouping. Display numbers tighten further to 1.1. Never use single line-height (1.0) except for isolated numbers.

**The Letter Spacing Rule.** Large text (>24px) uses negative letter-spacing (-0.5px to -0.1px) to prevent loose, gappy appearance. Small text (<14px) uses positive letter-spacing (0.2px to 0.3px) to improve character separation. Body text at 14-16px uses minimal spacing (0.1px).

## 4. Elevation

RainWeather employs a **hybrid elevation system**: subtle shadows combined with tonal layering and border definition. The approach favors flat surfaces with minimal depth, reserving shadows for floating elements and modal interactions.

### Shadow Vocabulary

The shadow system uses three tiers, all derived from `buttonShadow` token which adapts to theme mode:

- **Card Shadow** (`blurRadius: 10, offset: Offset(0, 4)`): Standard elevation for Material cards. In dark mode, shadow is rgba(0,0,0,0.3); in light mode, rgba(0,0,0,0.15). Applied via `AppColors.cardElevation` (value: 2). Creates gentle lift without harsh drop shadows.

- **Dialog Shadow** (two-layer: `blurRadius: 20, offset: Offset(0, 8)` + `blurRadius: 40, offset: Offset(0, 16)`): Heavy elevation for modals and dialogs. Dual-shadow approach creates realistic depth with soft diffusion. Used for bottom sheets, confirmation dialogs, and full-screen overlays.

- **Floating Island Shadow** (multi-layer with `blurRadius: 16` and `blurRadius: 8`): Complex shadow for floating action elements. Creates pronounced lift for interactive islands that hover above content.

- **Chart Point Shadow** (`blurRadius: 0.5`): Micro-shadows for chart data points. Extremely subtle, almost imperceptible — just enough to separate points from grid lines.

**Shadow Opacity by Theme:**
- Dark mode shadows: 30% opacity (stronger contrast needed against dark backgrounds)
- Light mode shadows: 15% opacity (softer appearance on light backgrounds)

### Border-Based Depth

Cards primarily use **border definition** rather than shadows for depth:

- **Standard Card Border**: 1px solid border using `cardBorder` color (rgba(255,255,255,0.21) dark / #E1F5FE light). Creates clear card boundaries without relying on shadows.
- **Glass Effect Cards**: Semi-transparent background (rgba(255,255,255,0.15)) with border creates frosted glass appearance. Background gradient shows through subtly.

### Named Rules

**The Flat-by-Default Rule.** Surfaces are flat at rest. Shadows appear only for: (1) Material Design Cards with explicit elevation, (2) Floating elements (FAB, action islands), (3) Modal dialogs. Standard content cards use borders, not shadows.

**The Shadow Intensity Rule.** Shadow opacity doubles in dark mode (30% vs 15%) because dark backgrounds absorb shadow visibility. A shadow that looks correct in light mode will disappear in dark mode without this adjustment.

**The Border-First Rule.** When defining card boundaries, prefer 1px borders over shadows. Borders are more reliable across different background colors and provide clearer visual separation in dense layouts.

## 5. Components

### Cards

Cards are the primary content containers, following Material Design 3 specifications with custom adaptations for weather data density.

**Shape:** Standard radius of 8px (`rounded.sm`). Small cards (tags, chips) use 4px (`rounded.xs`). Dialogs use 12px (`rounded.md`).

**Background:** 
- Dark mode: Semi-transparent white (rgba(255,255,255,0.15)) allowing background gradient to show through
- Light mode: Solid white (#FFFFFF) with border for definition
- Weather header: Fixed deep blue (#0A1B3D) regardless of theme

**Border:** 1px solid border using theme-adaptive `cardBorder` color. Essential for card definition in both modes.

**Internal Padding:**
- Standard cards: 16px (`spacing.lg`) — used for detailed information, air quality, charts
- Compact cards: 12px (`spacing.md`) — used for smaller content blocks
- Small cards: 8px (`spacing.sm`) — used for tags, chips, hourly forecast items
- Chart cards: 12px (`spacing.md`) — reduced padding to maximize chart area

**Spacing Between Cards:** 12px vertical (`spacing.md`) — Material Design 3 minimum recommended spacing. Horizontal margin of 8px on each side (`screenHorizontalPadding`).

**Shadow Strategy:** Most cards use no shadow (flat with border). Material Design Cards use elevation 2 with adaptive shadow color. Shadow cards (for emphasis) use elevation 4.

**Card Types:**
- **Standard Card**: Default card with border, 16px padding, 8px radius
- **Compact Card**: Reduced padding (12px) for space-constrained scenarios
- **Small Card**: Minimal card (8px padding, 4px radius) for tags and chips
- **Shadow Card**: Elevated card with shadow for emphasis
- **Glass Card**: Semi-transparent background with border for frosted effect
- **AI Gradient Card**: Amber gradient background with glow shadow for AI features

### Buttons

Buttons follow Material Design 3 principles with weather-specific adaptations.

**Shape:** 8px radius (`rounded.sm`) for standard buttons. 4px radius (`rounded.xs`) for small action buttons.

**Primary Button:** Uses `primaryBlue` background with white text. Padding: 12px vertical, 24px horizontal. No border. Subtle shadow on press.

**Secondary Button:** Transparent background with `primaryBlue` border (1px). Same padding as primary. Text color matches border.

**Icon Button:** Circular or square with 8px radius. Size: 40x40px standard, 32x32px small. Icon size: 24px standard, 20px small.

**Hover/Focus States:** 
- Primary: Background darkens by 10% on hover
- Secondary: Background fills with 10% opacity of border color on hover
- Focus ring: 2px outline using `accentBlue` with 4px offset

### Chips / Tags

Chips display categorical information (weather conditions, AQI levels, life indices).

**Style:** 4px radius (`rounded.xs`). Background uses semantic colors (orange #FFB74D, green #64DD17, etc.). White text for high contrast.

**Size:** Height: 24-32px. Padding: 4px vertical, 8px horizontal. Font: Label Small (12px, Medium 500).

**State:** Selected chips show darker background or added border. Filter chips toggle between outlined (unselected) and filled (selected).

**Special Variants:**
- **Current Location Tag**: Red background (#E53E3E) with white text. Indicates GPS-derived location vs. manually selected city.
- **AI Tag**: Amber gradient background with dark brown text (#3E2723). Always includes AI icon.
- **AQI Level Tags**: Color-coded by pollution level (green=excellent, yellow=light, orange=moderate, red=heavy, purple=severe).

### Inputs / Fields

Text input fields for city search, settings, and configuration.

**Style:** 8px radius. 1px border using `borderColor`. Background matches card background. Padding: 12px vertical, 16px horizontal.

**Focus:** Border changes to `primaryBlue` (2px width). Optional glow effect using `accentBlue` at 20% opacity with 4px blur.

**Error State:** Border changes to `error` color (#D32F2F dark / #FF6B6B light). Error message appears below field in Body Small with error color.

**Disabled State:** Opacity reduced to 60%. Border becomes dashed or removed entirely.

### Navigation

**Bottom Navigation Bar:**
- Height: 56-64px (adaptive)
- Background: Matches `appBarBackground` (derived from `backgroundSecondary`)
- Active item: Uses `bottomNavSelectedText` color (#8edafc dark / semi-transparent white light)
- Inactive item: Uses `textTertiary` color
- Selected background: Transparent (no pill background)
- Icon size: 24px
- Label: Label Small (12px, Medium 500) below icon

**App Bar:**
- Height: 56px standard, 64px with search
- Background: Gradient using `primaryGradient` (theme-dependent)
- Elevation: 4 with shadow for depth
- Title: Headline Small (20px, SemiBold 600)
- Icons: 24px size, `titleBarIconColor` (textSecondary)

**Drawer Navigation:**
- Width: 280-320px (responsive)
- Header: Deep blue gradient matching app bar
- Items: 48px height, 16px horizontal padding
- Active item: Background using `currentTagBackground` with left border indicator
- Divider: 1px using `dividerColor`

### Weather-Specific Components

**Temperature Display:**
- Main temperature: Temperature Display style (48px, Light 300)
- High/Low temps: Headline Small (20px, SemiBold 600) with semantic colors
- High temp color: #FF5722 (dark) / #D32F2F (light) — warm reds/oranges
- Low temp color: #8edafc (dark) / #012d78 (light) — cool blues

**Weather Icon Grid:**
- Icon size: 48-64px for main display, 24-32px for lists
- Layout: Centered with condition text below
- Animation: Smooth transitions between weather states (300ms duration)

**24-Hour Forecast Row:**
- Layout: Horizontal scrollable list
- Item width: 60-80px per hour
- Time label: Caption (11px)
- Temperature: Body Small (12px, Medium 500)
- Icon: 24px
- Spacing: 8px between items

**15-Day Forecast Card:**
- Layout: Vertical list with AM/PM split
- Date: Body Medium (14px)
- Condition: Body Small (12px)
- Temperature range: Body Medium with high/low colors
- Chart: Mini sparkline showing temperature trend

**Air Quality Card:**
- AQI number: Display Small (24px, SemiBold 600)
- Level label: Title Medium (16px, Medium 500) with color-coded background
- Pollutant details: Body Small in grid layout
- Color coding: Follows national AQI standards (green→yellow→orange→red→purple)

**Life Index Grid:**
- Layout: 2-column or 4-column grid (responsive)
- Icon: 32-40px
- Label: Label Small (12px, Medium 500)
- Value: Body Medium (14px, Medium 500)
- Background: Alternating semantic colors (orange #FFB74D, green #64DD17)

### AI Content Widget

Specialized component for displaying AI-generated insights.

**Background:** Amber gradient (dark: #FFB300→#FFC947→#FFE082, light: #FFE082→#FFCC80→#FFA726)

**Border:** 1px amber border at 30% opacity

**Shadow:** Soft amber glow (`blurRadius: 20, spreadRadius: 2`)

**Text:** Dark brown (#3E2723) for high contrast on amber gradient

**Loading State:** Skeleton animation with shimmer effect

**Label:** "AI" badge in top-left corner using amber color

## 6. Do's and Don'ts

### Do:

- **Do** use the fixed weather header card color (#0A1B3D) for today's weather and city weather page headers, regardless of theme mode. This provides visual consistency and brand anchoring.

- **Do** reserve amber/gold colors (#FFB300 range) exclusively for AI-generated content. This creates instant visual distinction and helps users identify algorithmic insights.

- **Do** maintain semantic weather colors constant across themes: sunny=#FFD54F, cloudy=#BDBDBD, rainy=#64B5F6, snowy=#E1F5FE, foggy=#9E9E9E. Users build muscle memory for these associations.

- **Do** use 8px border radius (`rounded.sm`) as the standard for cards and containers. Use 4px (`rounded.xs`) only for small elements like chips and tags.

- **Do** apply 12px vertical spacing (`spacing.md`) between cards. This is the Material Design 3 minimum and provides adequate breathing room without wasting space.

- **Do** use Noto Sans SC (思源黑体) for all text. This font provides optimal Chinese character rendering and consistent cross-platform appearance.

- **Do** verify that text tertiary (#B8D9F5 dark / #6B7280 light) maintains 4.5:1 contrast ratio against its background. When placing text on colored card backgrounds, always test contrast.

- **Do** use border-based depth (1px solid border) as the primary method for defining card boundaries. Shadows are secondary and should be used sparingly.

- **Do** adapt shadow opacity to theme mode: 30% in dark mode, 15% in light mode. Dark backgrounds absorb shadows, requiring higher opacity for visibility.

- **Do** use the responsive breakpoint system: mobile (<600px), tablet (600-1023px), desktop (1024-1439px), large desktop (≥1440px). Adjust column count, padding, and spacing accordingly.

- **Do** follow the typography weight progression: 300 (display numbers), 400 (body), 500 (labels), 600 (headings), 700 (major headings). Never skip weights.

### Don't:

- **Don't** use blue colors inside small cards on dark backgrounds. Blue has poor contrast against the dark blue app background (#0A1B3D). Use orange (#FFB74D), green (#64DD17), or other high-contrast colors instead.

- **Don't** place text tertiary (#B8D9F5) on colored card backgrounds without verifying contrast. This is a common accessibility failure. Either elevate to text secondary or choose a different background color.

- **Don't** nest cards inside cards. This creates visual confusion and excessive depth. Use dividers, spacing, or background color shifts to create hierarchy within a card.

- **Don't** use pure black (#000000) or pure white (#FFFFFF) as background colors. The dark mode uses deep navy (#0A1B3D) and light mode uses blue-tinted white (#C0D8EC) to reduce eye strain.

- **Don't** change semantic weather colors based on theme. Sunny is always gold, rain is always blue. Changing these breaks user mental models.

- **Don't** use shadows as the primary method for card definition. Prefer 1px borders. Shadows should be reserved for floating elements and modals.

- **Don't** use font sizes outside the established scale (11, 12, 14, 16, 18, 20, 24, 28, 32, 48px). Arbitrary sizes break visual rhythm.

- **Don't** apply amber colors to non-AI features. The amber accent is specifically reserved for AI-generated content. Using it elsewhere dilutes its meaning.

- **Don't** use border-radius larger than 16px except for special cases (bottom sheets, full-screen modals). Excessive rounding looks unprofessional and wastes space.

- **Don't** ignore the screen horizontal padding (8px). All content should respect this margin to maintain consistent alignment across screens.

- **Don't** use bounce or elastic easing for animations. Use natural cubic-bezier curves (e.g., `cubic-bezier(0.4, 0, 0.2, 1)`) for smooth, professional motion.

- **Don't** place critical information below the fold on mobile devices. Essential weather data (current conditions, temperature, condition) must be visible without scrolling.

- **Don't** use gray text on colored backgrounds without testing contrast. This is one of the most common accessibility failures in the codebase. Always verify 4.5:1 ratio.

- **Don't** mix theme-adaptive colors with fixed colors arbitrarily. Understand which colors should shift with theme (UI elements) and which should remain constant (semantic weather colors).
