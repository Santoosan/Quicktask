import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:quick_task/screens/edit_screen.dart';

class Task {
  final String objectId;
  final String title;
  final DateTime dueDate;
  bool status;

  Task({
    required this.objectId,
    required this.title,
    required this.dueDate,
    required this.status,
  });

  factory Task.fromParse(ParseObject parseObject) {
    print('Fetched ParseObject: ${parseObject.toJson()}');
    return Task(
      objectId: parseObject.objectId!,
      title: parseObject.get<String>('title') ?? '',
      dueDate: parseObject.get<DateTime>('dueDate') ?? DateTime.now(),
      status: parseObject.get<bool>('isCompleted') ?? false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Task> tasks = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    )..repeat(reverse: true);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final fetchedTasks = await fetchTasks();
    setState(() {
      tasks = fetchedTasks;
    });
  }

  Future<List<Task>> fetchTasks() async {
    try {
      final currentUser = await ParseUser.currentUser();
      if (currentUser == null) {
        return [];
      }

      final query = QueryBuilder(ParseObject('Task'))..orderByDescending('dueDate');
      final response = await query.query();

      if (response.success && response.results != null) {
        return (response.results as List<ParseObject>)
            .map((e) => Task.fromParse(e))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Exception fetching tasks: $e');
      return [];
    }
  }

  Future<bool> deleteTask(String objectId) async {
    final task = ParseObject('Task')..objectId = objectId;
    final response = await task.delete();
    return response.success;
  }

  Future<bool> toggleTaskStatus(String objectId, bool currentStatus) async {
    final task = ParseObject('Task')..objectId = objectId;
    task.set('isCompleted', !currentStatus);

    final response = await task.save();
    return response.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal,
                      Colors.blueAccent.withOpacity(0.6),
                      Colors.purpleAccent.withOpacity(0.6),
                    ],
                    stops: [
                      _controller.value,
                      _controller.value + 0.3,
                      _controller.value + 0.6
                    ].map((stop) => stop % 1).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          // Main content
          Column(
            children: [
              AppBar(
                title: Text(
                  'My Tasks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks available',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            margin:
                                EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            elevation: task.status ? 7 : 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: task.status
                                ? Colors.green[100]
                                : Colors.white,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(15),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: task.status
                                      ? Colors.green[800]
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Due: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(color: Colors.grey),
                              ),
                              trailing: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        task.status
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: task.status
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        final success =
                                            await toggleTaskStatus(
                                                task.objectId, task.status);
                                        if (success) {
                                          setState(() {
                                            task.status = !task.status;
                                          });
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditTaskScreen(task: task),
                                          ),
                                        ).then((result) {
                                          if (result == true) {
                                            _loadTasks();
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        final success =
                                            await deleteTask(task.objectId);
                                        if (success) {
                                          setState(() {
                                            tasks.remove(task);
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addTask');
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
        elevation: 8.0,
        tooltip: 'Add Task',
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}