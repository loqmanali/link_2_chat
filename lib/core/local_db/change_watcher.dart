// ignore_for_file: close_sinks
import 'dart:async';

/// "Read this now, and again after every write": the way a screen watches a
/// table without a code generator. A DAO calls [notify] after a write;
/// [watch] re-runs the read then, and reads never overlap.
class ChangeWatcher {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// A tick after every write.
  Stream<void> get changes => _changes.stream;

  void notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> close() => _changes.close();

  Stream<T> watch<T>(Future<T> Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? subscription;
    var reading = false;
    var again = false;
    Future<void> emit() async {
      if (reading) {
        again = true;
        return;
      }
      reading = true;
      do {
        again = false;
        try {
          final value = await read();
          if (!controller.isClosed) controller.add(value);
        } on Object catch (e, st) {
          if (!controller.isClosed) controller.addError(e, st);
        }
      } while (again);
      reading = false;
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = _changes.stream.listen((_) => emit());
        emit();
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
}
