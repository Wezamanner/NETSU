import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/core/utils/phone_number.dart';

void main() {
  test('normalizes Ethiopian mobile numbers', () {
    expect(PhoneNumber.normalize('0911000001'), '+251911000001');
    expect(PhoneNumber.normalize('251911000001'), '+251911000001');
    expect(PhoneNumber.normalize('+251 911 000 001'), '+251911000001');
  });

  test('rejects numbers that are not 09 mobiles', () {
    expect(PhoneNumber.normalize('0711000001'), isNull);
    expect(PhoneNumber.normalize('+251711000001'), isNull);
    expect(PhoneNumber.normalize('091100001'), isNull);
  });

  test('builds the synthetic email', () {
    expect(PhoneNumber.syntheticEmail('+251911000001'), '251911000001@jimma-waste.app');
  });
}
