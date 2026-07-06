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
    _database = await _initDB('freshmarket_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // 🌐 KONFIGURASI KHUSUS JIKA DIJALANKAN DI CHROME (WEB)
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    } else {
      // 📱 KONFIGURASI ASLI UNTUK HP (ANDROID/IOS)
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(path, version: 1, onCreate: _createDB);
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
     image TEXT NOT NULL 
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

    await db.execute('''
   CREATE TABLE vouchers (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     code TEXT NOT NULL,
     discount INTEGER NOT NULL
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
  }
}