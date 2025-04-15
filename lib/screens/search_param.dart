import 'package:flutter/material.dart';

class SearchParam extends StatefulWidget {
	const SearchParam({super.key});

	@override
	State<SearchParam> createState() => _SearchParamState();
}

class _SearchParamState extends State<SearchParam> {
	// Lista województw
	final List<String> wojewodztwa = [
	'Dolnośląskie',
	'Kujawsko-Pomorskie',
	'Lubelskie',
	'Lubuskie',
	'Łódzkie',
	'Małopolskie',
	'Mazowieckie',
	'Opolskie',
	'Podkarpackie',
	'Podlaskie',
	'Pomorskie',
	'Śląskie',
	'Świętokrzyskie',
	'Warmińsko-Mazurskie',
	'Wielkopolskie',
	'Zachodniopomorskie',
	];

	// Wybrane województwa
	List<String> selectedWojewodztwa = [];

	// Wybrana godzina
	TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

	// Odstęp dni
	int dayInterval = 1;

	void _pickTime() async {
	final TimeOfDay? picked = await showTimePicker(
		context: context,
		initialTime: selectedTime,
	);
	if (picked != null) {
		setState(() {
		selectedTime = picked;
		});
	}
	}

void _showWojewodztwaDialog() async {
	final List<String> tempSelected = List.from(selectedWojewodztwa);

	await showDialog(
	context: context,
	builder: (context) => StatefulBuilder(
		builder: (context, setStateDialog) => AlertDialog(
		title: const Text('Wybierz województwa'),
		content: SingleChildScrollView(
			child: Column(
			children: wojewodztwa.map((w) {
				final isSelected = tempSelected.contains(w);
				return CheckboxListTile(
				title: Text(w),
				value: isSelected,
				onChanged: (val) {
					setStateDialog(() {
					if (val == true) {
						tempSelected.add(w);
					} else {
						tempSelected.remove(w);
					}
					});
				},
				);
			}).toList(),
			),
		),
		actions: [
			TextButton(
			onPressed: () => Navigator.pop(context),
			child: const Text('Anuluj'),
			),
			TextButton(
			onPressed: () {
				setState(() {
				selectedWojewodztwa = tempSelected;
				});
				Navigator.pop(context);
			},
			child: const Text('Zatwierdź'),
			),
		],
		),
	),
	);
}


	@override
	Widget build(BuildContext context) {
	return Scaffold(
		appBar: AppBar(title: const Text('Ustawienia wyszukiwania')),
		body: Center(
		child: Padding(
		padding: const EdgeInsets.all(16),
		child: Column(
			mainAxisSize: MainAxisSize.min,
			crossAxisAlignment: CrossAxisAlignment.center,
			children: [
			ElevatedButton(
				onPressed: _showWojewodztwaDialog,
				child: Text(selectedWojewodztwa.isEmpty
					? 'Wybierz województwa'
					: 'Wybrano: ${selectedWojewodztwa.length}'),
			),
			const SizedBox(height: 16),
			ElevatedButton(
				onPressed: _pickTime,
				child: Text('Godzina: ${selectedTime.format(context)}'),
			),
			const SizedBox(height: 16),
			Row(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.center,
				children: [
				const Text('Powtarzaj co:'),
				const SizedBox(width: 16),
				DropdownButton<int>(
					value: dayInterval,
					items: List.generate(
					30,
					(index) => DropdownMenuItem(
						value: index + 1,
						child: Text('${index + 1} dni'),
					),
					),
					onChanged: (val) {
					if (val != null) {
						setState(() {
						dayInterval = val;
						});
					}
					},
				),
				],
			),
			],
		),
		),
		),

	);
	}
}
