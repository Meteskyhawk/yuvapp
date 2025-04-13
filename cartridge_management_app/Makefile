.PHONY: setup test test-coverage format lint build-runner clean build-android build-ios

# Setup project dependencies
setup:
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

# Run all tests
test:
	flutter test

# Run tests with coverage report
test-coverage:
	flutter test --coverage
	lcov --remove coverage/lcov.info '**/*.g.dart' '**/*.freezed.dart' -o coverage/lcov.info
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html

# Format the code
format:
	flutter format lib test

# Check for lint issues
lint:
	flutter analyze

# Run build_runner to generate code
build-runner:
	flutter pub run build_runner build --delete-conflicting-outputs

# Clean the project
clean:
	flutter clean
	flutter pub get

# Build Android APK
build-android:
	flutter build apk --release

# Build iOS archive
build-ios:
	flutter build ios --release --no-codesign

# Run the app in development mode
dev:
	flutter run --flavor development --target lib/main.dart

# Run the app in production mode
prod:
	flutter run --flavor production --target lib/main.dart

# Display available commands
help:
	@echo "Available commands:"
	@echo "  make setup           - Set up the project dependencies"
	@echo "  make test            - Run all tests"
	@echo "  make test-coverage   - Run tests with coverage report"
	@echo "  make format          - Format the code"
	@echo "  make lint            - Check for lint issues"
	@echo "  make build-runner    - Generate code with build_runner"
	@echo "  make clean           - Clean the project"
	@echo "  make build-android   - Build Android APK"
	@echo "  make build-ios       - Build iOS archive"
	@echo "  make dev             - Run app in development mode"
	@echo "  make prod            - Run app in production mode" 