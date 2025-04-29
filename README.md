# SzybkiePrawko

<p align="center">
	<a href="https://flutter.dev">
		<img src="https://img.shields.io/badge/Flutter-3.0-blue?logo=flutter" alt="Flutter version"/>
	</a>
	<a href="https://dart.dev">
		<img src="https://img.shields.io/badge/Dart-2.x-blue?logo=dart" alt="Dart version"/>
	</a>
	<a href="https://github.com/TwojRepo/LICENSE">
		<img src="https://img.shields.io/badge/License-GPLv3-green" alt="License GPLv3"/>
	</a>
	<a href="https://github.com/TwojRepo/actions">
		<img src="https://img.shields.io/github/workflow/status/TwojRepo/SzybkiePrawko/Build?label=build&logo=github" alt="Build status"/>
	</a>
</p>


SzybkiePrawko is a Flutter application that allows you to search for exam centers, view available exam dates on a calendar, and locate centers on a map. It depends on `info-car.pl` website for data retrieval.

## Prerequisites

- `Flutter SDK` (Channel stable, version 3.0 or higher)
- `Dart SDK` (included with Flutter)
- `Android SDK` (with an emulator or a connected device)
- `VS Code` (optional) with the Flutter and Dart extensions installed

## Getting Started

1. Clone the repository
	```bash
	git clone <your-repo-url>
	cd <project-folder>
	```

2. Install dependencies
	```bash
	flutter pub get
	``` 

## Running in Debug Mode (Windows)

```bash
flutter run -d windows \
	--dart-define=LOGIN='<your-login>' \
	--dart-define=PASSWORD='<your-password>'
```

## Building a Release APK

```bash
flutter build apk --release \
	--dart-define=LOGIN='<your-login>' \
	--dart-define=PASSWORD='<your-password>'
```
Once the build completes, the APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`.

## Project Structure

```
lib/
├── main.dart		# Application entrypoint
├── global.dart		# Global variables & session state
├── models.dart		# Data models (Word, ExamEvent, WordMoto)
├── screens/
│	├── search_param.dart	# Search & filter UI
│	├── calendar.dart		# Calendar view of exam dates
│	└── word_map.dart		# Map with markers & BottomSheet
└── services/
	└── api_service.dart	# HTTP interactions & data fetching
assets/
└── moto.json		# Preloaded JSON data for vehicle models
```