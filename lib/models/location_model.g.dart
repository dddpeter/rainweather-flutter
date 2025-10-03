// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) =>
    LocationModel(
      address: json['address'] as String,
      country: json['country'] as String,
      province: json['province'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      street: json['street'] as String,
      adcode: json['adcode'] as String,
      town: json['town'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$LocationModelToJson(LocationModel instance) =>
    <String, dynamic>{
      'address': instance.address,
      'country': instance.country,
      'province': instance.province,
      'city': instance.city,
      'district': instance.district,
      'street': instance.street,
      'adcode': instance.adcode,
      'town': instance.town,
      'lat': instance.lat,
      'lng': instance.lng,
    };
