import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'todo_item.dart';

void main() async {
  // Ensure Flutter engine bindings are ready before initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage and point it to the app's document directory
  await Hive.initFlutter();
  
  // Register our newly generated adapter binary mapper
  Hive.registerAdapter(TodoItemAdapter());
  
  // Open the tasks storage container box
  await Hive.openBox<TodoItem>('todoBox');

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // Grab our pre-opened box directly
  final Box<TodoItem> _todoBox = Hive.box<TodoItem>('todoBox');
  final TextEditingController _textController = TextEditingController();

  void _addTodoItem(String title) {
    if (title.trim().isEmpty) return;
    
    setState(() {
      // Box.add() inserts the object and assigns a unique local index key automatically
      _todoBox.add(TodoItem(title: title.trim()));
    });
    _textController.clear();
  }

  void _toggleTodoItem(int index) {
    setState(() {
      final item = _todoBox.getAt(index);
      if (item != null) {
        item.isDone = !item.isDone;
        item.save(); // HiveObject extension method writes changes directly to database
      }
    });
  }

  void _deleteTodoItem(int index) {
    setState(() {
      _todoBox.deleteAt(index); // Drops record seamlessly from memory and disk layout
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-do List', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a new task...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addTodoItem,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _addTodoItem(_textController.text),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: _todoBox.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks found! Add one above.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _todoBox.length,
                    itemBuilder: (context, index) {
                      // Retrieve the live indexed item from memory map
                      final item = _todoBox.getAt(index)!;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isDone,
                            onChanged: (_) => _toggleTodoItem(index),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: item.isDone 
                                  ? TextDecoration.lineThrough 
                                  : TextDecoration.none,
                              color: item.isDone ? Colors.grey : Colors.black87,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteTodoItem(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
