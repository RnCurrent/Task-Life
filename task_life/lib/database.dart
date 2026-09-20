import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';

class ToDoDatabase {
  List toDoList = [];
  
  // reference box
  final _mybox = Hive.box('mybox');

  // run if first time ever opening app
  void createInitialData() {
    toDoList = [
      ["Create task", false]
    ];
  }

  // load data from db
  void loadData() {
    toDoList = _mybox.get("TODOLIST");
  }

  // Update db
  void updateDatabase() {
    _mybox.put("TODOLIST", toDoList);
  }
}