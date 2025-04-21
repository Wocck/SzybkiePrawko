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
	final String address;
	final double latitude;
	final double longitude;

	 Word({
		required this.id,
		required this.name,
		required this.provinceId,
		required this.address,
		required this.latitude,
		required this.longitude,
	});
	
	factory Word.fromJson(Map<String, dynamic> j) => Word(
		id: j['id'] as int,
		name: j['name'] as String,
		provinceId: j['provinceId'] as int,
		address: j['address'] as String,
		latitude: double.parse(j['latitude'] as String),
		longitude: double.parse(j['longitude'] as String),
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

class WordMoto {
	final int wordId;
	final String word;
	final String moto;

	WordMoto({
		required this.wordId,
		required this.word,
		required this.moto
	});

	factory WordMoto.fromJson(Map<String, dynamic> j) => WordMoto(
		wordId:int.tryParse(j['ID']) as int,
		word: j['WORD'] as String,
		moto: j['MOTO'] as String,
	);
}