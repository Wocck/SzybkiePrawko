import 'package:flutter/material.dart';
import 'login_webview.dart';
import '../models.dart';
import '../global.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class SearchParam extends StatefulWidget {
	const SearchParam({super.key});

	@override
	State<SearchParam> createState() => _SearchParamState();
}

class _SearchParamState extends State<SearchParam> {
	List<Province> allProvinces = GlobalVars.provinces;
	List<Word> allWords = GlobalVars.words;

	List<int> selectedProvinceIds = [];
	List<int> selectedWordIds = [];

	TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
	int dayInterval = 1;

	bool sessionActive = false;
	Timer? _sessionTimer;

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

	void _showProvincesDialog() async {
		final temp = List<int>.from(selectedProvinceIds);
		await showDialog(
		context: context,
		builder: (_) => StatefulBuilder(
			builder: (ctx, setD) => AlertDialog(
			title: const Text('Wybierz województwa'),
			content: SingleChildScrollView(
				child: Column(
				children: [
					CheckboxListTile(
					title: const Text('Zaznacz wszystkie'),
					value: temp.length == allProvinces.length,
					onChanged: (v) => setD(() {
						temp.clear();
						if (v == true)
						temp.addAll(allProvinces.map((p) => p.id));
					}),
					),
					const Divider(),
					...allProvinces.map((p) {
					final sel = temp.contains(p.id);
					return CheckboxListTile(
						title: Text(p.name),
						value: sel,
						onChanged: (v) => setD(() {
						if (v == true) temp.add(p.id);
						else          temp.remove(p.id);
						}),
					);
					}),
				],
				),
			),
			actions: [
				TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
				TextButton(onPressed: () {
					setState(() {
						// 1) aktualizujemy wybrane województwa
						selectedProvinceIds = temp;
						// 2) usuwamy zaznaczone ośrodki spoza nowego zestawu województw
						selectedWordIds = selectedWordIds.where((wId) {
							final w = allWords.firstWhere((w) => w.id == wId);
							return selectedProvinceIds.contains(w.provinceId);
						}).toList();
					});
					Navigator.pop(ctx);
				}, child: const Text('Zatwierdź')),
			],
			),
		),
		);
	}

	void _showWordsDialog() async {
		final temp = List<int>.from(selectedWordIds);

		final filtered = allWords
			.where((w) => selectedProvinceIds.contains(w.provinceId))
			.toList();

		// 1. Grupowanie
		final Map<int, List<Word>> grouped = {};
		for (var w in filtered) {
			grouped.putIfAbsent(w.provinceId, () => []).add(w);
		}

		// 2. Sortowanie kluczy wg nazwy województwa
		final sortedProvinceIds = grouped.keys.toList()
			..sort((a, b) {
				final pa = allProvinces.firstWhere((p) => p.id == a).name;
				final pb = allProvinces.firstWhere((p) => p.id == b).name;
				return pa.compareTo(pb);
		});

		await showDialog(
		context: context,
		builder: (_) => StatefulBuilder(
			builder: (ctx, setD) => AlertDialog(
			title: const Text('Wybierz ośrodki'),
			content: SingleChildScrollView(
				child: Column(
				children: [
					CheckboxListTile(
					title: const Text('Zaznacz wszystkie'),
					value: filtered.every((w) => temp.contains(w.id)),
					onChanged: (v) => setD(() {
						if (v == true)
						temp.addAll(filtered.map((w) => w.id));
						else {
						filtered.forEach((w) => temp.remove(w.id));
						}
					}),
					),
					const Divider(),

					// 4. Grupy według województw
					for (var pid in sortedProvinceIds) ...[
						// nagłówek grupy
						Padding(
						padding: const EdgeInsets.symmetric(vertical: 8),
						child: Text(
							allProvinces.firstWhere((p) => p.id == pid).name,
							style: const TextStyle(
							fontWeight: FontWeight.bold,
							fontSize: 16,
							),
						),
						),
						// lista ośrodków w grupie
						...grouped[pid]!.map((w) {
						final sel = temp.contains(w.id);
						return Container(
							color: sel
								? Colors.blue.withOpacity(0.1)
								: Colors.grey.shade50,
							child: CheckboxListTile(
							title: Text(w.name),
							value: sel,
							onChanged: (v) => setD(() {
								if (v == true){
									temp.add(w.id);
								} else {
									temp.remove(w.id);
								}
							}),
							),
						);
						}),
						const Divider(),
					],
					],
				),
			),
			actions: [
				TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
				TextButton(onPressed: () {
				setState(() => selectedWordIds = temp);
				Navigator.pop(ctx);
				}, child: const Text('Zatwierdź')),
			],
			),
		),
		);
	}


	@override
	Widget build(BuildContext context) {
	return Scaffold(
		appBar: AppBar(title: const Text('Ustawienia wyszukiwania')),
		body: Stack(
		children: [
			// Główna zawartość
			Center(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.center,
				children: [
					ElevatedButton(
					onPressed: _showProvincesDialog,
					child: Text(
						selectedProvinceIds.isEmpty
							? 'Wybierz województwa'
							: 'Wybrano województw: ${selectedProvinceIds.length}',
					),
					),

					const SizedBox(height: 16),
					ElevatedButton(
					onPressed:
						selectedProvinceIds.isEmpty ? null : _showWordsDialog,
					child: Text(
						selectedWordIds.isEmpty
							? 'Wybierz ośrodki'
							: 'Wybrano ośrodków: ${selectedWordIds.length}',
					),
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
					Row(
					mainAxisAlignment: MainAxisAlignment.spaceEvenly,
					children: [
						ElevatedButton(
						onPressed: () async {
							final token = await Navigator.push<String>(
							context,
							MaterialPageRoute(
								builder: (_) => const LoginWebView()),
							);
							if (token != null) {
							GlobalVars.bearerToken = token;
							_checkSession();
							ScaffoldMessenger.of(context).showSnackBar(
								const SnackBar(content: Text('Zalogowano pomyślnie')),
							);
							}
						},
						child: const Text('Login'),
						),
						ElevatedButton(
						onPressed: () {
							// TODO: później tu podłącz „Start”
						},
						child: const Text('Start'),
						),
					],
					),
				],
				),
			),
			),

			// Kropka statusu w prawym dolnym rogu
			Positioned(
			bottom: 16,
			right: 16,
			child: Container(
				width: 12,
				height: 12,
				decoration: BoxDecoration(
				shape: BoxShape.circle,
				color: sessionActive ? Colors.green : Colors.red,
				),
			),
			),
		],
		),
	);
	}


	Future<void> _checkSession() async {
		final token = GlobalVars.bearerToken;
		print("TOKEN  = " + token);
		if (token.isEmpty) {
			setState(() => sessionActive = false);
			return;
		}
		final res = await http.get(
			Uri.parse('https://info-car.pl/api/word/word-centers/exam-schedule'),
			headers: {'Authorization': 'Bearer $token'},
		);
		if (res.statusCode == 200) {
			setState(() => sessionActive = true);
		} else if (res.statusCode == 401) {
			setState(() => sessionActive = false);
			if (mounted) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Sesja wygasła. Zaloguj się ponownie.')),
			);
			}
		}
	}


	@override
	void initState() {
		super.initState();
		_checkSession(); // od razu raz
		_sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkSession());
	}

	@override
	void dispose() {
		_sessionTimer?.cancel();
		super.dispose();
	}
}
