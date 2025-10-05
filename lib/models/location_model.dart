import 'package:json_annotation/json_annotation.dart';

part 'location_model.g.dart';

@JsonSerializable()
class LocationModel {
  final String address;
  final String country;
  final String province;
  final String city;
  final String district;
  final String street;
  final String adcode;
  final String town;
  final double lat;
  final double lng;

  /// Indicates if this location might be from a proxy/VPN
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isProxyDetected;

  LocationModel({
    required this.address,
    required this.country,
    required this.province,
    required this.city,
    required this.district,
    required this.street,
    required this.adcode,
    required this.town,
    required this.lat,
    required this.lng,
    this.isProxyDetected = false,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);

  @override
  String toString() {
    return 'LocationModel(district: $district, city: $city, province: $province)';
  }
}
