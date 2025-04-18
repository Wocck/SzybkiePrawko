import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class CalendarScreen extends StatefulWidget {
	final List<ExamEvent> events;
	const CalendarScreen({required this.events, Key? key}) : super(key: key);

	@override
	State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
	DateTime _focusedMonth = DateTime.now();

	void _goToPreviousMonth() => setState(() {
		_focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
		});

	void _goToNextMonth() => setState(() {
		_focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
		});

	List<Widget> _buildDaysGrid() {
	final List<Widget> dayTiles = [];
	final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
	final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
	final startWeekday = firstDay.weekday;

	for (var i = 1; i < startWeekday; i++) {
		dayTiles.add(const SizedBox.shrink());
	}

	for (var day = 1; day <= daysInMonth; day++) {
		final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
		final dayEvents = widget.events.where((e) =>
			e.dateTime.year == date.year &&
			e.dateTime.month == date.month &&
			e.dateTime.day == date.day).toList();

		dayTiles.add(
		GestureDetector(
			onTap: dayEvents.isEmpty ? null : () => _showDayDetails(date, dayEvents),
			child: Container(
			margin: const EdgeInsets.all(2),
			padding: const EdgeInsets.all(4),
			decoration: BoxDecoration(
				border: Border.all(color: Colors.grey.shade300),
				color: dayEvents.isNotEmpty ? Colors.blue.shade100 : null,
				borderRadius: BorderRadius.circular(4),
			),
			child: Stack(
				children: [
				Align(
					alignment: Alignment.topLeft,
					child: Text('$day', style: const TextStyle(fontWeight: FontWeight.bold)),
				),
				if (dayEvents.isNotEmpty)
					Align(
					alignment: Alignment.bottomRight,
					child: Text(
						'${dayEvents.length}',
						style: const TextStyle(fontSize: 12),
					),
					),
				],
			),
			),
		),
		);
	}

	return dayTiles;
	}

	void _showDayDetails(DateTime date, List<ExamEvent> events) {
	showModalBottomSheet(
		context: context,
		isScrollControlled: true,
		builder: (BuildContext ctx) {
		final maxHeight = MediaQuery.of(ctx).size.height * 0.5;
		return Container(
			constraints: BoxConstraints(maxHeight: maxHeight),
			padding: const EdgeInsets.all(16),
			child: Column(
			children: [
				Text(
				DateFormat.yMMMMd('pl_PL').format(date),
				style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
				),
				const SizedBox(height: 8),
				Expanded(
				child: ListView.builder(
					itemCount: events.length,
					itemBuilder: (context, index) {
					final e = events[index];
					return ListTile(
						title: Text(e.wordName),
						subtitle: Text(DateFormat.Hm('pl_PL').format(e.dateTime)),
						trailing: Text('Miejsc: ${e.places}'),
					);
					},
				),
				),
			],
			),
		);
		},
	);
	}


	@override
	Widget build(BuildContext context) {
	final monthYear = DateFormat.yMMMM('pl_PL').format(_focusedMonth);

	return Scaffold(
		appBar: AppBar(title: const Text('Kalendarz terminów')),
		body: Column(
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
		),
	);
	}
}
