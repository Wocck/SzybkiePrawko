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
	String _selectedCategory = GlobalVars.selectedCategory;
	
	@override
	void initState() {
		super.initState();
		_initLoginAndSession();
	}


	@override
	Widget build(BuildContext context) {
		super.build(context);

		final exceedMax = GlobalVars.selectedWordIds.length > GlobalVars.maxWords;
		
		return Scaffold(
			appBar: AppBar(
				leading: IconButton(
					icon: const Icon(Icons.info_outline),
					tooltip: 'Informacje',
					onPressed: _showInfoDialog,
				),
				title: Center(
					child: const Text('Wyszukiwanie')
				),
			),
			body: Stack(
			children: [
				Center(
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [ 
						IntrinsicWidth( 
							child: DropdownButtonFormField<String>(
								decoration: const InputDecoration(
									labelText: 'Kat.',
									border: OutlineInputBorder(),
								),
								value: _selectedCategory,
								items: GlobalVars.examCategories
								.map((cat) => DropdownMenuItem(
									value: cat,
									child: Text(cat),
								))
								.toList(),
								onChanged: (cat) {
									if (cat == null) return;
									setState(() {
										_selectedCategory = cat;
										GlobalVars.selectedCategory = cat;
										GlobalVars.selectedWordIds.clear();
										selectedProvinceIds.clear();
										GlobalVars.examEvents.clear();
									});
								},
							),
						),
						const SizedBox(height: 24),

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
							onPressed: (!GlobalVars.sessionActive || _isLoading || exceedMax || GlobalVars.selectedWordIds.isEmpty)
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
										if (!mounted) return;
										messenger.showSnackBar(
										SnackBar(content: Text('Błąd przy pobieraniu terminów: $e')),
										);
									} finally {
										setState(() => _isLoading = false);
									}
									},
							child: const Text('Wyszukaj'),
							),

							if (GlobalVars.selectedWordIds.isEmpty) ...[
								const SizedBox(width: 12),
								const Text(
									'Zaznacz ośrodki',
									style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
								),
							],

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
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							Container(
								width: 12,
								height: 12,
								decoration: BoxDecoration(
								shape: BoxShape.circle,
								color: GlobalVars.sessionActive ? Colors.green : Colors.red,
								),
							),

							const SizedBox(width: 8),
							if (!GlobalVars.sessionActive)
								IconButton(
								iconSize: 20,
								tooltip: 'Odśwież sesję',
								icon: _isLoading
									? SizedBox(
										width: 16,
										height: 16,
										child: CircularProgressIndicator(strokeWidth: 2),
										)
									: const Icon(Icons.refresh),
								onPressed: _isLoading ? null : _initLoginAndSession,
								),
						],
					),
				),
			],
			),
		);


	}


	@override
	void dispose() {
		_sessionTimer?.cancel();
		super.dispose();
	}

	void _showProvincesDialog() async {
		final temp = List<int>.from(selectedProvinceIds);
		await showDialog(
			context: context,
			builder: (_) => StatefulBuilder(
			builder: (ctx, setD) {
				return Dialog(
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
				child: Container(
					height: MediaQuery.of(ctx).size.height * 0.7,
					width: MediaQuery.of(ctx).size.width * 0.8,
					padding: const EdgeInsets.all(16),
					child: Material(
					color: Colors.transparent,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
						const Text(
							'Wybierz województwa',
							style: TextStyle(
							fontSize: 20,
							fontWeight: FontWeight.bold,
							),
						),
						const SizedBox(height: 16),
						Material(
							elevation: 4,
							borderRadius: BorderRadius.circular(8),
							child: Container(
							padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
							decoration: BoxDecoration(
								color: Theme.of(ctx).cardColor,
								borderRadius: BorderRadius.circular(8),
							),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.end,
								children: [
								TextButton.icon(
									label: const Text(''),
									icon: Icon(
									temp.length == allProvinces.length
										? Icons.check_box_outlined
										: Icons.check_box_outline_blank,
									),
									onPressed: () => setD(() {
									if (temp.length == allProvinces.length) {
										temp.clear();
									} else {
										temp
										..clear()
										..addAll(allProvinces.map((p) => p.id));
									}
									}),
								),
								const Spacer(),
								TextButton.icon(
									onPressed: () => Navigator.pop(ctx),
									label: const Text(''),
									icon: Icon(Icons.clear_rounded)
								),
								const SizedBox(width: 8),
								ElevatedButton.icon(
									onPressed: () {
									setState(() {
										selectedProvinceIds = temp;
										GlobalVars.selectedWordIds = GlobalVars.selectedWordIds.where((wId) {
										final w = allWords.firstWhere((w) => w.id == wId);
										return selectedProvinceIds.contains(w.provinceId);
										}).toList();
									});
									Navigator.pop(ctx);
									},
									label: const Text(''),
									icon: Icon(Icons.check_rounded)
								),
								],
							),
							),
						),
						const SizedBox(height: 12),
						Expanded(
							child: Material(
							elevation: 2,
							borderRadius: BorderRadius.circular(8),
							clipBehavior: Clip.antiAlias,
							child: Container(
								color: Theme.of(ctx).scaffoldBackgroundColor,
								child: ListView.builder(
								padding: const EdgeInsets.all(8),
								itemCount: allProvinces.length,
								itemBuilder: (context, index) {
									final p = allProvinces[index];
									final sel = temp.contains(p.id);
									return Padding(
									padding: const EdgeInsets.symmetric(vertical: 2.0),
									child: Card(
										elevation: 0,
										margin: EdgeInsets.zero,
										shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(6),
										),
										color: sel
											? Theme.of(ctx).colorScheme.primary.withAlpha((0.1 * 255).round())
											: Theme.of(ctx).colorScheme.surface,
										child: CheckboxListTile(
										title: Text(p.name, style: const TextStyle(fontSize: 16)),
										value: sel,
										onChanged: (v) => setD(() {
											if (v == true) {
											temp.add(p.id);
											} else {
											temp.remove(p.id);
											}
										}),
										controlAffinity: ListTileControlAffinity.leading,
										dense: true,
										),
									),
									);
								},
								),
							),
							),
						),
						],
					),
					),
				),
				);
			},
			),
		);
	}

	void _showWordsDialog() async {
		final temp = List<int>.from(GlobalVars.selectedWordIds);
		final baseList = allWords.where((w) => selectedProvinceIds.contains(w.provinceId)).toList();

		String search = '';
		List<Word> displayList = List.from(baseList);

		void filter() {
			final q = search.toLowerCase().trim();
			displayList = baseList
				.where((w) => w.name.toLowerCase().contains(q))
				.toList();
		}

		await showDialog(
			context: context,
			builder: (_) => StatefulBuilder(
			builder: (ctx, setD) {
				final groupedMap = <int, List<Word>>{};
				for (var w in displayList) {
				groupedMap.putIfAbsent(w.provinceId, () => []).add(w);
				}
				final sortedProvinceIds = groupedMap.keys.toList()
				..sort((a, b) {
					final na = allProvinces.firstWhere((p) => p.id == a).name;
					final nb = allProvinces.firstWhere((p) => p.id == b).name;
					return na.compareTo(nb);
				});

				return Dialog(
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
				child: Container(
					height: MediaQuery.of(ctx).size.height * 0.7,
					width: MediaQuery.of(ctx).size.width * 0.8,
					padding: const EdgeInsets.all(16),
					child: Material(
					color: Colors.transparent,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
						const Padding(
							padding: EdgeInsets.only(bottom: 16),
							child: Text(
							'Wybierz ośrodki',
							style: TextStyle(
								fontSize: 20,
								fontWeight: FontWeight.bold,
							),
							),
						),
						
						TextField(
							decoration: const InputDecoration(
								prefixIcon: Icon(Icons.search),
								hintText: 'Szukaj po nazwie...',
								contentPadding: EdgeInsets.symmetric(vertical: 8),
							),
							onChanged: (val) => setD(() {
								search = val;
								filter();
							}),
						),
						const SizedBox(height: 12),
						
						Material(
							elevation: 4,
							borderRadius: BorderRadius.circular(8),
							child: Container(
							padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
							decoration: BoxDecoration(
								color: Theme.of(ctx).cardColor,
								borderRadius: BorderRadius.circular(8),
							),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.end,
								children: [
								TextButton.icon(
									label: const Text(''),
									icon: Icon(
									displayList.every((w) => temp.contains(w.id))
										? Icons.check_box_outlined
										: Icons.check_box_outline_blank
									),
									onPressed: () => setD(() {
									if (displayList.every((w) => temp.contains(w.id))) {
										temp.clear();
									} else {
										temp..clear()..addAll(displayList.map((w) => w.id));
									}
									}),
								),
								const Spacer(),
								TextButton.icon(
									icon: Icon(Icons.clear_rounded),
									label: const Text(''),
									onPressed: () => Navigator.pop(ctx),
								),
								const SizedBox(width: 8),
								ElevatedButton.icon(
									onPressed: () {
										setState(() => GlobalVars.selectedWordIds = temp);
										Navigator.pop(ctx);
									},
									label: const Text(''),
									icon: Icon(Icons.check_rounded)
								),
								],
							),
							),
						),
						const SizedBox(height: 12),
						
						Expanded(
							child: Material(
							elevation: 2,
							borderRadius: BorderRadius.circular(8),
							clipBehavior: Clip.antiAlias,
							child: Stack(
								children: [
								Container(
									color: Theme.of(ctx).scaffoldBackgroundColor,
								),
								ListView.builder(
									padding: const EdgeInsets.all(8),
									itemCount: sortedProvinceIds.length,
									itemBuilder: (context, provinceIndex) {
									final pid = sortedProvinceIds[provinceIndex];
									final items = groupedMap[pid]!;
									
									return Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
										Padding(
											padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
											child: Center (
												child:Text(
													allProvinces.firstWhere((p) => p.id == pid).name.toUpperCase(),
													style: const TextStyle(
														fontWeight: FontWeight.bold,
														fontSize: 18,
													),
												),
											),
										),
										
										...items.map((w) => Padding(
											padding: const EdgeInsets.symmetric(vertical: 2),
											child: Card(
											elevation: 0,
											margin: EdgeInsets.zero,
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(6),
											),
											color: temp.contains(w.id)
												? Theme.of(ctx).colorScheme.primary.withAlpha((0.1 * 255).round())
												: Theme.of(ctx).colorScheme.surface,
											child: CheckboxListTile(
												title: Text(w.name, style: const TextStyle(fontSize: 16)),
												value: temp.contains(w.id),
												onChanged: (v) => setD(() {
												if (v == true) {
													temp.add(w.id);
												} else {
													temp.remove(w.id);
												}
												}),
												controlAffinity: ListTileControlAffinity.leading,
												dense: true,
											),
											),
										)),
										
										if (provinceIndex < sortedProvinceIds.length - 1)
											const Divider(height: 24),
										],
									);
									},
								),
								],
							),
							),
						),
						],
					),
					),
				),
				);
			},
			),
		);
	}

	void _showInfoDialog() {
		showDialog(
			context: context,
			builder: (ctx) => AlertDialog(
			title: const Text('Jak używać'),
			content: const Text(
				'1. Wybierz Kategorię, Województwa i Ośrodki egzaminacyjne.\n'
				'2. Opcjonalnie ustaw filtr godzinowy.\n'
				'3. Kliknij "Wyszukaj", aby pobrać dostępne terminy (Max 4 ośrodki jednocześnie).\n'
				'4. Możesz też przejść do mapy ośrodków i wyszukiwać terminy dla każdego ośrodka osobno.\n\n'
				
				'⚠️ Uwaga: Ze względu na ograniczenia portalu Info-Car można wyszukać maksymalnie 4 ośrodki jednocześnie.\n'
				'Po wybraniu ośrodkó możesz ładować terminy dla poszczególnych ośrodków klikając na nie na mapie.\n\n'
				'⚠️ Uwaga: Modele motocykli są w wiekszości poprawne ale w niektórych przypadkach mogą się różnić, warto upewnić się na stronie danego WORD-u.\n\n'
				'🔄 Sesja jest automatycznie odświeżana co 30 sekund. Jeśli sesja wygaśnie (czerwona kropka w prawym dolnym rogu), wróć na ekran główny i użyj przycisku odświeżania lub poczekaj 30s.\n\n'
				'🚫 Zbyt częste zapytania do Info-Car mogą spowodować blokadę zapytań na 10–15 sekund — w takim przypadku należy chwilę odczekać.'
			),
			actions: [
				TextButton(
				onPressed: () => Navigator.of(ctx).pop(),
				child: const Text('Zamknij'),
				),
			],
			),
		);
	}

	
	Future<void> _initLoginAndSession() async {
		try {
			await ApiService.loginHeadless();
			setState(() {
				GlobalVars.sessionActive = true;
			});
		} catch (e) {
			setState(() {
				GlobalVars.sessionActive = false;
			});
		}

		_sessionTimer = Timer.periodic(const Duration(seconds: 30), (_) => ApiService.checkSession());
	}
}
