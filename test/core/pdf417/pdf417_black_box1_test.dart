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

/// This test consists of perfect, computer-generated images. We should have 100% passing.
///
void main() {
  test('PDF417BlackBox1TestCase', () {
    AbstractBlackBoxTestCase(
      'test/resources/blackbox/pdf417-1',
      MultiFormatReader(),
      BarcodeFormat.pdf417,
    )
      ..addTest(10, 10, 0.0)
      ..addTest(10, 10, 90.0)
      ..addTest(10, 10, 180.0)
      ..addTest(10, 10, 270.0)
      ..testBlackBox();
  });
}
