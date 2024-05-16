import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('voterprofile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE profiles(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  documentNumber TEXT NOT NULL,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  dateOfBirth TEXT NOT NULL,
  nationality TEXT NOT NULL,
  dateOfExpiry TEXT NOT NULL,
  imageData BLOB,
  signatureData BLOB
)
''');
  }

  Future<int> insertProfile(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('profiles', row);
  }

  Future<Map<String, dynamic>?> getProfile(int id) async {
    final db = await instance.database;
    final results = await db.query(
        'profiles',
        where: 'id = ?',
        whereArgs: [id],
        columns: ['documentNumber', 'firstName', 'lastName', 'dateOfBirth', 'nationality', 'dateOfExpiry', 'imageData', 'signatureData']
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
  Future<Map<String, dynamic>?> getLastProfile() async {
    final db = await instance.database;
    final results = await db.query(
      'profiles',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

}

