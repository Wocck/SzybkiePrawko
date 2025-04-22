import 'package:flutter/material.dart';
import '../models.dart';
import '../global.dart';
import 'dart:async';
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
								return Padding(
									padding: const EdgeInsets.symmetric(vertical: 2.0),
									child: CheckboxListTile(
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
									),
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
							for (final w in filtered) {
								temp.remove(w.id);
							}
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
						for (var w in grouped[pid]!) Padding(
							padding: const EdgeInsets.symmetric(vertical: 2.0),
							child: CheckboxListTile(
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
					ElevatedButton(
						onPressed: (!GlobalVars.sessionActive || _isLoading || exceedMax)
							? null
							: () async {
									final messenger = ScaffoldMessenger.of(context);
									setState(() => _isLoading = true);
									final failed = <String>[];
									try {
									final events = await ApiService.fetchExamSchedules(
										GlobalVars.selectedWordIds,
										allWords,
										useTimeFilter: _useTimeFilter,
										startTime: _useTimeFilter ? _startTime : null,
										endTime: _useTimeFilter ? _endTime   : null,
										onError: (wordName) {
											failed.add(wordName);
										},
									);
									GlobalVars.examEvents = events;

									if (failed.isEmpty) {
										if (!mounted) return;
										messenger.showSnackBar(
											const SnackBar(content: Text('Pobrano terminy dla wszystkich ośrodków ✅')),
										);
									} else {
										if (!mounted) return;
										messenger.showSnackBar(
											SnackBar(content: Text('Nie udało się pobrać terminów dla: ${failed.join(', ')}')),
										);
									}
								} catch (e) {
									debugPrint('$e');
									if (!mounted) return;
									messenger.showSnackBar(
									SnackBar(content: Text('Błąd przy pobieraniu terminów: $e')),
									);
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
	
	@override
	void initState() {
		super.initState();
		_initLoginAndSession();
	}

	Future<void> _initLoginAndSession() async {
		try {
			final token = await ApiService.loginHeadless();
			setState(() {
				GlobalVars.sessionActive = true;
			});
			debugPrint('Logged in, token=$token');
		} catch (e) {
			setState(() {
				GlobalVars.sessionActive = false;
			});
			debugPrint('Headless login failed: $e');
		}

		_sessionTimer = Timer.periodic(const Duration(seconds: 30), (_) => ApiService.checkSession());
	}

	@override
	void dispose() {
		_sessionTimer?.cancel();
		super.dispose();
	}
}
