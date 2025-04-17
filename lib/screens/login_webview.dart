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

	static const _successUrlPrefix = 'https://info-car.pl/new/';

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
				if (request.headers?.containsKey("Authorization") ?? false) {
				final authorizationHeader = request.headers?["Authorization"];
				if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
				final token = authorizationHeader.substring(7); // Pobieramy token bez "Bearer "
					GlobalVars.bearerToken = token;
					//print("token = " + token);
					Navigator.pop(context);
				}
				}
			}
			return null;
		},

		onLoadStop: (controller, uri) async {
			final url = uri?.toString() ?? '';
			if (url.startsWith(_successUrlPrefix)) {
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
