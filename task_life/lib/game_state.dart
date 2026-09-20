class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.unlockLevel,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
  final int unlockLevel;
  final String icon;
}

const shopItems = [
  ShopItem(
    id: 'plant',
    name: 'House plant',
    description: 'A little greenery for your home.',
    cost: 25,
    unlockLevel: 1,
    icon: '🪴',
  ),
  ShopItem(
    id: 'lamp',
    name: 'Cozy lamp',
    description: 'Makes the house feel warmer.',
    cost: 75,
    unlockLevel: 2,
    icon: '💡',
  ),
  ShopItem(
    id: 'sofa',
    name: 'Comfy sofa',
    description: 'A well-earned place to relax.',
    cost: 150,
    unlockLevel: 4,
    icon: '🛋️',
  ),
];

class PetState {
  PetState({
    required this.name,
    required this.hunger,
    required this.lastFed,
    required this.alive,
  });

  String name;
  int hunger;
  DateTime lastFed;
  bool alive;

  Map<String, dynamic> toMap() => {
    'name': name,
    'hunger': hunger,
    'lastFed': lastFed.millisecondsSinceEpoch,
    'alive': alive,
  };

  factory PetState.fromMap(Map<dynamic, dynamic> map) => PetState(
    name: map['name'] as String,
    hunger: map['hunger'] as int,
    lastFed: DateTime.fromMillisecondsSinceEpoch(map['lastFed'] as int),
    alive: map['alive'] as bool,
  );
}

class GameState {
  GameState({
    required this.tasks,
    required this.xp,
    required this.money,
    required this.inventory,
    required this.pet,
  });

  List<List<dynamic>> tasks;
  int xp;
  int money;
  List<String> inventory;
  PetState? pet;

  int get level => xp ~/ 100 + 1;
  int get xpIntoLevel => xp % 100;
  bool get petsUnlocked => level >= 3;

  void completeTask(int index) {
    if (tasks[index][1] as bool) return;
    tasks[index][1] = true;
    xp += 25;
    money += 10;
  }

  bool purchase(ShopItem item) {
    if (level < item.unlockLevel ||
        money < item.cost ||
        inventory.contains(item.id)) {
      return false;
    }
    money -= item.cost;
    inventory.add(item.id);
    return true;
  }

  bool adoptPet(String name) {
    if (!petsUnlocked || (pet != null && pet!.alive) || money < 50) {
      return false;
    }
    money -= 50;
    final now = DateTime.now();
    pet = PetState(name: name, hunger: 100, lastFed: now, alive: true);
    return true;
  }

  bool feedPet() {
    final currentPet = pet;
    if (currentPet == null || !currentPet.alive || money < 10) return false;
    money -= 10;
    currentPet.hunger = (currentPet.hunger + 35).clamp(0, 100);
    currentPet.lastFed = DateTime.now();
    return true;
  }

  bool givePetToy() {
    final currentPet = pet;
    if (currentPet == null || !currentPet.alive || money < 15) return false;
    money -= 15;
    return true;
  }

  void updatePetHealth([DateTime? now]) {
    final currentPet = pet;
    if (currentPet == null || !currentPet.alive) return;
    final elapsed = (now ?? DateTime.now()).difference(currentPet.lastFed);
    currentPet.hunger = (100 - elapsed.inHours * 2).clamp(0, 100);
    if (elapsed.inHours >= 72) currentPet.alive = false;
  }

  Map<String, dynamic> toMap() => {
    'tasks': tasks,
    'xp': xp,
    'money': money,
    'inventory': inventory,
    'pet': pet?.toMap(),
  };

  factory GameState.initial() => GameState(
    tasks: [
      ['Create task', false],
    ],
    xp: 0,
    money: 0,
    inventory: [],
    pet: null,
  );

  factory GameState.fromMap(Map<dynamic, dynamic> map) => GameState(
    tasks: (map['tasks'] as List)
        .map((task) => List<dynamic>.from(task as List))
        .toList(),
    xp: map['xp'] as int,
    money: map['money'] as int,
    inventory: List<String>.from(map['inventory'] as List),
    pet: map['pet'] == null
        ? null
        : PetState.fromMap(map['pet'] as Map<dynamic, dynamic>),
  );
}
