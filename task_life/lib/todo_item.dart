import 'package:hive_ce/hive_ce.dart';

// This declares that Hive will auto-generate a type adapter in a separate file
part 'todo_item.g.dart';

@HiveType(typeId: 0)
class TodoItem extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}
