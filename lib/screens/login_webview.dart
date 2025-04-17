import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LoginWebView extends StatefulWidget {
  const LoginWebView({super.key});

  @override
  State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
	late InAppWebViewController _webViewController;

	// Adres, na który serwer przekierowuje po zalogowaniu
	static const _successUrlPrefix = 'https://info-car.pl/new/';

	@override
	Widget build(BuildContext context) {
	return Scaffold(
		appBar: AppBar(title: const Text('Logowanie')),
		body: InAppWebView(
		initialUrlRequest: URLRequest(
			url: WebUri('https://info-car.pl/oauth2/login'),
		),
		onWebViewCreated: (controller) {
			_webViewController = controller;
		},
		onLoadStop: (controller, url) async {
			final current = url?.toString() ?? '';
			if (current.startsWith(_successUrlPrefix)) {
			// 1. Po przekierowaniu na /new/ pobieramy ciasteczka
			final cookieManager = CookieManager.instance();
			final cookies = await cookieManager.getCookies(
				url: WebUri('https://info-car.pl/oauth2/login'),
			);

			// 2. Szukamy ciasteczka device-cookie
			String deviceCookieValue = '';
			for (var cookie in cookies) {
				if (cookie.name == 'device-cookie') {
				deviceCookieValue = cookie.value.toString();
				break;
				}
			}

			if (deviceCookieValue.isNotEmpty) {
				Navigator.of(context).pop(deviceCookieValue);
				print("[DEBUG] Token = " + deviceCookieValue);
			} else {
				ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Nie odczytano device-cookie')),
				);
			}
			}
		},
		),
	);
	}
}
