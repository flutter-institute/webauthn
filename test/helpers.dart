import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:webauthn/src/db/db.dart';

/// Initialize sqflite for tests
void sqfliteTestInit() {
  DB.mockDirectory = Directory.systemTemp.path;

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Uint8List ui(List<int> list) => Uint8List.fromList(list);

ByteBuffer bb(List<int> list) => Uint8List.fromList(list).buffer;

List<int> li(ByteBuffer bb) => Uint8List.view(bb).toList();
