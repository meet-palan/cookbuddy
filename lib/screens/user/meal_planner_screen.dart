import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MealPlannerScreen extends StatefulWidget {
  @override
  _MealPlannerScreenState createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Planner'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Calendar Section
          Container(
            color: Colors.orange.shade50,
            padding: const EdgeInsets.all(8.0),
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

          // Meal Slots Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                MealSlotWidget(slot: "Breakfast"),
                MealSlotWidget(slot: "Lunch"),
                MealSlotWidget(slot: "Dinner"),
                MealSlotWidget(slot: "Snacks"),
              ],
            ),
          ),

          // Bottom Action Section
          Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Generate Shopping List'),
                  onPressed: () {
                    // Shopping list logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.share),
                  label: Text('Export/Share Meal Plan'),
                  onPressed: () {
                    // Export/share logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Meal Slot Widget
class MealSlotWidget extends StatelessWidget {
  final String slot;

  MealSlotWidget({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(
          slot,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Tap to add a recipe'),
        trailing: Icon(Icons.add),
        onTap: () {
          // Navigate to recipe selection screen
        },
      ),
    );
  }
}
