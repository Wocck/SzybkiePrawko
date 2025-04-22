import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:szybkie_prawko/global.dart';
import 'package:szybkie_prawko/models.dart';
import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ApiService {
	static const _loginUrl = 'https://info-car.pl/oauth2/login';
	static const _successUrlPrefix = 'https://info-car.pl/new';
	static const _apiWordEndpoint = '/api/word/word-centers';
	static const _targetTokenPath = '/new/prawo-jazdy/sprawdz-wolny-termin';
	static const _wordCenters = 'https://info-car.pl/api/word/word-centers';
	static const _checkToken = 'https://info-car.pl/api/word/word-centers/exam-schedule';

	static Future<void> checkSession() async {
		final token = GlobalVars.bearerToken;

		bool isActive = false;
		if (token.isNotEmpty) {
			try {
				final now = DateTime.now().toUtc();
				final body = jsonEncode({
					"category": "A",
					"startDate": now.toIso8601String(),
					"endDate": now.add(const Duration(days: 1)).toIso8601String(),
					"wordId": "8001",
				});
				final res = await http.put(
					Uri.parse(_checkToken),
					headers: {
					'Authorization': 'Bearer $token',
					'Content-Type': 'application/json',
					},
					body: body,
				);
				isActive = res.statusCode == 200 && !res.body.trimLeft().startsWith('<html');
			} catch (_) {
				isActive = false;
			}
		}

		GlobalVars.sessionActive = isActive;

		if (!isActive) {
			debugPrint('Sesja wygasła, logowanie ponowne...');
			final newToken = await ApiService.loginHeadless();
			GlobalVars.sessionActive = newToken.isNotEmpty;
			return;
		}

		if (isActive && (GlobalVars.words.isEmpty || GlobalVars.provinces.isEmpty)) {
			await ApiService.loadWordCenters();
		}
	}

	static Future<void> loadWordCenters() async {
		try {
			final res = await http
				.get(Uri.parse(_wordCenters))
				.timeout(const Duration(seconds: 5));
			if (res.statusCode == 200) {
				final data =
					jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
				GlobalVars.provinces = (data['provinces'] as List)
					.map((j) => Province.fromJson(j as Map<String, dynamic>))
					.toList();
				GlobalVars.words = (data['words'] as List)
					.map((j) => Word.fromJson(j as Map<String, dynamic>))
					.toList();
			} else {
				debugPrint('Niepowodzenie pobierania słowników: ${res.statusCode}');
				GlobalVars.provinces = [];
				GlobalVars.words = [];
			}
		} catch (e) {
			debugPrint('Błąd podczas pobierania słowników: $e');
			GlobalVars.provinces = [];
			GlobalVars.words = [];
		}
	}

	static Future<String> loginHeadless() async {
		final completer = Completer<String>();
		
		final login = await CredentialsStorage.getLogin() ?? '';
		final password = await CredentialsStorage.getPassword() ?? '';

		late final HeadlessInAppWebView headless;
		bool injected = false;

		headless = HeadlessInAppWebView(
			initialUrlRequest: URLRequest(url: WebUri(_loginUrl)),
			onLoadStop: (controller, uri) async {
				final url = uri?.toString() ?? '';

				if (!injected && url.contains('/oauth2/login')) {
					injected = true;
					await controller.evaluateJavascript(source: """
					(function tryFill() {
						const u   = document.querySelector('.login-input');
						const p   = document.querySelector('.password-input');
						const btn = document.getElementById('register-button') 
									|| document.querySelector('button.submit-btn');
						if (u && p && btn) {
							u.value = ${jsonEncode(login)};
							p.value = ${jsonEncode(password)};
							btn.click();
						} else {
							setTimeout(tryFill, 500);
						}
					})();
					""");
				}

				if (url.startsWith(_successUrlPrefix)) {
					await controller.evaluateJavascript(source: """
					(function tryClickTokenLink() {
						const link = document.querySelector('a[href="$_targetTokenPath"]');
						if (link) {
							link.click();
						} else {
							setTimeout(tryClickTokenLink, 500);
						}
					})();
					""");
				}
			},
			shouldInterceptRequest: (controller, req) async {
				final requestUrl = req.url.toString();
				if (requestUrl.contains(_apiWordEndpoint)) {
					final auth = req.headers?['Authorization'];
					if (auth != null && auth.startsWith('Bearer ')) {
						final token = auth.substring(7);
						if (!completer.isCompleted) {
							completer.complete(token);
						}
						await headless.dispose();
					}
				}
				return null;
			},
				onConsoleMessage: (_, msg) {
				debugPrint('WebView console: ${msg.message}');
			},
		);

		await headless.run();

		final token = await completer.future;
		GlobalVars.bearerToken = token;
		return token;
	}

	static Future<List<ExamEvent>> fetchExamSchedules(
		List<int> selectedWordIds, List<Word> allWords,
		{
			bool useTimeFilter = false,
			TimeOfDay? startTime,
			TimeOfDay? endTime,
			void Function(String wordName)? onError,
		}) async {
		final now = DateTime.now().toUtc();

		final startDate = useTimeFilter && startTime != null
			? _toUtcDateTime(startTime)
			: now;
		final endDate = useTimeFilter && endTime != null
			? _toUtcDateTime(endTime)
			: DateTime(
				now.year, now.month + 1, now.day,
				now.hour, now.minute,
			).toUtc();


		final List<ExamEvent> allEvents = [];
		final int wordCount = selectedWordIds.length;
		final delay = _getDelay(wordCount);

		for (final wId in selectedWordIds) {
			final token = GlobalVars.bearerToken;

			final body = jsonEncode({
				"category": "A",
				"startDate": startDate.toIso8601String(),
				"endDate": endDate.toIso8601String(),
				"wordId": wId.toString(),
			});

			http.Response res;
			int attempts = 0;
			const int maxAttempts = 4;
			bool success = false;
			do {
				attempts++;
				res = await http.put(
					Uri.parse('https://info-car.pl/api/word/word-centers/exam-schedule'),
					headers: {
						'Authorization': 'Bearer $token',
						'Content-Type':  'application/json',
					},
					body: body,
				);
				final isHtmlError = res.body.trimLeft().startsWith('<html');
				if (res.statusCode == 200 && !isHtmlError) {
					success = true;
					break;
				}
				if (attempts < maxAttempts) {
					await Future.delayed(delay);
				}
			} while (attempts < maxAttempts);

			final wordName = allWords.firstWhere((w) => w.id == wId).name;
			if (res.statusCode != 200 || res.body.trimLeft().startsWith('<html')) {
				success = false;
				continue;
			}
			if (res.statusCode == 401) {
				success = false;
				throw UnauthenticatedException();
			}

			 if (!success) {
				if (onError != null) onError(wordName);
				continue;
			}

			final data = jsonDecode(res.body) as Map<String, dynamic>;
			final schedule = data['schedule'] as Map<String, dynamic>;
			final days = schedule['scheduledDays'] as List<dynamic>;

			for (final day in days) {
				final hours = (day['scheduledHours'] as List<dynamic>);
				for (final slot in hours) {
					final practice = (slot['practiceExams'] as List<dynamic>);
					for (final exam in practice) {
						final dt = DateTime.parse(exam['date'] as String);
						allEvents.add(ExamEvent(
						wordId: wId,
						wordName: wordName,
						dateTime: dt,
						places: exam['places'] as int,
						));
					}
				}
			}
		}
		return allEvents;
	}

	static Duration _getDelay(int wordCount) {
		return const Duration(milliseconds: 200);
	}

	static DateTime _toUtcDateTime(TimeOfDay t) {
		final now = DateTime.now();
		return DateTime(now.year, now.month, now.day, t.hour, t.minute).toUtc();
	}
}

class UnauthenticatedException implements Exception {
	@override
	String toString() => 'Nieautoryzowany';
}


