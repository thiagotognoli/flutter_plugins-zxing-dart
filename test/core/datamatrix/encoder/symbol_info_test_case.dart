/*
 * Copyright 2006 Jeremias Maerki
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







import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/datamatrix.dart';
import 'package:zxing/zxing.dart';

/// Tests the SymbolInfo class.
void main(){

  test('testSymbolInfo', () {
    SymbolInfo info = SymbolInfo.lookup(3)!;
    expect(5, info.getErrorCodewords());
    expect(8, info.matrixWidth);
    expect(8, info.matrixHeight);
    expect(10, info.getSymbolWidth());
    expect(10, info.getSymbolHeight());

    info = SymbolInfo.lookup(3, SymbolShapeHint.FORCE_RECTANGLE)!;
    expect(7, info.getErrorCodewords());
    expect(16, info.matrixWidth);
    expect(6, info.matrixHeight);
    expect(18, info.getSymbolWidth());
    expect(8, info.getSymbolHeight());

    info = SymbolInfo.lookup(9)!;
    expect(11, info.getErrorCodewords());
    expect(14, info.matrixWidth);
    expect(6, info.matrixHeight);
    expect(32, info.getSymbolWidth());
    expect(8, info.getSymbolHeight());

    info = SymbolInfo.lookup(9, SymbolShapeHint.FORCE_SQUARE)!;
    expect(12, info.getErrorCodewords());
    expect(14, info.matrixWidth);
    expect(14, info.matrixHeight);
    expect(16, info.getSymbolWidth());
    expect(16, info.getSymbolHeight());

    try {
      SymbolInfo.lookup(1559);
      fail("There's no rectangular symbol for more than 1558 data codewords");
    } catch ( _) { // IllegalArgumentException
      //expected
    }
    try {
      SymbolInfo.lookup(50, SymbolShapeHint.FORCE_RECTANGLE);
      fail("There's no rectangular symbol for 50 data codewords");
    } catch ( _) { // IllegalArgumentException
      //expected
    }

    info = SymbolInfo.lookup(35)!;
    expect(24, info.getSymbolWidth());
    expect(24, info.getSymbolHeight());

    Dimension fixedSize = new Dimension(26, 26);
    info = SymbolInfo.lookupDm(35,
                             SymbolShapeHint.FORCE_NONE, fixedSize, fixedSize, false)!;
    expect(26, info.getSymbolWidth());
    expect(26, info.getSymbolHeight());

    info = SymbolInfo.lookupDm(45,
                             SymbolShapeHint.FORCE_NONE, fixedSize, fixedSize, false)!;
    //assertNull(info);

    Dimension minSize = fixedSize;
    Dimension maxSize = new Dimension(32, 32);

    info = SymbolInfo.lookupDm(35,
                             SymbolShapeHint.FORCE_NONE, minSize, maxSize, false)!;
    //assertNotNull(info);
    expect(26, info.getSymbolWidth());
    expect(26, info.getSymbolHeight());

    info = SymbolInfo.lookupDm(40,
                             SymbolShapeHint.FORCE_NONE, minSize, maxSize, false)!;
    //assertNotNull(info);
    expect(26, info.getSymbolWidth());
    expect(26, info.getSymbolHeight());

    info = SymbolInfo.lookupDm(45,
                             SymbolShapeHint.FORCE_NONE, minSize, maxSize, false)!;
    //assertNotNull(info);
    expect(32, info.getSymbolWidth());
    expect(32, info.getSymbolHeight());

    info = SymbolInfo.lookupDm(63,
                             SymbolShapeHint.FORCE_NONE, minSize, maxSize, false)!;
    //assertNull(info);
  });

}
