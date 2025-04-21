import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../global.dart';
import '../models.dart';
import 'package:intl/intl.dart';
import 'package:szybkie_prawko/services/api_service.dart';

class WordMapScreen extends StatelessWidget {
	const WordMapScreen({Key? key}) : super(key: key);

	static final LatLngBounds polandBounds = LatLngBounds(
		LatLng(49.0, 14.0),
		LatLng(55.0, 24.5),
	);

	@override
	Widget build(BuildContext context) {
		final size = MediaQuery.of(context).size;
		final horizontalMargin = size.width * 0.05;
		final verticalMargin   = size.height * 0.05;

		final selected = GlobalVars.words
			.where((w) => GlobalVars.selectedWordIds.contains(w.id))
			.toList();
		if (selected.isEmpty) {
		return const Center(child: Text('Brak zaznaczonych ośrodków'));
		}
		final first = selected.first;
		final center = polandBounds.center;

		return Padding (
			padding: EdgeInsets.fromLTRB(
				horizontalMargin,
				verticalMargin,
				horizontalMargin,
				verticalMargin,
			),
			child: FlutterMap(
				options: MapOptions(
				initialCenter: center,
				initialZoom: 10,
				cameraConstraint: CameraConstraint.contain(bounds: polandBounds),
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
					Text(w.name,
						style: const TextStyle(
						fontSize: 18, fontWeight: FontWeight.bold
						)
					),
					const SizedBox(height: 4),
					Text(w.address, style: const TextStyle(color: Colors.grey)),
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
							final now = DateTime.now().toUtc();
							final nextMonth = DateTime(
								now.year, now.month+1, now.day,
								now.hour, now.minute
							).toUtc();
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
								ScaffoldMessenger.of(ctx).showSnackBar(
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
