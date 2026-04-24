class WeatherIndexThresholds {
  WeatherIndexThresholds._();

  static const double clothingHot = 35;
  static const double clothingWarm = 28;
  static const double clothingComfortable = 21;
  static const double clothingCool = 14;
  static const double clothingCold = 7;
  static const double clothingFreezing = -5;

  static const double makeupHot = 30;
  static const double makeupWarm = 20;
  static const double makeupCool = 10;

  static const double humidityDry = 40;
  static const double humidityHumid = 70;

  static const double windStrong = 30;
  static const double windVeryStrong = 40;

  static const double coldHighRisk = 5;
  static const double coldMediumRisk = 15;
  static const double coldLowRisk = 25;

  static const double exerciseExtremeCold = -10;
  static const double exerciseExtremeHot = 38;
  static const double exerciseVeryCold = 0;
  static const double exerciseVeryHot = 35;
  static const double exerciseCool = 10;
  static const double exerciseWarm = 30;

  static const int wmoRainStart = 51;
  static const int wmoRainEnd = 67;
  static const int wmoSnowStart = 71;
  static const int wmoSnowEnd = 86;
  static const int wmoPrecipEnd = 82;
  static const int wmoFogStart = 45;
  static const int wmoFogEnd = 48;
  static const int wmoStormStart = 95;
}
