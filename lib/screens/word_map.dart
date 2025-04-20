// lib/screens/word_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../global.dart';
import '../models.dart';
import 'package:intl/intl.dart';

class WordMapScreen extends StatelessWidget {
	const WordMapScreen({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
	final selected = GlobalVars.words
		.where((w) => GlobalVars.selectedWordIds.contains(w.id))
		.toList();

	if (selected.isEmpty) {
		return const Center(child: Text('Brak zaznaczonych ośrodków'));
	}

	final first = selected.first;
	final center = LatLng(first.latitude, first.longitude);

	return FlutterMap(
		options: MapOptions(
		initialCenter: center,
		initialZoom: 10,
		),
		children: [
			TileLayer(
				urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
				subdomains: const ['a', 'b', 'c'],
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
						// filter only events for this word
						final events = GlobalVars.examEvents
							.where((e) => e.wordId == w.id)
							.toList()
						..sort((a, b) => a.dateTime.compareTo(b.dateTime));

						showModalBottomSheet(
						context: context,
						isScrollControlled: true,
						builder: (ctx) => DraggableScrollableSheet(
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
										fontSize: 18, fontWeight: FontWeight.bold)),
								const SizedBox(height: 4),
								Text(w.address,
									style: const TextStyle(color: Colors.grey)),
								const Divider(height: 20),
								if (events.isEmpty)
									const Expanded(
										child: Center(
											child: Text('Brak terminów dla tego WORDu')))
								else
									Expanded(
									child: ListView.builder(
										controller: controller,
										itemCount: events.length,
										itemBuilder: (_, i) {
										final e = events[i];
										final formattedDate = DateFormat.yMMMd('pl_PL')
											.add_Hm()
											.format(e.dateTime);
										return ListTile(
											leading: const Icon(Icons.event),
											title: Text(formattedDate),
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
	);
	}
}
