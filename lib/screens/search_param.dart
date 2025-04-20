import 'dart:convert';

import 'package:flutter/material.dart';
import 'login_webview.dart';
import '../models.dart';
import '../global.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:szybkie_prawko/services/api_service.dart';

class SearchParam extends StatefulWidget {
	const SearchParam({super.key});

	@override
	State<SearchParam> createState() => _SearchParamState();
}

class _SearchParamState extends State<SearchParam> with AutomaticKeepAliveClientMixin {

	@override
	bool get wantKeepAlive => true;

	List<Province> allProvinces = GlobalVars.provinces;
	List<Word> allWords = GlobalVars.words;

	List<int> selectedProvinceIds = [];

	Timer? _sessionTimer;

	bool _isLoading = false;

	bool _useTimeFilter = false;
	TimeOfDay _startTime = const TimeOfDay(hour: 5, minute: 0);
	TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);


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
						if (v == true) {
							temp.addAll(allProvinces.map((p) => p.id));
						}
					}),
					),
					const Divider(),
					...allProvinces.map((p) {
					final sel = temp.contains(p.id);
					return CheckboxListTile(
						title: Text(p.name),
						value: sel,
						onChanged: (v) => setD(() {
							if (v == true) { 
								temp.add(p.id);
							} else {
								temp.remove(p.id);
							}
						}),
						tileColor: Theme.of(context).colorScheme.surface,
						selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
						shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
						controlAffinity: ListTileControlAffinity.leading,
					);
					}),
				],
				),
			),
			actions: [
				TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
				TextButton(onPressed: () {
					setState(() {
						selectedProvinceIds = temp;
						GlobalVars.selectedWordIds = GlobalVars.selectedWordIds.where((wId) {
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
		final temp = List<int>.from(GlobalVars.selectedWordIds);

		final filtered = allWords
			.where((w) => selectedProvinceIds.contains(w.provinceId))
			.toList();

		final Map<int, List<Word>> grouped = {};
		for (var w in filtered) {
			grouped.putIfAbsent(w.provinceId, () => []).add(w);
		}

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
						if (v == true) {
							temp.addAll(filtered.map((w) => w.id));
						} else {
							filtered.forEach((w) => temp.remove(w.id));
						}
					}),
					tileColor: Theme.of(context).colorScheme.surface,
					selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
						controlAffinity: ListTileControlAffinity.leading,
					),
					const Divider(),

					for (var pid in sortedProvinceIds) ...[
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
						for (var w in grouped[pid]!) CheckboxListTile(
							title: Text(w.name),
							value: temp.contains(w.id),
							onChanged: (v) => setD(() {
								if (v == true) {
									temp.add(w.id);
								} else {
									temp.remove(w.id);
								}
							}),
							controlAffinity: ListTileControlAffinity.leading,
							tileColor: Theme.of(ctx).colorScheme.surface,
							selectedTileColor: Theme.of(ctx)
								.colorScheme
								.primary
								.withAlpha((0.1 * 255).round()),
							shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(6),
							),
						),
						const Divider(),
					],
					],
				),
			),
			actions: [
				TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
				TextButton(onPressed: () {
					setState(() => GlobalVars.selectedWordIds = temp);
					Navigator.pop(ctx);
				}, child: const Text('Zatwierdź')),
			],
			),
		),
		);
	}


	@override
	Widget build(BuildContext context) {
		super.build(context);

		final exceedMax = GlobalVars.selectedWordIds.length > GlobalVars.maxWords;
		
	return Scaffold(
		appBar: AppBar(title: const Text('Ustawienia wyszukiwania')),
		body: Stack(
		children: [
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
						GlobalVars.selectedWordIds.isEmpty
							? 'Wybierz ośrodki'
							: 'Wybrano ośrodków: ${GlobalVars.selectedWordIds.length}',
					),
					),

					const SizedBox(height: 16),
					Align(
						alignment: Alignment.center,
						child: Card(
							shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(12),
							),
							color: Theme.of(context).colorScheme.surface,
							margin: const EdgeInsets.symmetric(vertical: 8),
							child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
							child: Row(
								mainAxisSize: MainAxisSize.min,
								children: [
								const Text('Ogranicz godzinowo'),
								const SizedBox(width: 8),
								Switch(
									value: _useTimeFilter,
									onChanged: (v) => setState(() => _useTimeFilter = v),
								),
								],
							),
							),
						),
					),

					if (_useTimeFilter) ... [
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
							ElevatedButton(
								onPressed: () async {
								final t = await showTimePicker(
									context: context, initialTime: _startTime);
								if (t != null) setState(() => _startTime = t);
								},
								child: Text('Od: ${_startTime.format(context)}'),
							),
							const SizedBox(width: 10),
							ElevatedButton(
								onPressed: () async {
								final t = await showTimePicker(
									context: context, initialTime: _endTime);
								if (t != null) setState(() => _endTime = t);
								},
								child: Text('Do: ${_endTime.format(context)}'),
							),
							],
						),
						const SizedBox(height: 16),
					],

					const SizedBox(height: 32),
					Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						if (!GlobalVars.sessionActive)
							ElevatedButton(
								onPressed: () async {
								await Navigator.push<String>(
									context,
									MaterialPageRoute(builder: (_) => const LoginWebView()),
								);
								await _checkSession();  // natychmiastowa weryfikacja
								ScaffoldMessenger.of(context).showSnackBar(
									const SnackBar(content: Text('Zalogowano pomyślnie')),
								);
								},
								child: const Text('Login'),
							),
							const SizedBox(width: 10),
						

						
					// Przycisk Start: wyłączony, gdy brak sesji, trwa ładowanie lub >4 ośrodki
					ElevatedButton(
						onPressed: (!GlobalVars.sessionActive || _isLoading || exceedMax)
							? null
							: () async {
								setState(() => _isLoading = true);
								try {
									final events = await ApiService.fetchExamSchedules(
									GlobalVars.selectedWordIds,
									allWords,
									useTimeFilter: _useTimeFilter,
									startTime: _useTimeFilter ? _startTime : null,
									endTime:   _useTimeFilter ? _endTime   : null,
									onError: (wordName) {
									ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(
										content: Text('Nie udało się pobrać terminów dla: $wordName'),
										backgroundColor: Colors.redAccent,
									),
									);
								},
									);
									GlobalVars.examEvents = events;
								} catch (e) {
									debugPrint("$e");
								} finally {
									setState(() => _isLoading = false);
								}
								},
						child: const Text('Start'),
						),
						
						if (exceedMax) ...[
							const SizedBox(width: 12),
							const Text(
								'Max 4 ośrodki naraz',
								style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
							),
						],

						if (!GlobalVars.sessionActive) ...[
							const SizedBox(width: 12),
							const Text(
								'Niezalogowany',
								style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
							),
						]
					],
					),
				],
				),
			),
			),

			if (_isLoading)
				Positioned.fill(
					child: Container(
						color: Colors.black54,
						child: const Center(
							child: CircularProgressIndicator(),
						),
					),
				),
			
			Positioned(
			bottom: 16,
			right: 16,
			child: Container(
				width: 12,
				height: 12,
				decoration: BoxDecoration(
				shape: BoxShape.circle,
				color: GlobalVars.sessionActive ? Colors.green : Colors.red,
				),
			),
			),
		],
		),
	);
	}

	Future<void> _checkSession() async {
		if (_isLoading) return;

		if (GlobalVars.bearerToken.isEmpty) {
			debugPrint("Brak tokenu → sesja nieaktywna");
			setState(() => GlobalVars.sessionActive = false);
			return;
		}
		final token = GlobalVars.bearerToken;
		final body = jsonEncode({
			"category": "A",
			"startDate": "2025-04-19T00:00:00.000Z",
			"endDate": "2025-06-20T00:00:00.000Z",
			"wordId": "8001",
		});

		bool isActive = false;

		try {
			final res = await http.put(
				Uri.parse('https://info-car.pl/api/word/word-centers/exam-schedule'),
				headers: {
				'Authorization': 'Bearer $token',
				'Content-Type': 'application/json',
				},
				body: body,
			);

			if (res.statusCode == 200 && !res.body.trimLeft().startsWith('<html')) {
				isActive = true;
			} else {
				debugPrint("✗ token odrzucony (status=${res.statusCode})");
			}

		} catch (e) {
			debugPrint("→ Błąd sieci przy tokenie: $e");
		}

		setState(() => GlobalVars.sessionActive = isActive);

		if (!isActive && mounted) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Sesja wygasła, zaloguj się ponownie')),
			);
		}
	}
	

	@override
	void initState() {
		super.initState();
		_sessionTimer = Timer.periodic(const Duration(minutes: 2), (_) => _checkSession());
	}

	@override
	void dispose() {
		_sessionTimer?.cancel();
		super.dispose();
	}
}
