import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';


class MealPlannerScreen extends StatefulWidget {
  @override
  _MealPlannerScreenState createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, Map<String, String>> _mealPlan = {};
  final _mealSlots = ["Breakfast", "Lunch", "Dinner", "Snacks"];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Planner'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Top Section with Text Fields and Open Calendar Button
          Container(
            color: Colors.orange.shade50,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan your meals",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Notes",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text("Open Calendar"),
                  onPressed: () {
                    _showCalendarModal(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Meal Slots Section
          Expanded(
            child: _selectedDay == null
                ? Center(
              child: Text(
                "Please select a date to plan your meals.",
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView(
              padding: const EdgeInsets.all(8.0),
              children: _mealSlots.map((slot) {
                return MealSlotWidget(
                  slot: slot,
                  controller: _getController(slot),
                  onMealChanged: (value) {
                    setState(() {
                      _mealPlan[_selectedDay] ??= {};
                      _mealPlan[_selectedDay]![slot] = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Bottom Section with Generate Shopping List Button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.shopping_cart),
              label: Text("Generate Shopping List"),
              onPressed: _generateShoppingListUsingAI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController _getController(String slot) {
    _controllers.putIfAbsent(slot, () {
      String initialText = _mealPlan[_selectedDay]?[slot] ?? "";
      return TextEditingController(text: initialText);
    });
    return _controllers[slot]!;
  }

  void _showCalendarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                "Select a Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2050),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    Navigator.pop(context); // Close modal on selection
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      shape: BoxShape.circle,
                    ),
                    defaultDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _generateShoppingListUsingAI() {
    List<String> shoppingList = [];
    _mealPlan[_selectedDay]?.values.forEach((meal) {
      shoppingList.addAll(meal.split(", ").map((item) => item.trim()));
    });
    shoppingList = shoppingList.toSet().toList(); // Remove duplicates

    Map<String, List<String>> categorizedList = {
      "Dairy": [],
      "Vegetables": [],
      "Protein": [],
      "Grains": [],
      "Others": []
    };

    for (var item in shoppingList) {
      if (["milk", "cheese", "butter", "yogurt"].contains(item.toLowerCase())) {
        categorizedList["Dairy"]!.add(item);
      } else if (["carrot", "spinach", "potato", "tomato"].contains(item.toLowerCase())) {
        categorizedList["Vegetables"]!.add(item);
      } else if (["chicken", "egg", "fish", "tofu"].contains(item.toLowerCase())) {
        categorizedList["Protein"]!.add(item);
      } else if (["rice", "bread", "pasta", "oats"].contains(item.toLowerCase())) {
        categorizedList["Grains"]!.add(item);
      } else {
        categorizedList["Others"]!.add(item);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("AI-Generated Shopping List"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: categorizedList.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...entry.value.map((item) => Text("- $item")),
                  SizedBox(height: 8),
                ],
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

// Meal Slot Widget
class MealSlotWidget extends StatelessWidget {
  final String slot;
  final TextEditingController controller;
  final Function(String) onMealChanged;

  MealSlotWidget({
    required this.slot,
    required this.controller,
    required this.onMealChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(
          slot,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter meals (e.g., Eggs, Milk, Bread)",
            border: InputBorder.none,
          ),
          onChanged: onMealChanged,
        ),
      ),
    );
  }
}
