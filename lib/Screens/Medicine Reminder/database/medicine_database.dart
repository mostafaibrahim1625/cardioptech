import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Medicine {
  final int? id;
  final String name;
  final String dose;
  final String shape;
  final String time;
  final String usageInstructions;
  final String image;
  final DateTime createdAt;
  final bool notificationsEnabled;
  final int? notificationId;

  Medicine({
    this.id,
    required this.name,
    required this.dose,
    required this.shape,
    required this.time,
    required this.usageInstructions,
    required this.image,
    required this.createdAt,
    this.notificationsEnabled = true,
    this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'dose': dose,
      'shape': shape,
      'time': time,
      'usage_instructions': usageInstructions,
      'image': image,
      'created_at': createdAt.millisecondsSinceEpoch,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'notification_id': notificationId,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      dose: map['dose'],
      shape: map['shape'] ?? '',
      time: map['time'] ?? '',
      usageInstructions: map['usage_instructions'] ?? '',
      image: map['image'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      notificationsEnabled: (map['notifications_enabled'] ?? 1) == 1,
      notificationId: map['notification_id'],
    );
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? dose,
    String? shape,
    String? time,
    String? usageInstructions,
    String? image,
    DateTime? createdAt,
    bool? notificationsEnabled,
    int? notificationId,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      shape: shape ?? this.shape,
      time: time ?? this.time,
      usageInstructions: usageInstructions ?? this.usageInstructions,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}

class MedicineDatabase {
  static final MedicineDatabase _instance = MedicineDatabase._internal();
  factory MedicineDatabase() => _instance;
  MedicineDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      print('Initializing database...');
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'medicines.db');
      print('Database path: $path');

      final database = await openDatabase(
        path,
        version: 3, // Increment version to trigger migration
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      print('Database initialized successfully');
      return database;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        shape TEXT,
        time TEXT,
        usage_instructions TEXT,
        image TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        notifications_enabled INTEGER DEFAULT 1,
        notification_id INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add new columns to existing table
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN shape TEXT');
        print('Added shape column');
      } catch (e) {
        print('Shape column might already exist: $e');
      }
      
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN time TEXT');
        print('Added time column');
      } catch (e) {
        print('Time column might already exist: $e');
      }
      
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN usage_instructions TEXT');
        print('Added usage_instructions column');
      } catch (e) {
        print('Usage_instructions column might already exist: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Add notification-related columns
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN notifications_enabled INTEGER DEFAULT 1');
        print('Added notifications_enabled column');
      } catch (e) {
        print('Notifications_enabled column might already exist: $e');
      }
      
      try {
        await db.execute('ALTER TABLE medicines ADD COLUMN notification_id INTEGER');
        print('Added notification_id column');
      } catch (e) {
        print('Notification_id column might already exist: $e');
      }
    }
  }

  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return await db.insert('medicines', medicine.toMap());
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Medicine.fromMap(maps[i]);
    });
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final db = await database;
    return await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    final db = await database;
    return await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllMedicines() async {
    final db = await database;
    await db.delete('medicines');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Method to force database recreation (useful for testing)
  Future<void> recreateDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'medicines.db');
    await deleteDatabase(path);
    _database = await _initDatabase();
  }
}
