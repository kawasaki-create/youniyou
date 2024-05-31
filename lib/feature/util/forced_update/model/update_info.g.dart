// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UpdateInfoImpl _$$UpdateInfoImplFromJson(Map<String, dynamic> json) =>
    _$UpdateInfoImpl(
      latestVersion: json['latestVersion'] as String,
      requiredVersion: json['requiredVersion'] as String,
      enabledAt: DateTime.parse(json['enabledAt'] as String),
    );

Map<String, dynamic> _$$UpdateInfoImplToJson(_$UpdateInfoImpl instance) =>
    <String, dynamic>{
      'latestVersion': instance.latestVersion,
      'requiredVersion': instance.requiredVersion,
      'enabledAt': instance.enabledAt.toIso8601String(),
    };
