import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<Widget> _buildDaysGrid() {
    final List<Widget> dayTiles = [];
    final DateTime firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final int startWeekday = firstDay.weekday;

    // Puste miejsca na początek
    for (int i = 1; i < startWeekday; i++) {
      dayTiles.add(const SizedBox.shrink());
    }

    // Dni miesiąca
    for (int i = 1; i <= daysInMonth; i++) {
      dayTiles.add(
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text('$i'),
        ),
      );
    }

    return dayTiles;
  }

  @override
  Widget build(BuildContext context) {
    final String monthYear = DateFormat.yMMMM('pl_PL').format(_focusedMonth);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _goToPreviousMonth, icon: const Icon(Icons.arrow_back)),
              Text(monthYear, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _goToNextMonth, icon: const Icon(Icons.arrow_forward)),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            children: _buildDaysGrid(),
          ),
        ),
      ],
    );
  }
}
