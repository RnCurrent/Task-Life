import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:task_life/game_state.dart';
import 'package:task_life/main.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('task-life-tests');
    Hive.init(directory.path);
    await Hive.openBox('mybox');
  });

  test('completing a task grants XP and money once', () {
    final state = GameState.initial();
    state.completeTask(0);
    state.completeTask(0);

    expect(state.xp, 25);
    expect(state.money, 10);
    expect(state.level, 1);
  });

  test('shop purchases are gated by level and money', () {
    final state = GameState.initial()..money = 100;

    expect(state.purchase(shopItems[1]), isFalse);
    state.xp = 100;
    expect(state.purchase(shopItems[1]), isTrue);
    expect(state.inventory, contains('lamp'));
  });

  test('a pet dies after three days without food', () {
    final state = GameState.initial()
      ..xp = 200
      ..money = 50;
    expect(state.adoptPet('Mochi'), isTrue);

    final lastFed = state.pet!.lastFed;
    state.updatePetHealth(lastFed.add(const Duration(hours: 72)));

    expect(state.pet!.alive, isFalse);
  });

  testWidgets('app displays progression navigation', (tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('House'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
  });
}
