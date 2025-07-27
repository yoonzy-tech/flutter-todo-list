import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/task.dart';

const String DB_ID = 'todo_app_database.db';
const String TASK_TABLE_ID = 'tasks';

class TaskManager {
  // create a single instance from the private constructor
  static final TaskManager _instance = TaskManager._internal();

  // public factory constructor 
  // Every time you call TaskManager(), this line is executed and it returns the already-created instance (_instance from line 13).
  factory TaskManager() => _instance;

  // private constructor
  TaskManager._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Check if database exists
  Future<bool> databaseExists() async {
    final dbPath = join(await getDatabasesPath(), DB_ID);
    return File(dbPath).exists();
  }

  Future<Database> _initDatabase() async {
    print('db_location: ${await getDatabasesPath()}');

    return openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), DB_ID),
      // When the database is first created, create a table to store tasks.
      onCreate: (db, version) {
        print('Creating database tables for the first time...');
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE $TASK_TABLE_ID(id INTEGER PRIMARY KEY, list_id INTEGER, title TEXT, description TEXT, is_completed INTEGER, due_date TEXT, created_at TEXT, updated_at TEXT)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  Future<void> createDatabase() async {
    final exists = await databaseExists();
    if (exists) {
      print('Database already exists, connecting to existing database...');
    } else {
      print('First time app launch - creating new database...');
    }
    await database; // This will initialize the database
  }

  // Method to close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Method to reset the database (useful for development)
  Future<void> resetDatabase() async {
    final dbPath = join(await getDatabasesPath(), DB_ID);

    // Close existing database connection if it exists
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the database file
    await deleteDatabase(dbPath);
    print('Database reset - will be recreated');

    // Reinitialize the database
    await database;
    print('Reinitializing database');
  }

  // Define a function that inserts tasks into the database
  Future<void> insertTask(Task task) async {
    // Get a reference to the database.
    final db = await database;

    await db.insert(
      // Insert the task into the correct table. You might also specify the
      // `conflictAlgorithm` to use in case the same task is inserted twice.
      //
      // In this case, replace any previous data.
      TASK_TABLE_ID,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // A method that retrieves all the tasks from the tasks table.
  Future<List<Task>> getTasks() async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all the tasks.
    final List<Map<String, Object?>> taskMaps = await db.query(TASK_TABLE_ID);

    // Convert the list of each task's fields into a list of `task` objects.
    return taskMaps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    // Get a reference to the database.
    final db = await database;

    // Update the given Task.
    await db.update(
      TASK_TABLE_ID,
      task.toMap(),
      // Ensure that the Task has a matching id.
      where: 'id = ?',
      // Pass the Task's id as a whereArg to prevent SQL injection.
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the Task from the database.
    await db.delete(
      TASK_TABLE_ID,
      // Use a `where` clause to delete a specific task.
      where: 'id = ?',
      // Pass the Task's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }
}
