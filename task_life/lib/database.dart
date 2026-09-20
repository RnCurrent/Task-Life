import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'game_state.dart';

class ToDoDatabase {
  final _mybox = Hive.box('mybox');

  GameState state = GameState.initial();

  void loadData() {
    final savedState = _mybox.get('GAME_STATE');
    if (savedState is Map) {
      state = GameState.fromMap(savedState);
      state.updatePetHealth();
      return;
    }

    final oldTasks = _mybox.get('TODOLIST');
    if (oldTasks is List) {
      state.tasks = oldTasks
          .map((task) => List<dynamic>.from(task as List))
          .toList();
    }
  }

  void updateDatabase() {
    _mybox.put('GAME_STATE', state.toMap());
  }
}
