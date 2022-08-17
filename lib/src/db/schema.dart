import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

abstract class DBSchema<S extends SchemaObject> {
  DBSchema([DB? db]) : _db = db ?? const DB();

  final DB _db;

  Transaction? _activeTransaction;

  /// Start or nest a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    late T result;
    if (_activeTransaction == null) {
      // Start a new transaction
      final conn = await _db.open();
      result = await conn.transaction((txn) async {
        _activeTransaction = txn;
        return action(txn);
      });
      _activeTransaction = null;
      if (conn.isOpen) await conn.close();
    } else {
      // Execute the action using the currently open transaction
      result = await action(_activeTransaction!);
    }

    return result;
  }

  /// Execute a query on a new connection or the active transaction
  Future<T> execute<T>(Future<T> Function(DatabaseExecutor conn) action) async {
    late T result;
    if (_activeTransaction == null) {
      // Start a new connection
      final conn = await _db.open();
      result = await action(conn);
      if (conn.isOpen) await conn.close();
    } else {
      // Execute the action using the currently open transaction
      result = await action(_activeTransaction!);
    }

    return result;
  }

  /// Insert a new object, returning the object that was created
  Future<S> insert(S data);

  /// Update an object, returning `true` if updates happened
  Future<bool> update(S data);

  /// Delete an object by ID, returning `true` if delete happened
  Future<bool> delete(int id);

  /// Get an object by primary key, returning `null` if not found
  Future<S?> getById(int id);
}

abstract class SchemaObject extends Equatable {
  // ignore: prefer_const_constructors_in_immutables
  SchemaObject(this.id);

  late final int? id;
}
