/*
 * Copyright 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:test/scaffolding.dart';
import 'package:zxing_lib/zxing.dart';

import '../common/abstract_black_box.dart';

void main() {
  test('QRCodeBlackBox2TestCase', () {
    AbstractBlackBoxTestCase(
      'test/resources/blackbox/qrcode-2',
      MultiFormatReader(),
      BarcodeFormat.qrCode,
    )
      ..addTest(31, 31, 0.0)
      ..addTest(29, 29, 90.0)
      ..addTest(30, 30, 180.0)
      ..addTest(30, 30, 270.0)
      ..testBlackBox();
  });
}
