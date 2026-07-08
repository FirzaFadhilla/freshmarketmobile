import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk mendeteksi apakah jalan di Chrome
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Jembatan khusus Web

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('freshmarket_v6.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // 🌐 KONFIGURASI KHUSUS JIKA DIJALANKAN DI CHROME (WEB)
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
    } else {
      // 📱 KONFIGURASI ASLI UNTUK HP (ANDROID/IOS)
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE products ADD COLUMN type TEXT NOT NULL DEFAULT 'Lokal'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'kg'");
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL 
      )
    ''');

    // 2. Tabel Products
    await db.execute('''
   CREATE TABLE products (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     name TEXT NOT NULL,
     price INTEGER NOT NULL,
     stock INTEGER NOT NULL,
     image TEXT NOT NULL,
     type TEXT NOT NULL DEFAULT 'Lokal',
     unit TEXT NOT NULL DEFAULT 'kg'
   )
 ''');

    // 3. Tabel Cart
    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // 4. Tabel Vouchers
    await db.execute('''
   CREATE TABLE vouchers (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     code TEXT NOT NULL,
     discount INTEGER NOT NULL
   )
  ''');

    // 5. Tabel Transactions
    await db.execute('''
   CREATE TABLE transactions (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     total_price INTEGER NOT NULL,
     discount INTEGER NOT NULL DEFAULT 0,
     date TEXT NOT NULL
   )
  ''');

    // 6. Tabel Orders
    await db.execute('''
   CREATE TABLE orders (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     user_email TEXT NOT NULL,
     total_price INTEGER NOT NULL,
     payment_method TEXT NOT NULL,
     status TEXT NOT NULL,
     date TEXT NOT NULL,
     items_json TEXT NOT NULL
   )
  ''');

    // 1. Buat Akun Admin Bawaan
    await db.insert('users', {
      'email': 'admin@gmail.com',
      'password': 'admin',
      'role': 'admin'
    });

    // 2. Buat Akun Kasir Bawaan
    await db.insert('users', {
      'email': 'kasir@gmail.com',
      'password': 'kasir',
      'role': 'kasir'
    });

    // 3. Buat Akun Customer Bawaan
    await db.insert('users', {
      'email': 'user@gmail.com',
      'password': 'user',
      'role': 'customer'
    });

    // 4. Tambah Transaksi Bawaan untuk Demo Grafik Dashboard
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    final twoDaysAgoStr = DateTime.now().subtract(const Duration(days: 2)).toIso8601String().split('T')[0];

    await db.insert('transactions', {
      'total_price': 45000,
      'discount': 5000,
      'date': twoDaysAgoStr
    });
    await db.insert('transactions', {
      'total_price': 120000,
      'discount': 10000,
      'date': yesterdayStr
    });
    await db.insert('transactions', {
      'total_price': 85000,
      'discount': 0,
      'date': todayStr
    });
  }
}