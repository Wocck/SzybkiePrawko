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
		LatLng(48.0, 13.0),
		LatLng(55.4, 25.0),
	);

	@override
	State<WordMapScreen> createState() => _WordMapScreenState();

}

class _WordMapScreenState extends State<WordMapScreen> {
	final MapController _mapController = MapController();

	@override
	void initState() {
		super.initState();

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

		final selected = GlobalVars.words
			.where((w) => GlobalVars.selectedWordIds.contains(w.id))
			.toList();
		if (selected.isEmpty) {
		return const Center(child: Text('Brak zaznaczonych ośrodków'));
		}

		return Padding (
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
				subdomains: const ['a','b','c'],
				userAgentPackageName: 'dev.yourapp.package',
				),
				MarkerLayer(
				markers: selected.map((w) {
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
		);
	}

	void _openWordSheet(BuildContext context, Word w) {
		final motoEntry = GlobalVars.wordMotos.firstWhere(
			(m) => m.wordId == w.id,
			orElse: () => WordMoto(wordId: w.id, moto: '-', word: '-'),
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
						'${w.name} —> ${motoEntry.moto}',
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
