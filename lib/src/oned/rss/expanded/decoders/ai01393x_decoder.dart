/*
 * Copyright (C) 2010 ZXing authors
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

/*
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", led by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 */

import '../../../../common/bit_array.dart';
import '../../../../common/string_builder.dart';

import '../../../../not_found_exception.dart';
import 'ai01_decoder.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
class AI01393xDecoder extends AI01Decoder {
  static const int _headerSize = 5 + 1 + 2;
  static const int _lastDigitSize = 2;
  static const int _firstThreeDigitsSize = 10;

  AI01393xDecoder(BitArray information) : super(information);

  @override
  String parseInformation() {
    if (information.size < _headerSize + AI01Decoder.gtinSize) {
      throw NotFoundException.instance;
    }

    final buf = StringBuilder();

    encodeCompressedGtin(buf, _headerSize);

    final lastAIdigit = generalDecoder.extractNumericValueFromBitArray(
      _headerSize + AI01Decoder.gtinSize,
      _lastDigitSize,
    );

    buf.write('(393');
    buf.write(lastAIdigit);
    buf.write(')');

    final firstThreeDigits = generalDecoder.extractNumericValueFromBitArray(
      _headerSize + AI01Decoder.gtinSize + _lastDigitSize,
      _firstThreeDigitsSize,
    );
    if (firstThreeDigits ~/ 100 == 0) {
      buf.write('0');
    }
    if (firstThreeDigits ~/ 10 == 0) {
      buf.write('0');
    }
    buf.write(firstThreeDigits);

    final generalInformation = generalDecoder.decodeGeneralPurposeField(
      _headerSize +
          AI01Decoder.gtinSize +
          _lastDigitSize +
          _firstThreeDigitsSize,
      null,
    );
    buf.write(generalInformation.newString);

    return buf.toString();
  }
}
