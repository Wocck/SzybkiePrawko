import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../global.dart';
import '../models.dart';
import 'package:intl/intl.dart';
import 'package:szybkie_prawko/services/api_service.dart';
import 'package:flutter/services.dart';

class WordMapScreen extends StatefulWidget {
	const WordMapScreen({super.key});

	static final LatLngBounds polandBounds = LatLngBounds(
		LatLng(47.5, 13.4),
		LatLng(56.4, 26.0),
	);

	@override
	State<WordMapScreen> createState() => _WordMapScreenState();

}

class _WordMapScreenState extends State<WordMapScreen> {
	final MapController _mapController = MapController();
	Set<String> _selectedMotos = {};


	@override
	void initState() {
		super.initState();
		_selectedMotos = GlobalVars.distinctMotoModels.toSet();
		_mapController.mapEventStream.listen((event) {
			if (event is MapEventMove || event is MapEventMoveEnd) {
				GlobalVars.lastMapCenter = event.camera.center;
				GlobalVars.lastMapZoom = event.camera.zoom;
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		final center = GlobalVars.lastMapCenter ?? WordMapScreen.polandBounds.center;
		final zoom = GlobalVars.lastMapZoom ?? 8.0;

		final size = MediaQuery.of(context).size;
		final horizontalMargin = size.width * 0.05;
		final verticalMargin   = size.height * 0.05;

		final selectedWords = GlobalVars.words
			.where((w) => GlobalVars.selectedWordIds.contains(w.id))
			.toList();
		if (selectedWords.isEmpty) {
			return const Center(child: Text('Brak zaznaczonych ośrodków'));
		}

		final filtered = selectedWords.where((w) {
			final moto = GlobalVars.wordMotos
				.firstWhere((m) => m.wordId == w.id,
				orElse: () => WordMoto(wordId: w.id, wordName: w.name, motoModel: '-'))
				.motoModel;
			return _selectedMotos.contains(moto);
		}).toList();

		setState(() {});

		return Scaffold(
			appBar: _buildAppBar(),
			body: filtered.isEmpty
				? const Center(child: Text('Brak ośrodków dla wybranych modeli'))
				: Padding(
					padding: EdgeInsets.fromLTRB(
						horizontalMargin,
						verticalMargin,
						horizontalMargin,
						verticalMargin,
					),

					child: FlutterMap(
						mapController: _mapController,
						options: MapOptions(
							initialCenter: center,
							initialZoom: zoom,
							keepAlive: true,
							cameraConstraint: CameraConstraint.contain(bounds: WordMapScreen.polandBounds),
						),
						children: [
							TileLayer(
								urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
								subdomains: const ['a', 'b', 'c'],
								userAgentPackageName: 'dev.yourapp.package',
							),
							MarkerLayer(
							markers: filtered.map((w) {
								return Marker(
									point: LatLng(w.latitude, w.longitude),
									width: 40,
									height: 40,
									child: GestureDetector(
										onTap: () {
											_openWordSheet(context, w);
										},
										child: const Icon(
											Icons.location_on,
											color: Colors.red,
											size: 32,
										),
									),
								);
							}).toList(),
							),
						],
					),
				),
		);
	}

	AppBar _buildAppBar() {
		return AppBar(
		title: Center(
			child: const Text('Mapa ośrodków')
		),
		actions: [
			IconButton(
				icon: const Icon(Icons.filter_list),
				tooltip: 'Filtruj po modelach',
				onPressed: _openMotoFilterDialog,
			),
		],
		);
	}

	void _openMotoFilterDialog() async {
		final temp = Set<String>.from(_selectedMotos);
		await showDialog(
			context: context,
			builder: (_) => StatefulBuilder(
			builder: (ctx, setD) => AlertDialog(
				title: const Text('Wybierz modele motocykli'),
				content: SizedBox(
				height: MediaQuery.of(context).size.height * 0.6,
				width: MediaQuery.of(context).size.width * 0.8,
				child: Wrap(
					spacing: 8.0,
					runSpacing: 8.0,
					children: [
						ChoiceChip(
							label: const Text('Wszystkie'),
							selected: temp.length == GlobalVars.distinctMotoModels.length,
							onSelected: (bool selected) {
							setD(() {
								temp.clear();
								if (selected) {
								temp.addAll(GlobalVars.distinctMotoModels);
								}
							});
							},
						),
						const Divider(),
						...GlobalVars.distinctMotoModels.map((model) {
							return ChoiceChip(
							label: Text(model),
							selected: temp.contains(model),
							onSelected: (bool selected) {
								setD(() {
								if (selected) {
									temp.add(model);
								} else {
									temp.remove(model);
								}
								});
							},
							);
						}),
					],
				),
				),
				actions: [
				TextButton(
					onPressed: () => Navigator.pop(ctx),
					child: const Text('Anuluj'),
				),
				TextButton(
					onPressed: () {
						setState(() {
							_selectedMotos = temp;
						});
						Navigator.pop(ctx);
					},
					child: const Text('Zatwierdź'),
				),
				],
			),
			),
		);
	}


	void _openWordSheet(BuildContext context, Word w) {
		final motoEntry = GlobalVars.wordMotos.firstWhere(
			(m) => m.wordId == w.id,
			orElse: () => WordMoto(wordId: w.id, motoModel: '-', wordName: '-'),
		);

		showModalBottomSheet(
		context: context,
		isScrollControlled: true,
		builder: (ctx) {
			List<ExamEvent> events = GlobalVars.examEvents
				.where((e) => e.wordId == w.id)
				.toList()
			..sort((a,b)=>a.dateTime.compareTo(b.dateTime));
			bool isLoading = false;

			return StatefulBuilder(
			builder: (ctx, setSt) => DraggableScrollableSheet(
				expand: false,
				initialChildSize: 0.5,
				minChildSize: 0.3,
				maxChildSize: 0.9,
				builder: (_, controller) => Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
					Text(
						'${w.name} —> ${motoEntry.motoModel}',
						style: const TextStyle(
							fontSize: 18, fontWeight: FontWeight.bold
						),
					),
					const SizedBox(height: 4),
					Row (
						children: [
							SelectableText(w.address, style: const TextStyle(color: Colors.grey)),
							IconButton(
								icon: const Icon(Icons.copy, size: 20),
								tooltip: 'Kopiuj adres',
								onPressed: () {
									Clipboard.setData(ClipboardData(text: w.address));
									ScaffoldMessenger.of(ctx).showSnackBar(
									const SnackBar(content: Text('Adres skopiowany do schowka')),
									);
								},
							),
						],
					),
					const Divider(height: 20),
					Row(
						children: [
						ElevatedButton.icon(
							icon: isLoading 
							? SizedBox(
								width: 16, height: 16,
								child: CircularProgressIndicator(strokeWidth: 2)
								)
							: const Icon(Icons.download),
							label: const Text('Pobierz terminy'),
							style: GlobalVars.sessionActive
								? null
								: ElevatedButton.styleFrom(
									backgroundColor: Theme.of(context).disabledColor,
									),
							onPressed: !GlobalVars.sessionActive || isLoading
								? () {
									if (!GlobalVars.sessionActive) {
										ScaffoldMessenger.of(ctx).showSnackBar(
										const SnackBar(
											content: Text('Sesja nieaktywna. Zaloguj się ponownie.'),
										),
										);
									}
									} : () async {
							setSt(() => isLoading = true);
							final messenger = ScaffoldMessenger.of(context);
							try {
								final fetched = await ApiService.fetchExamSchedules(
								[w.id], GlobalVars.words,
								useTimeFilter: false
								);
								GlobalVars.examEvents = [
								...GlobalVars.examEvents
									.where((e)=>e.wordId!=w.id),
								...fetched
								];
								events = fetched;
							} catch (e) {
								messenger.showSnackBar(
									SnackBar(content: Text('Błąd: $e'))
								);
							} finally {
								setSt(() => isLoading = false);
							}
							},
						),
						const SizedBox(width: 16),
						Text('(${events.length} terminów)'),
						],
					),
					const Divider(height: 20),
					Expanded(
						child: events.isEmpty
						? const Center(child: Text('Brak terminów'))
						: ListView.builder(
							controller: controller,
							itemCount: events.length,
							itemBuilder: (_, i) {
								final e = events[i];
								final formatted = DateFormat.yMMMd('pl_PL')
								.add_Hm()
								.format(e.dateTime);
								return ListTile(
								leading: const Icon(Icons.event),
								title: Text(formatted),
								subtitle: Text('Miejsc: ${e.places}'),
								);
							},
							),
					),
					],
				),
				),
			),
			);
		},
		);
	}
}
