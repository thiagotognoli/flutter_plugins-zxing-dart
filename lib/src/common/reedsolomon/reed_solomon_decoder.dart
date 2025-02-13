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

import 'generic_gf.dart';
import 'generic_gfpoly.dart';
import 'reed_solomon_exception.dart';

/// Implements Reed-Solomon decoding, as the name implies.
///
/// The algorithm will not be explained here, but the following references were helpful
/// in creating this implementation:
///
/// <ul>
/// <li>Bruce Maggs.
/// <a href="http://www.cs.cmu.edu/afs/cs.cmu.edu/project/pscico-guyb/realworld/www/rs_decode.ps">
/// "Decoding Reed-Solomon Codes"</a> (see discussion of Forney's Formula)</li>
/// <li>J.I. Hall. <a href="www.mth.msu.edu/~jhall/classes/codenotes/GRS.pdf">
/// "Chapter 5. Generalized Reed-Solomon Codes"</a>
/// (see discussion of Euclidean algorithm)</li>
/// </ul>
///
/// Much credit is due to William Rucklidge since portions of this code are an indirect
/// port of his C++ Reed-Solomon implementation.
///
/// @author Sean Owen
/// @author William Rucklidge
/// @author sanfordsquires
class ReedSolomonDecoder {
  final GenericGF _field;

  ReedSolomonDecoder(this._field);

  /// <p>Decodes given set of received codewords, which include both data and error-correction
  /// codewords. Really, this means it uses Reed-Solomon to detect and correct errors, in-place,
  /// in the input.</p>
  ///
  /// @param received data and error-correction codewords
  /// @param twoS number of error-correction codewords available
  /// @throws ReedSolomonException if decoding fails for any reason
  void decode(List<int> received, int twoS) {
    final poly = GenericGFPoly(_field, received);
    final syndromeCoefficients = Int32List(twoS);
    bool noError = true;
    for (int i = 0; i < twoS; i++) {
      final eval = poly.evaluateAt(_field.exp(i + _field.generatorBase));
      syndromeCoefficients[syndromeCoefficients.length - 1 - i] = eval;
      if (eval != 0) {
        noError = false;
      }
    }
    if (noError) {
      return;
    }
    final syndrome = GenericGFPoly(_field, syndromeCoefficients);
    final sigmaOmega =
        _runEuclideanAlgorithm(_field.buildMonomial(twoS, 1), syndrome, twoS);
    final sigma = sigmaOmega[0];
    final omega = sigmaOmega[1];
    final errorLocations = _findErrorLocations(sigma);
    final errorMagnitudes = _findErrorMagnitudes(omega, errorLocations);
    for (int i = 0; i < errorLocations.length; i++) {
      final position = received.length - 1 - _field.log(errorLocations[i]);
      if (position < 0) {
        throw ReedSolomonException('Bad error location');
      }
      received[position] =
          GenericGF.addOrSubtract(received[position], errorMagnitudes[i]);
    }
  }

  List<GenericGFPoly> _runEuclideanAlgorithm(
    GenericGFPoly a,
    GenericGFPoly b,
    int R,
  ) {
    // Assume a's degree is >= b's
    if (a.degree < b.degree) {
      final temp = a;
      a = b;
      b = temp;
    }

    GenericGFPoly rLast = a;
    GenericGFPoly r = b;
    GenericGFPoly tLast = _field.zero;
    GenericGFPoly t = _field.one;

    // Run Euclidean algorithm until r's degree is less than R/2
    while (2 * r.degree >= R) {
      final rLastLast = rLast;
      final tLastLast = tLast;
      rLast = r;
      tLast = t;

      // Divide rLastLast by rLast, with quotient in q and remainder in r
      if (rLast.isZero) {
        // Oops, Euclidean algorithm already terminated?
        throw ReedSolomonException('r_{i-1} was zero');
      }
      r = rLastLast;
      GenericGFPoly q = _field.zero;
      final denominatorLeadingTerm = rLast.getCoefficient(rLast.degree);
      final dltInverse = _field.inverse(denominatorLeadingTerm);
      while (r.degree >= rLast.degree && !r.isZero) {
        final degreeDiff = r.degree - rLast.degree;
        final scale = _field.multiply(r.getCoefficient(r.degree), dltInverse);
        q = q.addOrSubtract(_field.buildMonomial(degreeDiff, scale));
        r = r.addOrSubtract(rLast.multiplyByMonomial(degreeDiff, scale));
      }

      t = q.multiply(tLast).addOrSubtract(tLastLast);

      if (r.degree >= rLast.degree) {
        throw ReedSolomonException(
          'Division algorithm failed to reduce polynomial?',
        );
      }
    }

    final sigmaTildeAtZero = t.getCoefficient(0);
    if (sigmaTildeAtZero == 0) {
      throw ReedSolomonException('sigmaTilde(0) was zero');
    }

    final inverse = _field.inverse(sigmaTildeAtZero);
    final sigma = t.multiplyInt(inverse);
    final omega = r.multiplyInt(inverse);
    return [sigma, omega];
  }

  Int32List _findErrorLocations(GenericGFPoly errorLocator) {
    // This is a direct application of Chien's search
    final numErrors = errorLocator.degree;
    if (numErrors == 1) {
      // shortcut
      return Int32List.fromList([errorLocator.getCoefficient(1)]);
    }
    final result = Int32List(numErrors);
    int e = 0;
    for (int i = 1; i < _field.size && e < numErrors; i++) {
      if (errorLocator.evaluateAt(i) == 0) {
        result[e] = _field.inverse(i);
        e++;
      }
    }
    if (e != numErrors) {
      throw ReedSolomonException(
        'Error locator degree does not match number of roots ($e != $numErrors)',
      );
    }
    return result;
  }

  Int32List _findErrorMagnitudes(
    GenericGFPoly errorEvaluator,
    List<int> errorLocations,
  ) {
    // This is directly applying Forney's Formula
    final s = errorLocations.length;
    final result = Int32List(s);
    for (int i = 0; i < s; i++) {
      final xiInverse = _field.inverse(errorLocations[i]);
      int denominator = 1;
      for (int j = 0; j < s; j++) {
        if (i != j) {
          //denominator = field.multiply(denominator,
          //    GenericGF.addOrSubtract(1, field.multiply(errorLocations[j], xiInverse)));
          // Above should work but fails on some Apple and Linux JDKs due to a Hotspot bug.
          // Below is a funny-looking workaround from Steven Parkes
          final term = _field.multiply(errorLocations[j], xiInverse);
          final termPlus1 = (term & 0x1) == 0 ? term | 1 : term & ~1;
          denominator = _field.multiply(denominator, termPlus1);
        }
      }
      result[i] = _field.multiply(
        errorEvaluator.evaluateAt(xiInverse),
        _field.inverse(denominator),
      );
      if (_field.generatorBase != 0) {
        result[i] = _field.multiply(result[i], xiInverse);
      }
    }
    return result;
  }
}
