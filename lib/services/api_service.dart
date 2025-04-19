

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:szybkie_prawko/global.dart';
import 'package:szybkie_prawko/models.dart';

class ApiService {

	static Future<List<ExamEvent>> fetchExamSchedules(List<int> selectedWordIds, List<Word> allWords) async {
		final token = GlobalVars.bearerToken;
		if (token.isEmpty) throw Exception('Brak tokena');

		final now = DateTime.now();
		final startDate = DateTime(
			now.year, now.month, now.day,
			now.hour, now.minute,
		).toUtc();
		final endMonth = DateTime(now.year, now.month + 1, now.day,
			now.hour, now.minute,
		).toUtc();

		final List<ExamEvent> allEvents = [];

		for (final wId in selectedWordIds) {
			final body = jsonEncode({
			"category": "A",
			"startDate": startDate.toIso8601String(),
			"endDate": endMonth.toIso8601String(),
			"wordId": wId.toString(),
			});

			http.Response res;
			int attempts = 0;
			const int maxAttempts = 4;
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
				break;
			}
			if (attempts < maxAttempts) {
				await Future.delayed(Duration(seconds: 8));
			}
			} while (attempts < maxAttempts);

			final wordName = allWords.firstWhere((w) => w.id == wId).name;

			if (res.statusCode != 200 || res.body.trimLeft().startsWith('<html')) {
				debugPrint('Pominięto word \'$wordName\' po $attempts próbach, status ${res.statusCode}');
				continue;
			}
			if (res.statusCode == 401) {
				throw UnauthenticatedException();
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
}

class UnauthenticatedException {
	@override
	String toString() {
		return 'Nieautoryzowany';
	}
}