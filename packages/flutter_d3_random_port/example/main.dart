// Original code, not ported from d3-random: package example.

// Example prints sampled values.
// ignore_for_file: avoid_print

import 'package:flutter_d3_random_port/d3_random.dart';

void main() {
  // Deterministic PRNG matching upstream d3-random v3.0.1 bit-for-bit.
  final seed = randomLcg(0.42);
  final normal = randomNormal.source(seed)(100, 15);
  print('Normal draws: ${List<double>.generate(5, (_) => normal())}');

  // Discrete integer distribution returning int directly.
  final die = randomInt.source(randomLcg(7))(1, 7);
  print('Die rolls: ${List<int>.generate(6, (_) => die())}');

  // Batch sampling into a typed Float64List / Int32List.
  final gammaSamples = randomGamma.source(randomLcg(0.5)).sample(1000, 2, 1.5);
  final poissonSamples = randomPoisson.source(randomLcg(0.5)).sample(1000, 12);
  print(
    'Sampled ${gammaSamples.length} gamma and '
    '${poissonSamples.length} poisson variates.',
  );
}
