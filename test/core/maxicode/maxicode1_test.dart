/*
 * Copyright 2016 ZXing authors
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

/// Tests [MaxiCodeReader] against a fixed set of test images.
void main() {
  test('Maxicode1TestCase', () {
    AbstractBlackBoxTestCase(
      'test/resources/blackbox/maxicode-1',
      MultiFormatReader(),
      BarcodeFormat.maxicode,
    )
      ..addTest(7, 7, 0.0)
      ..testBlackBox();
  });
}
