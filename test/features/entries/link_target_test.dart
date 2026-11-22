import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/features/entries/domain/link_target.dart';

void main() {
  test('sanitize strips everything but digits', () {
    expect(LinkTarget.sanitize('+20 100-123 (4567)'), '201001234567');
    expect(LinkTarget.sanitize('201001234567'), '201001234567');
    expect(LinkTarget.sanitize(''), '');
  });

  test('whatsapp and telegram links carry the sanitized number', () {
    expect(
      LinkTarget.whatsapp('+20 100 123 4567'),
      'https://wa.me/201001234567',
    );
    expect(
      LinkTarget.telegram('+20 100 123 4567'),
      'https://t.me/201001234567',
    );
  });

  test('whatsappWithMessage URL-encodes the message', () {
    expect(
      LinkTarget.whatsappWithMessage('201001234567', 'hello there'),
      'https://wa.me/201001234567?text=hello%20there',
    );
  });

  test('forPlatform picks by the enum', () {
    expect(
      LinkTarget.forPlatform('2010', LinkPlatform.whatsapp),
      'https://wa.me/2010',
    );
    expect(
      LinkTarget.forPlatform('2010', LinkPlatform.telegram),
      'https://t.me/2010',
    );
  });
}
