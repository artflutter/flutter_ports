# Why low UI/raster timings still missed 120 Hz

2026-11-05. Investigation of the 20k-line comparison where fl_chart delivered
120 FPS / 8.34 ms frame p90, while the Chart.js port delivered 108.1 FPS /
16.66 ms despite lower engine build/raster timings. This investigation changes
no production runtime code. Instrumentation and the control ran in an isolated
workspace; source-hashes.json pins the original app/library inputs.

## Finding

The port's public ChartView performs chart.update after the Flutter build phase.
In this workload, rebuilding/parsing the entire input array is its largest
avoidable component. The benchmark supplies a new list of 20k numeric XY points
each tick and leaves Chart.js parsing enabled. DatasetController._dataCheck drops
the old parsed list; parseObjectData builds new ParsedItems, then parse populates
the metadata list and checks ordering. Both lists grow as values are appended.

The gallery stress configuration explicitly uses parsing:false for line and
scatter. The new public-widget comparison retained the normal parsing default,
so it measures an additional cost that the earlier stress optimization did not.

## Matched diagnostic runs

Native macOS profile, built-in 120-Hz display, DPR2, 1237×420 chart viewport,
20k line values, seed 7, no axes/markers/fill/smoothing/labels. Each run has two
seconds warmup and eighteen measured seconds. Native visibility/cancellation
checks remained active. Only port-cpu enables CPU sampling; do not use its FPS
as a benchmark. The other rows use lightweight timeline scopes, without CPU
sampling. The timings are diagnostic results, not a published ranking.

| Run | FPS | Frame-gap p90 | UI-build p90 | Raster p90 |
| --- | ---: | ---: | ---: | ---: |
| Port, ordinary parsing | 111.7 | 8.34 ms | 2.64 ms | 0.98 ms |
| fl_chart | 119.8 | 8.34 ms | 3.45 ms | 7.47 ms |
| Port, parsing:false control | 119.8 | 8.34 ms | 2.01 ms | 0.96 ms |
| Port, ordinary parsing recheck | 106.3 | 16.67 ms | 2.86 ms | 1.00 ms |

The control preserves all 20,000 points. At the initial full-size layout, every
point was checked against the native scales' projection of the original XY
value, including skip state: zero mismatches; sorted input confirmed. The input
generator keeps x sorted and both coordinates finite for every step. No sampling
or drawing omission is introduced. This is not permission to disable parsing for
arbitrary unsorted, categorical, date, custom-key or stacked input.

## Where the time went

First ordinary port trace, 308 observed post-frame updates:

| Stage | Mean | p90 |
| --- | ---: | ---: |
| Entire post-frame update | 6.55 ms | 9.72 ms |
| Parsing (included above) | 3.39 ms | 6.42 ms |
| Dataset geometry/options update | 1.28 ms | 1.66 ms |
| Chart drawing preparation | 1.04 ms | 1.87 ms |
| Layout | 0.17 ms | 0.18 ms |
| Typed config reconciliation | 0.05 ms | 0.05 ms |

Matched engine timestamps put the post-frame update 8–29 microseconds **after**
the reported build finish. Thus the displayed UI-build number omits this update.
The common data-generation scope lies inside the build phase and must not be
added again. For 307 fully matched frames, build plus post-frame work averages
7.86 ms, with a jointly measured p90 of 11.13 ms. At 120 Hz the interval is 8.33 ms.
These are not sums of independent p90 values.

The missed gaps follow the expensive work with one frame of scheduling lag:
preceding-frame build+update averages 11.52 ms before long gaps versus 7.67 ms
before ordinary gaps; the parsing portion averages 6.19 versus 3.24 ms. This
comparison uses the 15 long gaps in the retained trace window, not every frame
of the capture. CPU sampling places about 34% of samples in parsing; list growth
appears in both the temporary parse result and the metadata array population.

With parsing disabled, parsing becomes effectively constant-time and post-frame
update falls to 3.46 ms mean / 4.03 ms p90. Raster time stays approximately the
same. Restoring parsing reproduces the slow cadence. The bottleneck is repeated
CPU-side parsing/allocation in a deferred update, not expensive rasterization.

## Concrete next fix

For this known sorted numeric XY benchmark, expose/record the documented
parsing:false input mode rather than silently changing defaults. Keep a parsing-
enabled case for raw-input comparisons. If improving normal library defaults,
target parse-result/metadata allocation and copying while preserving fresh
parsed objects, ordering checks and observable parsing behavior.

Do not move arbitrary chart callbacks into Flutter build merely to make the
UI-duration column look complete. Frame interval and FPS already report the
end-to-end scheduling effect.

## Evidence

summary.json, raw compressed engine frame records, timelines and the CPU profile
accompany this report. diagnostic.patch shows all isolated instrumentation and
the compile-time DIAG_NO_PARSE control. driver.dart.txt runs the real benchmark
UI/controller. profile.dart.txt records eight seconds of Dart/GC timeline after
warmup. The viewport width is fixed in the diagnostic host; only one measurement
process runs at a time. The source hash audit confirms no app/library runtime
changes were promoted during this investigation.
