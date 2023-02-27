// GENERATED CODE - DO NOT MODIFY BY HAND

part of painter;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Point _$PointFromJson(Map<String, dynamic> json) {
  return Point(
    (json['x'] as num).toDouble(),
    (json['y'] as num).toDouble(),
  );
}

Map<String, dynamic> _$PointToJson(Point instance) => <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

PathHistoryEntry _$PathHistoryEntryFromJson(Map<String, dynamic> json) {
  return PathHistoryEntry(
    (json['pathDx'] as num).toDouble(),
    (json['pathDy'] as num).toDouble(),
    json['paintA'] as int,
    json['paintR'] as int,
    json['paintG'] as int,
    json['paintB'] as int,
    json['paintBlendMode'] as int,
    (json['paintThickness'] as num).toDouble(),
  )..lineToList = (json['lineToList'] as List)
      .map((e) => Point.fromJson(e as Map<String, dynamic>))
      .toList();
}

Map<String, dynamic> _$PathHistoryEntryToJson(PathHistoryEntry instance) =>
    <String, dynamic>{
      'pathDx': instance.pathDx,
      'pathDy': instance.pathDy,
      'lineToList': instance.lineToList,
      'paintA': instance.paintA,
      'paintR': instance.paintR,
      'paintG': instance.paintG,
      'paintB': instance.paintB,
      'paintBlendMode': instance.paintBlendMode,
      'paintThickness': instance.paintThickness,
    };
