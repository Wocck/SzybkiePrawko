class Province {
	final int id;
	final String name;
	Province({required this.id, required this.name});
	factory Province.fromJson(Map<String, dynamic> j) => Province(
		id: j['id'] as int,
		name: j['name'] as String,
	);
}

class Word {
	final int id;
	final String name;
	final int provinceId;
	Word({required this.id, required this.name, required this.provinceId});
	factory Word.fromJson(Map<String, dynamic> j) => Word(
		id: j['id'] as int,
		name: j['name'] as String,
		provinceId: j['provinceId'] as int,
	);
}

class ExamEvent {
	final int wordId;
	final String wordName;
	final DateTime dateTime;
	final int places;

	ExamEvent({
		required this.wordId,
		required this.wordName,
		required this.dateTime,
		required this.places,
	});
}