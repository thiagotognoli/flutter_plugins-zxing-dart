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

import '../../oned/upce_reader.dart';
import '../../barcode_format.dart';
import '../../result.dart';
import 'product_parsed_result.dart';
import 'result_parser.dart';

/// Parses strings of digits that represent a UPC code.
///
/// @author dswitkin@google.com (Daniel Switkin)
class ProductResultParser extends ResultParser {
  // Treat all UPC and EAN variants as UPCs, in the sense that they are all product barcodes.
  @override
  ProductParsedResult? parse(Result result) {
    final format = result.barcodeFormat;
    if (!(format == BarcodeFormat.upcA ||
        format == BarcodeFormat.upcE ||
        format == BarcodeFormat.ean8 ||
        format == BarcodeFormat.ean13)) {
      return null;
    }
    final rawText = ResultParser.getMassagedText(result);
    if (!isStringOfDigits(rawText, rawText.length)) {
      return null;
    }
    // Not actually checking the checksum again here

    String normalizedProductID;
    // Expand UPC-E for purposes of searching
    if (format == BarcodeFormat.upcE && rawText.length == 8) {
      normalizedProductID = UPCEReader.convertUPCEtoUPCA(rawText);
    } else {
      normalizedProductID = rawText;
    }

    return ProductParsedResult(rawText, normalizedProductID);
  }
}
