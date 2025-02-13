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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/oned.dart';

void main() {
  BitArray buildBitArray(List<List<int>> pairValues) {
    final pairs = <ExpandedPair>[];
    for (int i = 0; i < pairValues.length; ++i) {
      final pair = pairValues[i];

      DataCharacter? leftChar;
      if (i == 0) {
        leftChar = null;
      } else {
        leftChar = DataCharacter(pair[0], 0);
      }

      DataCharacter? rightChar;
      if (i == 0) {
        rightChar = DataCharacter(pair[0], 0);
      } else if (pair.length == 2) {
        rightChar = DataCharacter(pair[1], 0);
      } else {
        rightChar = null;
      }

      final expandedPair = ExpandedPair(leftChar, rightChar, null);
      pairs.add(expandedPair);
    }

    return BitArrayBuilder.buildBitArray(pairs);
  }

  void checkBinary(List<List<int>> pairValues, String expected) {
    final binary = buildBitArray(pairValues);
    expect(expected, binary.toString());
  }

  test('testBuildBitArray1', () {
    final pairValues = [
      [19],
      [673, 16]
    ];

    final expected = ' .......X ..XX..X. X.X....X .......X ....';

    checkBinary(pairValues, expected);
  });
}
