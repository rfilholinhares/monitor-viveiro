// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leitura_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LeituraAdapter extends TypeAdapter<Leitura> {
  @override
  final int typeId = 1;

  @override
  Leitura read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Leitura(
      id: fields[0] as String,
      idTanque: fields[1] as String,
      dataHora: fields[2] as DateTime,
      oxigenio: fields[3] as double,
      temperatura: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Leitura obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.idTanque)
      ..writeByte(2)
      ..write(obj.dataHora)
      ..writeByte(3)
      ..write(obj.oxigenio)
      ..writeByte(4)
      ..write(obj.temperatura);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeituraAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
