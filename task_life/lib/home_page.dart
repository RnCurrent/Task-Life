import 'package:flutter/material.dart';
import 'package:task_life/database.dart';
import 'package:task_life/dialog_box.dart';
import 'package:task_life/game_state.dart';
import 'package:task_life/todo_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = ToDoDatabase();
  final controller = TextEditingController();
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    db.loadData();
  }

  void save() {
    db.updateDatabase();
    setState(() {});
  }

  void toggleTask(int index, bool? value) {
    if (value == true) {
      db.state.completeTask(index);
      _showMessage('Task complete! +25 XP and +\$10');
    } else {
      db.state.tasks[index][1] = false;
    }
    save();
  }

  void saveNewTask() {
    final title = controller.text.trim();
    if (title.isEmpty) return;
    db.state.tasks.add([title, false]);
    controller.clear();
    Navigator.of(context).pop();
    save();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> adoptPet() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adopt a pet'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Pet name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Adopt for \$50'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name != null && name.isNotEmpty && db.state.adoptPet(name)) {
      save();
      _showMessage('$name joined your home!');
    } else if (name != null) {
      _showMessage('You need level 3 and \$50, and can only have one pet.');
    }
  }

  Widget _stats() {
    final state = db.state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level ${state.level}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('💰 ${state.money}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: state.xpIntoLevel / 100),
            const SizedBox(height: 4),
            Text('${state.xpIntoLevel}/100 XP to level ${state.level + 1}'),
          ],
        ),
      ),
    );
  }

  Widget _tasksView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _stats(),
        const SizedBox(height: 8),
        ...List.generate(
          db.state.tasks.length,
          (index) => ToDoTile(
            taskName: db.state.tasks[index][0] as String,
            taskCompleted: db.state.tasks[index][1] as bool,
            onChanged: (value) => toggleTask(index, value),
            deleteFunction: (context) {
              setState(() => db.state.tasks.removeAt(index));
              db.updateDatabase();
            },
          ),
        ),
      ],
    );
  }

  Widget _houseView() {
    final state = db.state;
    final items = shopItems.where((item) => state.inventory.contains(item.id));
    final pet = state.pet;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _stats(),
        const SizedBox(height: 12),
        Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('🏠', style: TextStyle(fontSize: 64)),
                const Text(
                  'Your virtual house',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Text('Your house is ready for its first decoration.')
                else
                  Wrap(
                    spacing: 12,
                    children: items
                        .map(
                          (item) =>
                              Chip(label: Text('${item.icon} ${item.name}')),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (pet == null)
          Card(
            child: ListTile(
              leading: const Text('🐾', style: TextStyle(fontSize: 32)),
              title: Text(
                state.petsUnlocked ? 'Adopt a pet' : 'Pets unlock at level 3',
              ),
              subtitle: Text(
                state.petsUnlocked
                    ? 'You can care for one pet at a time.'
                    : 'Complete tasks to reach level 3.',
              ),
              trailing: state.petsUnlocked
                  ? FilledButton(
                      onPressed: adoptPet,
                      child: const Text('Adopt'),
                    )
                  : null,
            ),
          )
        else if (pet.alive)
          _petCard(pet),
        if (pet != null && !pet.alive)
          Card(
            child: ListTile(
              leading: const Text('💀', style: TextStyle(fontSize: 32)),
              title: const Text('Your pet has passed away'),
              subtitle: const Text(
                'You can adopt a new pet when you are ready.',
              ),
              trailing: FilledButton(
                onPressed: state.petsUnlocked ? adoptPet : null,
                child: const Text('Adopt'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _petCard(PetState pet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pet.alive ? '🐶' : '💀'} ${pet.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              pet.alive
                  ? 'Hunger: ${pet.hunger}/100'
                  : 'Your pet has died from hunger.',
            ),
            if (pet.alive) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: pet.hunger / 100),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: db.state.money >= 10
                        ? () {
                            if (db.state.feedPet()) {
                              save();
                              _showMessage('Pet fed for \$10.');
                            }
                          }
                        : null,
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Feed \$10'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (db.state.givePetToy()) {
                        save();
                        _showMessage('Your pet enjoyed a toy for \$15!');
                      } else {
                        _showMessage('You need \$15 for a toy.');
                      }
                    },
                    icon: const Icon(Icons.toys),
                    label: const Text('Toy \$15'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shopView() {
    final state = db.state;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _stats(),
        const SizedBox(height: 8),
        ...shopItems.map((item) {
          final locked = state.level < item.unlockLevel;
          final owned = state.inventory.contains(item.id);
          return Card(
            child: ListTile(
              leading: Text(item.icon, style: const TextStyle(fontSize: 30)),
              title: Text(item.name),
              subtitle: Text(
                locked
                    ? 'Unlocks at level ${item.unlockLevel}'
                    : item.description,
              ),
              trailing: owned
                  ? const Chip(label: Text('Owned'))
                  : FilledButton(
                      onPressed: locked
                          ? null
                          : () {
                              if (state.purchase(item)) {
                                save();
                                _showMessage(
                                  '${item.name} added to your house.',
                                );
                              } else {
                                _showMessage('You need \$${item.cost}.');
                              }
                            },
                      child: Text('\$${item.cost}'),
                    ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final views = [_tasksView(), _houseView(), _shopView()];
    return Scaffold(
      appBar: AppBar(title: Text(['Tasks', 'My House', 'Shop'][selectedTab])),
      body: views[selectedTab],
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => DialogBox(
                  controller: controller,
                  onSave: saveNewTask,
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.home), label: 'House'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Shop'),
        ],
      ),
    );
  }
}
