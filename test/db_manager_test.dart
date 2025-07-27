import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:todo_list/db_manager.dart';
import 'package:todo_list/models/task.dart';

void main() {
  late TaskManager taskManager;
  late String testDbPath;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    taskManager = TaskManager();

    // Create a unique test database path for each test
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    testDbPath = join(await getDatabasesPath(), 'test_todo_$timestamp.db');

    // Override the database ID for testing
    // Note: This would require making db_id non-final in the actual implementation
    // For now, we'll work with the existing structure
  });

  tearDown(() async {
    // Clean up: close database and delete test file
    try {
      if (await File(
        join(await getDatabasesPath(), 'todo_app_database.db'),
      ).exists()) {
        await deleteDatabase(
          join(await getDatabasesPath(), 'todo_app_database.db'),
        );
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('Database Initialization Tests', () {
    test('should create database on first initialization', () async {
      // Arrange
      final dbPath = join(await getDatabasesPath(), 'todo_app_database.db');
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }

      // Act
      await taskManager.createDatabase();
      final exists = await taskManager.databaseExists();

      // Assert
      expect(exists, true);
    });

    test('should detect existing database', () async {
      // Arrange
      await taskManager.createDatabase();

      // Act
      final exists = await taskManager.databaseExists();

      // Assert
      expect(exists, true);
    });

    test('should return false for non-existent database', () async {
      // Arrange
      final dbPath = join(await getDatabasesPath(), 'todo_app_database.db');
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }

      // Act
      final exists = await taskManager.databaseExists();

      // Assert
      expect(exists, false);
    });
  });

  group('Database Reset Tests', () {
    test('should reset database successfully', () async {
      // Arrange
      await taskManager.createDatabase();
      final task = Task(
        listId: 1,
        title: 'Test Task Before Reset',
        description: 'This should be deleted after reset',
      );
      await taskManager.insertTask(task);

      // Verify task exists before reset
      final tasksBeforeReset = await taskManager.getTasks();
      expect(tasksBeforeReset.length, 1);

      // Act
      await taskManager.resetDatabase();

      // Assert
      final tasksAfterReset = await taskManager.getTasks();
      expect(tasksAfterReset.length, 0);
      expect(await taskManager.databaseExists(), true);
    });
  });

  group('Task CRUD Operations Tests', () {
    setUp(() async {
      await taskManager.createDatabase();
    });

    test('should insert a task successfully', () async {
      // Arrange
      final task = Task(
        listId: 1,
        title: 'Test Task',
        description: 'Test Description',
      );

      // Act
      await taskManager.insertTask(task);
      final tasks = await taskManager.getTasks();

      // Assert
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Test Task');
      expect(tasks.first.description, 'Test Description');
      expect(tasks.first.listId, 1);
      expect(tasks.first.isCompleted, false);
    });

    test('should insert multiple tasks successfully', () async {
      // Arrange
      final task1 = Task(listId: 1, title: 'Task 1');
      final task2 = Task(listId: 1, title: 'Task 2');
      final task3 = Task(listId: 1, title: 'Task 3');

      // Act
      await taskManager.insertTask(task1);
      await taskManager.insertTask(task2);
      await taskManager.insertTask(task3);
      final tasks = await taskManager.getTasks();

      // Assert
      expect(tasks.length, 3);
      expect(tasks.map((t) => t.title).toList(), [
        'Task 1',
        'Task 2',
        'Task 3',
      ]);
    });

    test('should retrieve all tasks', () async {
      // Arrange
      final tasks = [
        Task(listId: 1, title: 'Task 1', isCompleted: false),
        Task(listId: 1, title: 'Task 2', isCompleted: true),
        Task(listId: 2, title: 'Task 3', description: 'With description'),
      ];

      for (final task in tasks) {
        await taskManager.insertTask(task);
      }

      // Act
      final retrievedTasks = await taskManager.getTasks();

      // Assert
      expect(retrievedTasks.length, 3);
      expect(retrievedTasks.where((t) => t.isCompleted).length, 1);
      expect(retrievedTasks.where((t) => t.description != null).length, 1);
    });

    test('should update a task successfully', () async {
      // Arrange
      final originalTask = Task(
        listId: 1,
        title: 'Original Title',
        description: 'Original Description',
        isCompleted: false,
      );
      await taskManager.insertTask(originalTask);

      final tasks = await taskManager.getTasks();
      final insertedTask = tasks.first;

      final updatedTask = Task(
        id: insertedTask.id,
        listId: insertedTask.listId,
        title: 'Updated Title',
        description: 'Updated Description',
        isCompleted: true,
        createdAt: insertedTask.createdAt,
        updatedAt: DateTime.now(),
      );

      // Act
      await taskManager.updateTask(updatedTask);
      final updatedTasks = await taskManager.getTasks();

      // Assert
      expect(updatedTasks.length, 1);
      final result = updatedTasks.first;
      expect(result.title, 'Updated Title');
      expect(result.description, 'Updated Description');
      expect(result.isCompleted, true);
      expect(result.id, insertedTask.id);
    });

    test('should delete a task successfully', () async {
      // Arrange
      final task1 = Task(listId: 1, title: 'Task 1');
      final task2 = Task(listId: 1, title: 'Task 2');

      await taskManager.insertTask(task1);
      await taskManager.insertTask(task2);

      final tasksBeforeDelete = await taskManager.getTasks();
      expect(tasksBeforeDelete.length, 2);

      final taskToDelete = tasksBeforeDelete.first;

      // Act
      await taskManager.deleteTask(taskToDelete.id!);
      final tasksAfterDelete = await taskManager.getTasks();

      // Assert
      expect(tasksAfterDelete.length, 1);
      expect(tasksAfterDelete.first.title, 'Task 2');
    });

    test('should handle empty task list', () async {
      // Act
      final tasks = await taskManager.getTasks();

      // Assert
      expect(tasks, isEmpty);
    });

    test('should preserve task creation and update timestamps', () async {
      // Arrange
      final now = DateTime.now();
      final task = Task(
        listId: 1,
        title: 'Timestamp Test',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await taskManager.insertTask(task);
      final retrievedTasks = await taskManager.getTasks();

      // Assert
      final retrievedTask = retrievedTasks.first;
      expect(
        retrievedTask.createdAt.millisecondsSinceEpoch,
        closeTo(now.millisecondsSinceEpoch, 1000),
      ); // Within 1 second
      expect(
        retrievedTask.updatedAt.millisecondsSinceEpoch,
        closeTo(now.millisecondsSinceEpoch, 1000),
      ); // Within 1 second
    });
  });

  group('Task Model Tests', () {
    test('should handle task with due date', () async {
      // Arrange
      await taskManager.createDatabase();
      final dueDate = DateTime.now().add(const Duration(days: 7));
      final task = Task(
        listId: 1,
        title: 'Task with due date',
        dueDate: dueDate,
      );

      // Act
      await taskManager.insertTask(task);
      final tasks = await taskManager.getTasks();

      // Assert
      final retrievedTask = tasks.first;
      expect(retrievedTask.dueDate, isNotNull);
      expect(retrievedTask.dueDate!.day, dueDate.day);
    });

    test('should handle task without description', () async {
      // Arrange
      await taskManager.createDatabase();
      final task = Task(listId: 1, title: 'Task without description');

      // Act
      await taskManager.insertTask(task);
      final tasks = await taskManager.getTasks();

      // Assert
      final retrievedTask = tasks.first;
      expect(retrievedTask.description, isNull);
    });

    test('should handle task with empty description', () async {
      // Arrange
      await taskManager.createDatabase();
      final task = Task(
        listId: 1,
        title: 'Task with empty description',
        description: '',
      );

      // Act
      await taskManager.insertTask(task);
      final tasks = await taskManager.getTasks();

      // Assert
      final retrievedTask = tasks.first;
      expect(retrievedTask.description, '');
    });
  });

  group('Error Handling Tests', () {
    test('should handle database operations after reset', () async {
      // Arrange
      await taskManager.createDatabase();
      await taskManager.resetDatabase();

      // Act & Assert - should not throw
      final task = Task(listId: 1, title: 'After Reset');
      await taskManager.insertTask(task);
      final tasks = await taskManager.getTasks();

      expect(tasks.length, 1);
      expect(tasks.first.title, 'After Reset');
    });

    test('should handle updating non-existent task gracefully', () async {
      // Arrange
      await taskManager.createDatabase();
      final nonExistentTask = Task(
        id: 999999, // Non-existent ID
        listId: 1,
        title: 'Non-existent task',
      );

      // Act & Assert - should not throw
      await taskManager.updateTask(nonExistentTask);
      final tasks = await taskManager.getTasks();
      expect(tasks.length, 0);
    });

    test('should handle deleting non-existent task gracefully', () async {
      // Arrange
      await taskManager.createDatabase();

      // Act & Assert - should not throw
      await taskManager.deleteTask(999999); // Non-existent ID
      final tasks = await taskManager.getTasks();
      expect(tasks.length, 0);
    });
  });

  group('Task Model Validation Tests', () {
    test('should create task with minimal required fields', () {
      // Act
      final task = Task(listId: 1, title: 'Minimal Task');

      // Assert
      expect(task.listId, 1);
      expect(task.title, 'Minimal Task');
      expect(task.description, isNull);
      expect(task.isCompleted, false);
      expect(task.dueDate, isNull);
      expect(task.createdAt, isA<DateTime>());
      expect(task.updatedAt, isA<DateTime>());
    });

    test('should serialize and deserialize task correctly', () {
      // Arrange
      final originalTask = Task(
        id: 1,
        listId: 2,
        title: 'Serialization Test',
        description: 'Test Description',
        isCompleted: true,
        dueDate: DateTime(2024, 12, 25),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      // Act
      final map = originalTask.toMap();
      final deserializedTask = Task.fromMap(map);

      // Assert
      expect(deserializedTask.id, originalTask.id);
      expect(deserializedTask.listId, originalTask.listId);
      expect(deserializedTask.title, originalTask.title);
      expect(deserializedTask.description, originalTask.description);
      expect(deserializedTask.isCompleted, originalTask.isCompleted);
      expect(deserializedTask.dueDate?.day, originalTask.dueDate?.day);
      expect(deserializedTask.createdAt.day, originalTask.createdAt.day);
      expect(deserializedTask.updatedAt.day, originalTask.updatedAt.day);
    });
  });
}
