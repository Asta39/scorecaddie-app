import 'dart:async';

/// Emits [load]'s result now and then every [every] while listened to.
///
/// Used instead of Supabase realtime `.stream()` on the User table: realtime
/// isn't enabled there, and its first fetch reads every column, which private
/// columns (email) no longer allow.
Stream<T> pollStream<T>(Future<T> Function() load, {Duration every = const Duration(seconds: 30)}) {
  late final StreamController<T> c;
  Timer? timer;
  Future<void> tick() async {
    try {
      final v = await load();
      if (!c.isClosed) c.add(v);
    } catch (e, s) {
      if (!c.isClosed) c.addError(e, s);
    }
  }

  c = StreamController<T>(
    onListen: () {
      tick();
      timer = Timer.periodic(every, (_) => tick());
    },
    onCancel: () => timer?.cancel(),
  );
  return c.stream;
}
