name: Build APK
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'

      - name: Create Flutter project
        run: flutter create --org com.marley --project-name marley_tutor marley_app

      - name: Extract source files
        run: |
          unzip marley_tutor_flutter.zip
          cp -r marley_tutor/lib/* marley_app/lib/
          cp marley_tutor/pubspec.yaml marley_app/pubspec.yaml

      - name: Get dependencies
        run: |
          cd marley_app
          flutter pub get

      - name: Build APK
        run: |
          cd marley_app
          flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: marley-apk
          path: marley_app/build/app/outputs/flutter-apk/app-release.apk
