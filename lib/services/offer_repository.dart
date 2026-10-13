import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/offer.dart';

/// Archivio locale delle offerte (SQLite sul telefono).
class OfferRepository {
  Database? _db;

  Future<Database> get _database async {
    return _db ??= await openDatabase(
      p.join(await getDatabasesPath(), 'offerte.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE offers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_name TEXT NOT NULL,
            canonical_name TEXT NOT NULL,
            brand TEXT,
            category TEXT NOT NULL,
            store TEXT NOT NULL,
            price REAL NOT NULL,
            original_price REAL,
            quantity REAL,
            unit TEXT,
            valid_from TEXT,
            valid_until TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_offers_canonical ON offers(canonical_name)');
      },
    );
  }

  Future<List<Offer>> getAll() async {
    final db = await _database;
    final rows = await db.query('offers', orderBy: 'created_at DESC');
    return rows.map(Offer.fromMap).toList();
  }

  Future<void> insertAll(List<Offer> offers) async {
    final db = await _database;
    final batch = db.batch();
    for (final o in offers) {
      final map = o.toMap()..remove('id');
      batch.insert('offers', map);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('offers', where: 'id = ?', whereArgs: [id]);
  }

  /// Cancella le offerte scadute da più di [olderThanDays] giorni.
  /// Le offerte recenti restano per lo storico dei prezzi.
  Future<int> deleteExpired({int olderThanDays = 180}) async {
    final db = await _database;
    final limit = DateTime.now().subtract(Duration(days: olderThanDays)).toIso8601String();
    return db.delete('offers', where: 'valid_until IS NOT NULL AND valid_until < ?', whereArgs: [limit]);
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete('offers');
  }
}
