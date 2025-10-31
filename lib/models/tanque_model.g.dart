// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tanque_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TanqueAdapter extends TypeAdapter<Tanque> {
  @override
  final int typeId = 0;

  @override
  Tanque read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tanque(
      id: fields[0] as String,
      nome: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Tanque obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TanqueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
