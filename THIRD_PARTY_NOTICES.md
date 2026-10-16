# Third-party components

Low End itself is released under the [MIT License](LICENSE). It is built with the open-source components below. All of them are permissive licences (MIT, BSD, Apache-2.0, zlib, public domain) that allow free use and redistribution, including in a free app on Google Play. The full text of each licence ships with the app: **Settings → About → View licences** lists every Flutter and Dart package, and the files named below hold the texts of the native parts.

Exact versions of every package are in [pubspec.lock](pubspec.lock). Keep this file in step with `pubspec.yaml` when a dependency is added or removed.

## What the app uses directly

| Component | Version | Used for | Licence |
| --- | --- | --- | --- |
| [Flutter](https://flutter.dev) (framework and engine) | 3.47 | The whole app | BSD-3-Clause |
| [flutter_soloud](https://pub.dev/packages/flutter_soloud) | 5.2.1 | Audio engine: metronome, drone, piano | MIT |
| [record](https://pub.dev/packages/record) (+ `record_android`) | 7.1.2 | Microphone for the tuner | BSD-3-Clause |
| [audio_service](https://pub.dev/packages/audio_service) (+ `audio_session`, `rxdart`) | 0.18.19 | Playing with the screen off, media notification | MIT (`rxdart`: Apache-2.0) |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 2.5.6 | Settings kept on the phone | BSD-3-Clause |
| [wakelock_plus](https://pub.dev/packages/wakelock_plus) | 1.8.1 | Keep the screen on (optional) | BSD-3-Clause |
| [url_launcher](https://pub.dev/packages/url_launcher) | 6.3.3 | Opens the source-code link | BSD-3-Clause |
| [intl](https://pub.dev/packages/intl) | 0.20.3 | Languages (English, Italian) | BSD-3-Clause |

Build and test only (not in the app): `flutter_test`, `flutter_lints`.

## Native code inside flutter_soloud

- **SoLoud** audio engine, by Jari Komppa: zlib/libpng licence. It bundles a few small libraries under equally liberal terms (public domain, zlib, MIT); see `src/soloud/LICENSE` in the package.
- **Signalsmith Stretch** and **Signalsmith Linear**: MIT.
- The Xiph codecs (Ogg, Vorbis, Opus, FLAC) are **left out** of the build (`no_xiph_libs` in `pubspec.yaml`), because the app plays only its own short samples.

## Transitive packages

Everything else that `pubspec.lock` lists comes from the Dart and Flutter teams or from small well-known authors, under these licences:

- **BSD-3-Clause**: `async`, `characters`, `collection`, `crypto`, `ffi`, `file`, `fixnum`, `glob`, `hooks`, `http`, `http_parser`, `jni` and its helpers, `logging`, `meta`, `path`, `path_provider*`, `platform`, `plugin_platform_interface`, `process`, `pub_semver`, `source_span`, `stack_trace`, `string_scanner`, `typed_data`, `vector_math`, `web`, `win32`, `xdg_directories`, `yaml`, and the platform packages of the plugins above.
- **BSD-2-Clause**: `sqflite*` (used by the cache of `audio_service`).
- **MIT**: `audio_service_*`, `audio_session`, `flutter_cache_manager`, `petitparser`, `synchronized`, `uuid`, `xml`.
- **Apache-2.0**: `clock`, `material_color_utilities`, `rxdart`.
- **MPL-2.0**: `dbus`. It is used only by the Linux version of `wakelock_plus` and is **not part of the Android app**.

## Android libraries

The Android build also contains AndroidX, Kotlin (`kotlin-stdlib`, `kotlinx-coroutines`), Okio, ReLinker, JSpecify and Guava's `listenablefuture`, all under **Apache-2.0**.

## Sounds and images

- **Piano notes**: *Salamander Grand Piano V3* by Alexander Holm, released into the **public domain** on 4 March 2022. Details in [assets/piano/README.md](assets/piano/README.md).
- **Material Icons** (Flutter's built-in icon font): Apache-2.0.

## Checks made

On 16 October 2026 every package in `pubspec.lock` (108) and every external Android library of the release build (88) was checked against the [OSV](https://osv.dev) vulnerability database, with no known vulnerability found.
