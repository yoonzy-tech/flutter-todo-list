import 'package:flutter/material.dart';
import 'db_manager.dart';
import 'models/task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TodoListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TaskManager _taskManager = TaskManager();
  List<Task> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      print('Initializing database...');
      await _taskManager.createDatabase();
      await _loadTasks();
    } catch (e) {
      print('Database initialization error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing database: $e')),
        );
      }
    }
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);
      final tasks = await _taskManager.getTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tasks: $e')));
      }
      print('Error loading tasks: $e');
    }
  }

  Future<void> _addTask(String title, String? description) async {
    if (title.trim().isEmpty) return;

    final newTask = Task(
      listId: 1, // Default list ID
      title: title.trim(),
      description: description?.trim(),
    );

    try {
      await _taskManager.insertTask(newTask);
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding task: $e')));
      }
      print('Error adding task: $e');
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedTask = Task(
      id: task.id,
      listId: task.listId,
      title: task.title,
      description: task.description,
      isCompleted: !task.isCompleted,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _taskManager.updateTask(updatedTask);
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
      }
      print('Error updating task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskManager.deleteTask(task.id!);
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
      }
      print('Error deleting task: $e');
    }
  }

  Future<void> _editTask(
    Task task,
    String newTitle,
    String? newDescription,
  ) async {
    final updatedTask = Task(
      id: task.id,
      listId: task.listId,
      title: newTitle.trim(),
      description: newDescription?.trim(),
      isCompleted: task.isCompleted,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _taskManager.updateTask(updatedTask);
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
      }
      print('Error updating task: $e');
    }
  }

  void _showAddTaskDialog() {
    _showTaskDialog();
  }

  void _showEditTaskDialog(Task task) {
    _showTaskDialog(task: task);
  }

  void _showTaskDialog({Task? task}) {
    final isEditing = task != null;
    _textController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';

    // Helper function to handle task submission
    Future<void> handleSubmit() async {
      final title = _textController.text.trim();
      final description = _descriptionController.text.trim();

      if (title.isEmpty) return;

      // Close the dialog first
      Navigator.pop(context);

      // Then perform the database operation
      try {
        if (isEditing) {
          await _editTask(task, title, description);
        } else {
          await _addTask(title, description);
        }
      } catch (e) {
        print('Error in handleSubmit: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                  ),
                  Text(
                    isEditing ? 'Edit Task' : 'Add Task',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) => handleSubmit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Enter task description',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => handleSubmit(),
                          child: Text(isEditing ? 'Update' : 'Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ).whenComplete(() {
      _textController.clear();
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (value) async {
              if (value == 'reset_database') {
                await _taskManager.resetDatabase();
                await _loadTasks();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'reset_database',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Reset Database'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
              ? _buildEmptyState()
              : _buildTaskList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first task',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    // Separate completed and pending tasks
    final pendingTasks = _tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Pending tasks
        ...pendingTasks.map((task) => _buildTaskItem(task)),

        // Completed tasks section
        if (completedTasks.isNotEmpty) ...[
          if (pendingTasks.isNotEmpty) const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Completed (${completedTasks.length})',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...completedTasks.map((task) => _buildTaskItem(task)),
        ],
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteTask(task),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) => _toggleTaskCompletion(task),
            shape: const CircleBorder(),
            activeColor: Colors.blue,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              decoration:
                  task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
              color: task.isCompleted ? Colors.grey[500] : Colors.black87,
            ),
          ),
          subtitle:
              task.description != null && task.description!.isNotEmpty
                  ? Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          task.isCompleted
                              ? Colors.grey[400]
                              : Colors.grey[600],
                      decoration:
                          task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                    ),
                  )
                  : null,
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditTaskDialog(task);
              } else if (value == 'delete') {
                _deleteTask(task);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Close the database connection to prevent widget dependency errors
    _taskManager.close().catchError((error) {
      // Handle any errors during database closure silently
      print('Error closing database: $error');
    });
    super.dispose();
  }
}
