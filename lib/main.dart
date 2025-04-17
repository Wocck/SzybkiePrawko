import 'package:flutter/material.dart';
import 'screens/search_param.dart';
import 'screens/calendar.dart';
import 'global.dart';
import 'models.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
	WidgetsFlutterBinding.ensureInitialized();
	await initializeDateFormatting('pl_PL');

	// ——— pobranie województw i ośrodków ———
	final res = await http.get(Uri.parse('https://info-car.pl/api/word/word-centers'));
	if (res.statusCode == 200) {
		final jsonString = utf8.decode(res.bodyBytes);
		final data = jsonDecode(jsonString) as Map<String, dynamic>;
		GlobalVars.provinces = (data['provinces'] as List)
			.map((j) => Province.fromJson(j as Map<String, dynamic>))
			.toList();
		GlobalVars.words = (data['words'] as List)
			.map((j) => Word.fromJson(j as Map<String, dynamic>))
			.toList();
	}

	runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
	return MaterialApp(
		title: 'Szybkie Prawko',
		theme: ThemeData(
		colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
		useMaterial3: true,
		),
		home: const PageContainer(),
	);
	}
}

class PageContainer extends StatefulWidget {
	const PageContainer({super.key});

	@override
	State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
	final PageController _controller = PageController();
	int _currentPage = 0;

	void _onPageChanged(int index) {
		setState(() {
			_currentPage = index;
		});
	}

	Widget _buildIndicator(int index) {
		return GestureDetector(
		onTap: () {
			_controller.animateToPage(
			index,
			duration: const Duration(milliseconds: 300),
			curve: Curves.easeInOut,
			);
		},
		child: Container(
			width: 12,
			height: 12,
			margin: const EdgeInsets.symmetric(horizontal: 6),
			decoration: BoxDecoration(
			shape: BoxShape.circle,
			color: _currentPage == index ? Colors.blue : Colors.grey,
			),
		),
		);
	}

	@override
	Widget build(BuildContext context) {
	return Scaffold(
		body: PageView(
		controller: _controller,
		onPageChanged: _onPageChanged,
		children: const [
			SearchParam(),
			CalendarScreen(),
		],
		),
		bottomNavigationBar: Padding(
		padding: const EdgeInsets.all(8.0),
		child: Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: List.generate(2, _buildIndicator),
		),
		),
	);
	}
}
