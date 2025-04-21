import 'package:flutter/material.dart';
import 'screens/search_param.dart';
import 'screens/calendar.dart';
import 'global.dart';
import 'models.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screens/word_map.dart';
import 'package:flutter/services.dart' show rootBundle;


void main() async {
	WidgetsFlutterBinding.ensureInitialized();
	await initializeDateFormatting('pl_PL');
	await loadWordMotos();

	try {
		final res = await http.get(Uri.parse('https://info-car.pl/api/word/word-centers'))
			.timeout(const Duration(seconds: 5));
		if (res.statusCode == 200) {
			final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
			GlobalVars.provinces = (data['provinces'] as List)
				.map((j) => Province.fromJson(j as Map<String, dynamic>))
				.toList();
			GlobalVars.words = (data['words'] as List)
				.map((j) => Word.fromJson(j as Map<String, dynamic>))
				.toList();
		} else {
			debugPrint('Niepowodzenie pobierania słowników: ${res.statusCode}');
		}
	} catch (e) {

	debugPrint('Błąd podczas pobierania słowników: $e');
	GlobalVars.provinces = [];
	GlobalVars.words = [];
	}

	runApp(const MyApp());
}

class MyApp extends StatefulWidget {
	const MyApp({super.key});
	@override
	State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
	ThemeMode _themeMode = ThemeMode.system;

	void _toggleTheme() {
	setState(() {
		_themeMode = _themeMode == ThemeMode.light
		? ThemeMode.dark
		: ThemeMode.light;
	});
	}

	@override
	Widget build(BuildContext context) {
	return MaterialApp(
		title: 'Szybki egzamin',
		themeMode: _themeMode,

		theme: ThemeData(
			brightness: Brightness.light,
			colorScheme: ColorScheme.fromSeed(
			seedColor: Colors.blue,
			brightness: Brightness.light,  // <-- dodajemy
			),
			useMaterial3: true,
		),

		darkTheme: ThemeData(
			brightness: Brightness.dark,
			colorScheme: ColorScheme.fromSeed(
				seedColor: Colors.blue,
				brightness: Brightness.dark,  // <-- i tutaj
			),
			useMaterial3: true,
		),

		home: PageContainer(onToggleTheme: _toggleTheme),
	);
	}
}

class PageContainer extends StatefulWidget {
	final VoidCallback onToggleTheme;
	const PageContainer({required this.onToggleTheme, super.key});

	@override
	State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
	final PageController _controller = PageController();
	int _currentPage = 0;

	void _onPageChanged(int index) {
	setState(() => _currentPage = index);
	}

	Widget _buildIndicator(int index) {
	return GestureDetector(
		onTap: () => _controller.animateToPage(
		index,
		duration: const Duration(milliseconds: 300),
		curve: Curves.easeInOut,
		),
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
		appBar: AppBar(
		title: const Text('Szybki egzamin'),
		actions: [
			IconButton(
			icon: Icon(
				Theme.of(context).brightness == Brightness.dark
				? Icons.light_mode
				: Icons.dark_mode,
			),
			onPressed: widget.onToggleTheme,
			),
		],
		),
		body: PageView(
		controller: _controller,
		onPageChanged: _onPageChanged,
		children: [
			SearchParam(),
			CalendarScreen(events: GlobalVars.examEvents),
			WordMapScreen(),
		],
		),
		bottomNavigationBar: Padding(
		padding: const EdgeInsets.all(8.0),
		child: Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: List.generate(3, _buildIndicator),
		),
		),
	);
	}
}

Future<void> loadWordMotos() async {
	final jsonStr = await rootBundle.loadString('assets/moto.json');
	final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;

	final motos = jsonList
		.map((e) => WordMoto.fromJson(e as Map<String, dynamic>))
		.toList();
	GlobalVars.wordMotos = motos;
}