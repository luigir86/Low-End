import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Runs [work] away from the screen's thread where there is one: in an
/// isolate on the phone. A web page has no isolates, so there it runs on
/// the screen's thread, once the current frame is done.
Future<T> offThread<T>(FutureOr<T> Function() work) =>
    kIsWeb ? Future(work) : Isolate.run(work);
