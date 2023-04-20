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

import 'dart:math' as math;

import '../barcode_format.dart';
import '../common/bit_matrix.dart';
import '../encode_hint_type.dart';
import '../writer.dart';
import 'decoder/error_correction_level.dart';
import 'encoder/encoder.dart';
import 'encoder/qrcode.dart';

/// This object renders a QR Code as a BitMatrix 2D array of greyscale values.
///
/// @author dswitkin@google.com (Daniel Switkin)
class QRCodeWriter implements Writer {
  static const int _quietZoneSize = 4;

  @override
  BitMatrix encode(
    String contents,
    BarcodeFormat format,
    int width,
    int height, [
    Map<EncodeHintType, Object>? hints,
  ]) {
    if (contents.isEmpty) {
      throw ArgumentError('Found empty contents');
    }

    if (format != BarcodeFormat.qrCode) {
      throw ArgumentError('Can only encode QR_CODE, but got $format');
    }

    if (width < 0 || height < 0) {
      throw ArgumentError(
        'Requested dimensions are too small: $width x $height',
      );
    }

    ErrorCorrectionLevel errorCorrectionLevel = ErrorCorrectionLevel.L;
    int quietZone = _quietZoneSize;
    if (hints != null) {
      if (hints.containsKey(EncodeHintType.errorCorrection)) {
        errorCorrectionLevel = ErrorCorrectionLevel
            .values[hints[EncodeHintType.errorCorrection] as int];
      }
      if (hints.containsKey(EncodeHintType.margin)) {
        quietZone = int.parse(hints[EncodeHintType.margin].toString());
      }
    }

    final code = Encoder.encode(contents, errorCorrectionLevel, hints);
    return _renderResult(code, width, height, quietZone);
  }

  // Note that the input matrix uses 0 == white, 1 == black, while the output matrix uses
  // 0 == black, 255 == white (i.e. an 8 bit greyscale bitmap).
  static BitMatrix _renderResult(
    QRCode code,
    int width,
    int height,
    int quietZone,
  ) {
    final input = code.matrix;
    if (input == null) {
      throw StateError('ByteMatrix input is null');
    }
    final inputWidth = input.width;
    final inputHeight = input.height;
    final qrWidth = inputWidth + (quietZone * 2);
    final qrHeight = inputHeight + (quietZone * 2);
    final outputWidth = math.max(width, qrWidth);
    final outputHeight = math.max(height, qrHeight);

    final multiple = math.min(outputWidth ~/ qrWidth, outputHeight ~/ qrHeight);
    // Padding includes both the quiet zone and the extra white pixels to accommodate the requested
    // dimensions. For example, if input is 25x25 the QR will be 33x33 including the quiet zone.
    // If the requested size is 200x160, the multiple will be 4, for a QR of 132x132. These will
    // handle all the padding from 100x100 (the actual QR) up to 200x160.
    final leftPadding = (outputWidth - (inputWidth * multiple)) ~/ 2;
    final topPadding = (outputHeight - (inputHeight * multiple)) ~/ 2;

    final output = BitMatrix(outputWidth, outputHeight);

    for (int inputY = 0, outputY = topPadding;
        inputY < inputHeight;
        inputY++, outputY += multiple) {
      // Write the contents of this row of the barcode
      for (int inputX = 0, outputX = leftPadding;
          inputX < inputWidth;
          inputX++, outputX += multiple) {
        if (input.get(inputX, inputY) == 1) {
          output.setRegion(outputX, outputY, multiple, multiple);
        }
      }
    }

    return output;
  }
}
