/// Abstract clock for injectable time (tests / sync).
abstract class Clock {
  DateTime now();
}

/// Wall-clock [DateTime.now] implementation.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
