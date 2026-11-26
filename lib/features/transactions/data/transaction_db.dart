import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../categories/data/category_model.dart';
import 'transaction_model.dart';

/// SQLite data-access layer for transactions and categories.
class TransactionDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'sakuwashi.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            category TEXT NOT NULL,
            note TEXT DEFAULT '',
            date TEXT NOT NULL
          )
        ''');
        await _createCategoriesTable(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCategoriesTable(db);
          await _seedDefaultCategories(db);
        }
      },
    );
    return _db!;
  }

  static Future<void> _createCategoriesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _seedDefaultCategories(DatabaseExecutor db) async {
    final existing = await db.query('categories', limit: 1);
    if (existing.isNotEmpty) return;

    final batch = db.batch();

    // Default Expense Categories
    const expenseDefaults = [
      ('Makan & Minum', 'restaurant', 0),
      ('Transportasi', 'directions_car', 1),
      ('Tagihan', 'receipt_long', 2),
      ('Belanja', 'shopping_bag', 3),
      ('Hiburan', 'movie', 4),
      ('Lainnya', 'more_horiz', 9999),
    ];
    for (final (name, iconKey, sortOrder) in expenseDefaults) {
      batch.insert('categories', {
        'name': name,
        'type': 'expense',
        'icon_key': iconKey,
        'is_default': 1,
        'sort_order': sortOrder,
      });
    }

    // Default Income Categories
    const incomeDefaults = [
      ('Gaji', 'account_balance_wallet', 0),
      ('Freelance', 'work', 1),
      ('Bonus', 'card_giftcard', 2),
      ('Investasi', 'trending_up', 3),
      ('Lainnya', 'more_horiz', 9999),
    ];
    for (final (name, iconKey, sortOrder) in incomeDefaults) {
      batch.insert('categories', {
        'name': name,
        'type': 'income',
        'icon_key': iconKey,
        'is_default': 1,
        'sort_order': sortOrder,
      });
    }

    await batch.commit(noResult: true);
  }

  // ── CATEGORIES CRUD ──────────────────────────────────────

  /// Fetch categories by type ('expense' | 'income').
  /// Ensures 'Lainnya' is ALWAYS at the very end of the list.
  static Future<List<CategoryModel>> getCategories(String type) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy:
          "CASE WHEN name = 'Lainnya' THEN 1 ELSE 0 END, sort_order ASC, id ASC",
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Fetch all categories across all types.
  static Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      orderBy:
          "type ASC, CASE WHEN name = 'Lainnya' THEN 1 ELSE 0 END, sort_order ASC, id ASC",
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Insert a new custom category.
  static Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  /// Update an existing category.
  /// If [oldName] is provided and changed, updates all corresponding transactions.
  static Future<int> updateCategory(
    CategoryModel category, {
    String? oldName,
  }) async {
    final db = await database;
    final res = await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );

    if (oldName != null && oldName != category.name) {
      await db.update(
        'transactions',
        {'category': category.name},
        where: 'category = ? AND type = ?',
        whereArgs: [oldName, category.type],
      );
    }
    return res;
  }

  /// Delete a custom category (`is_default == 0`).
  /// All associated transactions are automatically re-assigned to 'Lainnya'.
  static Future<int> deleteCategory(
    int id,
    String categoryName,
    String type,
  ) async {
    final db = await database;
    // Re-assign existing transactions to 'Lainnya'
    await db.update(
      'transactions',
      {'category': 'Lainnya'},
      where: 'category = ? AND type = ?',
      whereArgs: [categoryName, type],
    );

    // Only non-default categories can be deleted
    return db.delete(
      'categories',
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }

  /// Count how many transactions currently reference [categoryName] with [type].
  static Future<int> countTransactionsByCategory(
    String categoryName,
    String type,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE category = ? AND type = ?',
      [categoryName, type],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Ensure a category with [name] and [type] exists in the categories table.
  /// If it does not exist, insert it as a new custom category with fallback icon.
  static Future<void> ensureCategoryExists(String name, String type) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final db = await database;
    final existing = await db.query(
      'categories',
      where: 'LOWER(name) = ? AND type = ?',
      whereArgs: [trimmedName.toLowerCase(), type],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('categories', {
        'name': trimmedName,
        'type': type,
        'icon_key': 'more_horiz',
        'is_default': 0,
        'sort_order': 50,
      });
    }
  }

  // ── TRANSACTIONS CRUD ────────────────────────────────────
  static Future<int> insert(TransactionModel txn) async {
    final db = await database;
    return db.insert('transactions', txn.toMap());
  }

  static Future<int> update(TransactionModel txn) async {
    final db = await database;
    return db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  static Future<int> delete(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Fetch transactions filtered by type and month.
  static Future<List<TransactionModel>> getByTypeAndMonth(
    String type,
    int year,
    int month,
  ) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      'transactions',
      where: 'type = ? AND date >= ? AND date < ?',
      whereArgs: [type, start, end],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// Fetch all transactions for a given month (both types).
  static Future<List<TransactionModel>> getByMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// Fetch ALL transactions (for CSV export / backup).
  static Future<List<TransactionModel>> getAll() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// Fetch transactions within an arbitrary date range [start, end).
  /// If [end] is null, fetches all transactions from [start] onwards (open-ended).
  static Future<List<TransactionModel>> getByDateRange(
    DateTime start,
    DateTime? end, {
    String? type,
    String? query,
  }) async {
    final db = await database;
    final conditions = <String>['date >= ?'];
    final args = <Object?>[start.toIso8601String()];

    if (end != null) {
      conditions.add('date < ?');
      args.add(end.toIso8601String());
    }
    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }
    if (query != null && query.isNotEmpty) {
      conditions.add('(note LIKE ? OR category LIKE ?)');
      args.add('%$query%');
      args.add('%$query%');
    }

    final maps = await db.query(
      'transactions',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// Fetch transactions for a full calendar year.
  static Future<List<TransactionModel>> getByYear(int year) async {
    return getByDateRange(
      DateTime(year, 1, 1),
      DateTime(year + 1, 1, 1),
    );
  }

  /// Count transactions in a date range.
  static Future<int> countByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE date >= ? AND date < ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Count all transactions.
  static Future<int> countAll() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Search by note or category.
  static Future<List<TransactionModel>> search(
    String query,
    String type,
    int year,
    int month,
  ) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      'transactions',
      where:
          'type = ? AND date >= ? AND date < ? AND (note LIKE ? OR category LIKE ?)',
      whereArgs: [type, start, end, '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// Bulk insert (for restore). Returns count inserted.
  static Future<int> bulkInsert(List<TransactionModel> txns) async {
    final db = await database;
    final batch = db.batch();
    for (final txn in txns) {
      batch.insert(
        'transactions',
        txn.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    final results = await batch.commit();
    return results.length;
  }

  /// Clear all data (for full restore replacement).
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }
}
