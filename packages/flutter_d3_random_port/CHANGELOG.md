## 0.1.0

- Initial release: native, fully statically typed pure-Dart port of `d3-random`
  `v3.0.1` with zero runtime dependencies.
- All 17 distributions with typed `.source(RandomSource)` factories
  (`randomUniform`, `randomInt`, `randomNormal`, `randomLogNormal`,
  `randomBates`, `randomIrwinHall`, `randomExponential`, `randomPareto`,
  `randomBernoulli`, `randomGeometric`, `randomBinomial`, `randomGamma`,
  `randomBeta`, `randomWeibull`, `randomCauchy`, `randomLogistic`,
  `randomPoisson`), bit-exact `randomLcg`, and typed `Float64List`/`Int32List`
  batch `fill`/`sample` helpers.
