import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../global.dart';

class LoginWebView extends StatefulWidget {
  const LoginWebView({super.key});

  @override
  State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
	late InAppWebViewController _webViewController;

	// Adres, na który serwer przekierowuje po zalogowaniu
	static const _successUrlPrefix = 'https://info-car.pl/new/';
	static const _nextPageUrl = 'https://info-car.pl/new/prawo-jazdy/sprawdz-wolny-termin';

	@override
	Widget build(BuildContext context) {
	return Scaffold(
		appBar: AppBar(title: const Text('Logowanie')),
		body: InAppWebView(
		initialUrlRequest: URLRequest(
			url: WebUri('https://info-car.pl/oauth2/login'),
		),

		shouldInterceptRequest:
			(InAppWebViewController controller, WebResourceRequest request) async {
			final url = request.url.toString();
			if (url.contains('/api/word/word-centers')) {
			print('🕵️‍♂️ Intercepted request to word-centers');
			print('Method: ${request.method}');
			print('Headers:');
			request.headers?.forEach((key, value) {
				print('  $key: $value');
			});
			}
			// zwracamy null, żeby WebView kontynuowało normalne ładowanie
			return null;
		},

		onLoadStop: (controller, uri) async {
			final url = uri?.toString() ?? '';
			// Sprawdzamy, czy URL zaczyna się od _successUrlPrefix (po zalogowaniu)
			if (url.startsWith(_successUrlPrefix)) {
				// Gdy użytkownik jest zalogowany, uruchamiamy JS do kliknięcia w link
				print('User logged in, now clicking the link...');
				await controller.evaluateJavascript(source: """
				const link = document.querySelector('a[href="/new/prawo-jazdy/sprawdz-wolny-termin"]');
				if (link) {
					link.click();
				}
				""");
			}
		},

		onWebViewCreated: (controller) {
			_webViewController = controller;
		},
		),
	);
	}
}
