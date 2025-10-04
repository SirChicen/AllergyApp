import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/analysis_result.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'allerai.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE analysis_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurant_name TEXT,
        user_menu_name TEXT,
        image_path TEXT,
        analysis_data TEXT NOT NULL,
        analyzed_at TEXT NOT NULL,
        user_allergens TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE analysis_history ADD COLUMN user_menu_name TEXT');
    }
  }

  Future<int> saveAnalysis({
    required AnalysisResult result,
    required String imagePath,
    required List<String> userAllergens,
    String? restaurantName,
    String? userMenuName,
  }) async {
    final db = await database;
    
    return await db.insert('analysis_history', {
      'restaurant_name': restaurantName,
      'user_menu_name': userMenuName,
      'image_path': imagePath,
      'analysis_data': jsonEncode(result.toJson()),
      'analyzed_at': result.analyzedAt.toIso8601String(),
      'user_allergens': jsonEncode(userAllergens),
    });
  }

  Future<List<AnalysisHistory>> getAnalysisHistory() async {
    final db = await database;
    final maps = await db.query(
      'analysis_history',
      orderBy: 'analyzed_at DESC',
    );

    return maps.map((map) => AnalysisHistory.fromMap(map)).toList();
  }

  Future<void> deleteAnalysis(int id) async {
    final db = await database;
    await db.delete(
      'analysis_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('analysis_history');
  }

  Future<void> updateMenuName(int id, String userMenuName) async {
    final db = await database;
    await db.update(
      'analysis_history',
      {'user_menu_name': userMenuName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class AnalysisHistory {
  final int id;
  final String? restaurantName;
  final String? userMenuName;
  final String imagePath;
  final AnalysisResult analysisResult;
  final DateTime analyzedAt;
  final List<String> userAllergens;

  AnalysisHistory({
    required this.id,
    this.restaurantName,
    this.userMenuName,
    required this.imagePath,
    required this.analysisResult,
    required this.analyzedAt,
    required this.userAllergens,
  });

  factory AnalysisHistory.fromMap(Map<String, dynamic> map) {
    return AnalysisHistory(
      id: map['id'],
      restaurantName: map['restaurant_name'],
      userMenuName: map['user_menu_name'],
      imagePath: map['image_path'],
      analysisResult: AnalysisResult.fromJson(jsonDecode(map['analysis_data'])),
      analyzedAt: DateTime.parse(map['analyzed_at']),
      userAllergens: List<String>.from(jsonDecode(map['user_allergens'])),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_name': restaurantName,
      'user_menu_name': userMenuName,
      'image_path': imagePath,
      'analysis_data': jsonEncode(analysisResult.toJson()),
      'analyzed_at': analyzedAt.toIso8601String(),
      'user_allergens': jsonEncode(userAllergens),
    };
  }

}