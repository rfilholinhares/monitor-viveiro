// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turno_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TurnoAdapter extends TypeAdapter<Turno> {
  @override
  final int typeId = 2;

  @override
  Turno read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Turno(
      id: fields[0] as String,
      dataHoraInicio: fields[1] as DateTime,
      dataHoraFim: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Turno obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dataHoraInicio)
      ..writeByte(2)
      ..write(obj.dataHoraFim);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurnoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
