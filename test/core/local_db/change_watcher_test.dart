import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';

void main() {
  test('watch reads now and again after every notify', () async {
    final watcher = ChangeWatcher();
    var value = 1;
    final seen = <int>[];
    final sub = watcher.watch(() async => value).listen(seen.add);

    await pumpEventQueue();
    value = 2;
    watcher.notify();
    await pumpEventQueue();

    expect(seen, [1, 2]);
    await sub.cancel();
    await watcher.close();
  });

  test(
    'a notify during a read triggers one more read, never an overlap',
    () async {
      final watcher = ChangeWatcher();
      var running = 0;
      var maxRunning = 0;
      var reads = 0;
      final sub = watcher
          .watch(() async {
            running++;
            maxRunning = maxRunning > running ? maxRunning : running;
            reads++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            running--;
            return reads;
          })
          .listen((_) {});

      await Future<void>.delayed(const Duration(milliseconds: 1));
      watcher
        ..notify()
        ..notify();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(maxRunning, 1);
      expect(
        reads,
        2,
      ); // the first read, plus one for the notifies that piled up
      await sub.cancel();
      await watcher.close();
    },
  );
}
