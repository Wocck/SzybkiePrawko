import 'models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GlobalVars {
	static List<Province> provinces = [];
	static List<Word> words = [];
	static List<ExamEvent> examEvents = [];
	static String bearerToken = '';
	static List<int> selectedWordIds = [];
	static bool sessionActive = false;
	static List<WordMoto> wordMotos = [];

	static final maxWords = 4;
}

class CredentialsStorage {
	static final _storage = FlutterSecureStorage();

	static const _keyLogin = 'login';
	static const _keyPassword = 'password';

	static Future<void> saveCredentials(String login, String password) async {
		await _storage.write(key: _keyLogin,    value: login);
		await _storage.write(key: _keyPassword, value: password);
	}

	static Future<String?> getLogin() async {
		return await _storage.read(key: _keyLogin);
	}

	static Future<String?> getPassword() async {
		return await _storage.read(key: _keyPassword);
	}

	static Future<void> deleteCredentials() async {
		await _storage.delete(key: _keyLogin);
		await _storage.delete(key: _keyPassword);
	}
}

class Secrets {
	static final login = const String.fromEnvironment('LOGIN');
	static final password = const String.fromEnvironment('PASSWORD');
}