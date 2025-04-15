import 'package:flutter/material.dart';
import 'login_webview.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
			const SizedBox(height: 32),
			ElevatedButton(
				onPressed: () async {
					await Navigator.push(
						context,
						MaterialPageRoute(builder: (_) => const LoginWebView()),
					);

					final prefs = await SharedPreferences.getInstance();
					final token = prefs.getString('auth_token');
					print('[DEBUG] Odebrany token z prefs: $token');
					
					if (token != null) {
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(content: Text('Zalogowano pomyślnie')),
					);
					await checkApiAccess();
					}
				},
				child: const Text('Start'),
			),
			],
		),
		),
		),

	);
	}

	Future<void> checkApiAccess() async {
		final prefs = await SharedPreferences.getInstance();
		final token = prefs.getString('auth_token');

		
		if (token == null) {
			print('[ERROR] Brak tokenu. Użytkownik nie jest zalogowany.');
			return;
		}

		final uri = Uri.parse('https://info-car.pl/api/word/word-centers/exam-schedule');
		try {
			final response = await http.put(
			uri,
			headers: {
				'Authorization': token,
				'Content-Type': 'application/json',
			},
			body: '''{
				"category": "B", 
				"wordId": 1
			}''',
			);

			if (response.statusCode == 200) {
			print('[OK] Odpowiedź z API: ${response.body}');
			} else {
			print('[BŁĄD] Status: ${response.statusCode}');
			print(response.body);
			}
		} catch (e) {
			print('[WYJĄTEK] Nie udało się wywołać API: $e');
		}
	}
}
