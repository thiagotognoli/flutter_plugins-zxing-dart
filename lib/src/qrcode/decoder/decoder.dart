/*
 * Copyright 2007 ZXing authors
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

import 'dart:typed_data';

import '../../checksum_exception.dart';
import '../../common/bit_matrix.dart';
import '../../common/decoder_result.dart';
import '../../common/reedsolomon/reed_solomon_exception.dart';
import '../../common/reedsolomon/generic_gf.dart';
import '../../common/reedsolomon/reed_solomon_decoder.dart';
import '../../decode_hint.dart';
import '../../formats_exception.dart';
import 'bit_matrix_parser.dart';
import 'data_block.dart';
import 'decoded_bit_stream_parser.dart';
import 'qrcode_decoder_meta_data.dart';

/// The main class which implements QR Code decoding -- as opposed to locating and extracting
/// the QR Code from an image.
///
/// @author Sean Owen
class Decoder {
  final ReedSolomonDecoder _rsDecoder;

  Decoder() : _rsDecoder = ReedSolomonDecoder(GenericGF.qrCodeField256);

  /// <p>Convenience method that can decode a QR Code represented as a 2D array of booleans.
  /// "true" is taken to mean a black module.</p>
  ///
  /// @param image booleans representing white/black QR Code modules
  /// @param hints decoding hints that should be used to influence decoding
  /// @return text and bytes encoded within the QR Code
  /// @throws FormatException if the QR Code cannot be decoded
  /// @throws ChecksumException if error correction fails
  DecoderResult decode(
    List<List<bool>> image, [
    DecodeHint? hints,
  ]) {
    return decodeMatrix(BitMatrix.parse(image), hints);
  }

  /// <p>Decodes a QR Code represented as a [BitMatrix]. A 1 or "true" is taken to mean a black module.</p>
  ///
  /// @param bits booleans representing white/black QR Code modules
  /// @param hints decoding hints that should be used to influence decoding
  /// @return text and bytes encoded within the QR Code
  /// @throws FormatException if the QR Code cannot be decoded
  /// @throws ChecksumException if error correction fails
  DecoderResult decodeMatrix(
    BitMatrix bits, [
    DecodeHint? hints,
  ]) {
    // Construct a parser and read version, error-correction level
    final parser = BitMatrixParser(bits);
    FormatsException? fe;
    ChecksumException? ce;
    try {
      return _decodeParser(parser, hints);
    } on FormatsException catch (e) {
      fe = e;
    } on ChecksumException catch (e) {
      ce = e;
    }

    try {
      // Revert the bit matrix
      parser.remask();

      // Will be attempting a mirrored reading of the version and format info.
      parser.setMirror(true);

      // Preemptively read the version.
      parser.readVersion();

      // Preemptively read the format information.
      parser.readFormatInformation();

      /*
       * Since we're here, this means we have successfully detected some kind
       * of version and format information when mirrored. This is a good sign,
       * that the QR code may be mirrored, and we should try once more with a
       * mirrored content.
       */
      // Prepare for a mirrored reading.
      parser.mirror();

      final result = _decodeParser(parser, hints);

      // Success! Notify the caller that the code was mirrored.
      result.other = QRCodeDecoderMetaData(true);

      return result;
    } on ChecksumException catch (_) {
      // Throw the exception from the original reading
      if (fe != null) {
        throw fe;
      }
      throw ce!; // If fe is null, this can't be
    } on FormatsException catch (_) {
      // Throw the exception from the original reading
      if (fe != null) {
        throw fe;
      }
      throw ce!; // If fe is null, this can't be
    }
  }

  DecoderResult _decodeParser(
    BitMatrixParser parser, [
    DecodeHint? hints,
  ]) {
    final version = parser.readVersion();
    final ecLevel = parser.readFormatInformation().errorCorrectionLevel;

    // Read codewords
    final codewords = parser.readCodewords();
    // Separate into data blocks
    final dataBlocks = DataBlock.getDataBlocks(codewords, version, ecLevel);

    // Count total number of data bytes
    int totalBytes = 0;
    for (DataBlock dataBlock in dataBlocks) {
      totalBytes += dataBlock.numDataCodewords;
    }
    final resultBytes = Uint8List(totalBytes);
    int resultOffset = 0;

    // Error-correct and copy data blocks together into a stream of bytes
    for (DataBlock dataBlock in dataBlocks) {
      final codewordBytes = dataBlock.codewords;
      final numDataCodewords = dataBlock.numDataCodewords;
      _correctErrors(codewordBytes, numDataCodewords);
      for (int i = 0; i < numDataCodewords; i++) {
        resultBytes[resultOffset++] = codewordBytes[i];
      }
    }

    // Decode the contents of that stream of bytes
    return DecodedBitStreamParser.decode(resultBytes, version, ecLevel, hints);
  }

  /// <p>Given data and error-correction codewords received, possibly corrupted by errors, attempts to
  /// correct the errors in-place using Reed-Solomon error correction.</p>
  ///
  /// @param codewordBytes data and error correction codewords
  /// @param numDataCodewords number of codewords that are data bytes
  /// @throws ChecksumException if error correction fails
  void _correctErrors(Uint8List codewordBytes, int numDataCodewords) {
    final numCodewords = codewordBytes.length;
    // First read into an array of ints
    final codewordsInts = Int32List(numCodewords);
    for (int i = 0; i < numCodewords; i++) {
      codewordsInts[i] = codewordBytes[i];
    }
    try {
      _rsDecoder.decode(codewordsInts, codewordBytes.length - numDataCodewords);
    } on ReedSolomonException catch (_) {
      throw ChecksumException.getChecksumInstance();
    }
    // Copy back into array of bytes -- only need to worry about the bytes that were data
    // We don't care about errors in the error-correction codewords
    for (int i = 0; i < numDataCodewords; i++) {
      codewordBytes[i] = codewordsInts[i];
    }
  }
}
