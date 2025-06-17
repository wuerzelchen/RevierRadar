// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'district_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DistrictAdapter extends TypeAdapter<District> {
  @override
  final int typeId = 0;

  @override
  District read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return District.hive(
      name: fields[0] as String,
      points: (fields[1] as List).cast<LatLngSerializable>(),
      colorValue: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, District obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.points)
      ..writeByte(2)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LatLngSerializableAdapter extends TypeAdapter<LatLngSerializable> {
  @override
  final int typeId = 1;

  @override
  LatLngSerializable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatLngSerializable(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LatLngSerializable obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngSerializableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
