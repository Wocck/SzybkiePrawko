import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginWebView extends StatefulWidget {
	const LoginWebView({super.key});

	@override
	State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
	late InAppWebViewController webViewController;

	@override
	Widget build(BuildContext context) {
	return Scaffold(
		appBar: AppBar(title: const Text('Zaloguj się do info-car')),
		body: InAppWebView(
		initialUrlRequest: URLRequest(
			url: WebUri('https://info-car.pl/oauth2/login'),
		),
		onWebViewCreated: (controller) {
			webViewController = controller;
		},
		onLoadStop: (controller, url) async {
			if (url == null) return;
			
			final history = await controller.getCopyBackForwardList();
			if (history != null && history.list != null) {
			for (final entry in history.list!) {
				final uriStr = entry.url.toString();
				if (uriStr.contains('/sprawdz-wolny-termin')) {
				final cookies = await CookieManager.instance()
					.getCookies(url: WebUri(uriStr));
				for (final cookie in cookies) {
					if (cookie.name.toLowerCase().contains('authorization') ||
						cookie.value.startsWith('Bearer')) {
					final prefs = await SharedPreferences.getInstance();
					await prefs.setString('auth_token', cookie.value);
					if (context.mounted) {
						print('[DEBUG] Zapisuję token: ${cookie.value}');
						Navigator.pop(context, cookie.value);
					}
					return;
					}
				}
				}
			}
			}
		},
		),
	);
	}
}
