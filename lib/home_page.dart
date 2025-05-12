import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'second_page.dart';

class HomePage extends StatefulWidget {
  final void Function(bool) onThemeChanged;
  final bool isDark;

  const HomePage({
    super.key,
    required this.onThemeChanged,
    required this.isDark,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> tasks = [];
  List<String> filteredTasks = [];
  TextEditingController controller = TextEditingController();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    searchController.addListener(_filterTasks);
  }

  void _filterTasks() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredTasks =
          tasks.where((task) => task.toLowerCase().contains(query)).toList();
    });
  }

  void _addTask(String task) async {
    if (task.isEmpty) return;
    setState(() {
      tasks.add(task);
      controller.clear();
      _saveTasks();
      _filterTasks();
    });
  }

  void _removeTask(int index) async {
    setState(() {
      tasks.removeAt(index);
      _saveTasks();
      _filterTasks();
    });
  }

  void _editTask(int index, String newTask) async {
    if (newTask.isEmpty) return;
    setState(() {
      tasks[index] = newTask;
      _saveTasks();
      _filterTasks();
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('tasks') ?? [];
    setState(() {
      tasks = saved;
      filteredTasks = List.from(saved);
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo List'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeChanged(!widget.isDark),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecondPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Cari tugas...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Tambah tugas',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _addTask(controller.text),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final actualIndex = tasks.indexOf(filteredTasks[index]);
                  return Card(
                    child: ListTile(
                      title: Text(filteredTasks[index]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final editController = TextEditingController(
                                text: filteredTasks[index],
                              );
                              final edited = await showDialog<String>(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('Edit Tugas'),
                                      content: TextField(
                                        controller: editController,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, null),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(
                                                context,
                                                editController.text,
                                              ),
                                          child: const Text('Simpan'),
                                        ),
                                      ],
                                    ),
                              );
                              if (edited != null && edited.isNotEmpty) {
                                _editTask(actualIndex, edited);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeTask(actualIndex),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
