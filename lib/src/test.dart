import 'package:test/test.dart';

void main(){
  List<int>data=[];

  group('Address', () {
    test('base58 addresses and valid network', () {
      if (data .length != 22 || data[0] != 1
          || data[1] != 20) {
        throw ArgumentError('Output is invalid');
      }
    });
  });

}
