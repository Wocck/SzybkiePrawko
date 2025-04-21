import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../global.dart';

class LoginWebView extends StatefulWidget {
  const LoginWebView({super.key});

  @override
  State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {

	static const _loginUrl = 'https://info-car.pl/oauth2/login';
	static const _successUrlPrefix = 'https://info-car.pl/new';
	static const _apiWord = '/api/word/word-centers';
	static const _targetTokenPath = '/new/prawo-jazdy/sprawdz-wolny-termin';
	bool _clicked = false;

	@override
	void initState() {
		super.initState();
		_clicked = false;
	}

	@override
	Widget build(BuildContext context) {
	return Scaffold(
		appBar: AppBar(title: const Text('Logowanie')),
		body: InAppWebView(
		initialUrlRequest: URLRequest(
			url: WebUri(_loginUrl)
		),

		shouldInterceptRequest:
			(InAppWebViewController controller, WebResourceRequest request) async {
			final url = request.url.toString();
			if (url.contains(_apiWord)) {
				if (request.headers?.containsKey("Authorization") ?? false) {
				final authorizationHeader = request.headers?["Authorization"];
				if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
					final token = authorizationHeader.substring(7);
					GlobalVars.bearerToken = token;
					Navigator.pop(context, token);
					debugPrint(token);
				}
				}
			}
			return null;
		},

		onLoadStop: (controller, uri) async {
			final url = uri?.toString() ?? '';
			 if (!_clicked && (url == _successUrlPrefix || url == '$_successUrlPrefix/')) {
				_clicked = true;
				await controller.evaluateJavascript(source: """
					(function clickWhenReady() {
						const link = document.querySelector('a[href="$_targetTokenPath"]');
						if (link) {
						link.click();
						} else {
						setTimeout(clickWhenReady, 500);
						}
					})();
				""");
			}
		},
		
		),
	);
	}
}
