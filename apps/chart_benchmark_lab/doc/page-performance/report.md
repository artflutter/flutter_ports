# Page performance of the chart benchmark lab

Date: 2026-11-06. Code base: `048f8db` plus the uncommitted change of this report.

## Result

The page around the charts does much less work now. A window resize with saved results no
longer drops frames in Safari and drops almost none in Firefox. Taps on the library buttons and on Run are about
two to seven times faster at their slowest frames. A page load shows a splash after about
80 ms, and not a blank white page for about 3.4 seconds.

Two interactions did not improve: a tap on a feature switch and a sort of the table. Their
slowest frames stay over the frame budget in some browsers. The section "What did not
improve" gives the figures.

No file in `lib/charts` or `packages/flutter_chartjs_port` changed.

## How this was measured

`tool/perf_page.dart` runs the real page in profile mode and scripts each interaction. It
reads the Flutter frame timings. Most scenarios use a chart of 100 items, so that the figures
show the page and not the chart.

Each target ran in the order old, new, new, old, and each figure is the mean of two runs. Two
runs give a direction and not an exact value. Differences below about 10% can be noise.

| Target | Build | Display rate |
| --- | --- | --- |
| Chrome 156 | WebAssembly with threads | 120 Hz |
| Safari 27 | JavaScript | 60 FPS limit |
| Firefox 159 | JavaScript | 60 FPS limit |
| macOS app, M3 Max | Native | 120 Hz |
| Pixel 8a, Android 17 | Native | 120 Hz |

Each window on the Mac was on the built-in display. The iPhone was not connected, so it has
no figures.

`test/page_work_test.dart` counts the widgets that build and the render objects that paint for
each interaction. A count does not depend on the machine, so those figures are exact.

## What changed

1. Each section of the page is one widget instance that rebuilds only when a value that it
   reads changes. Before, each change of the controller rebuilt the whole page and updated the
   chart.
2. Repaint boundaries sit below each scroll view, around the plot and around the sections that
   change often. A scroll frame, a chart frame and a readout no longer record the rest of the
   page.
3. An idle chart stays mounted through a resize and at the first layout. Before, each resize
   step and each load threw the chart away and mounted a new one. A Graphic bar chart keeps the
   old behavior, because it reads its bar width only when it mounts.
4. The results table keeps its rank, its built rows and its keys. A resize no longer rebuilds
   the rows. A sort moves keyed rows.
5. A setting that does not change does nothing, for example a tap on the selected chart type.
6. The web page shows a splash in the color of the page until the first frame, with a hint after
   30 seconds. The page background is no longer white.

Each test still starts with a new chart. Warmup, timing windows, comparison keys, the data
generator and the overlay labels did not change.

## Work counts

These are the counts of the desktop layout, with 24 saved results and the chart of 100 items.

| Interaction | Widgets built | Render objects painted |
| --- | --- | --- |
| A controller change with nothing visible | 2,780 → 0 | 2,756 → 0 |
| One scroll frame | 0 → 0 | 294 → 1 |
| One chart frame | 6 → 6 | 295 → 5 |
| One readout | 53 → 53 | 426 → 136 |
| A press of Run | 2,780 → 159 | 2,756 → 164 |
| One resize step | 5,568 → 1,796 | 5,563 → 607 |
| A hover over a switch and away | 20 → 20 | 2,040 → 1,126 |
| A sort | 1,462 → 1,461 | 3,839 → 3,268 |

The first frames mounted the chart two times, and they now mount it one time.

## Timings

Each cell gives old → new. FPS is frames for each second. Other figures are milliseconds of
work on the UI thread. P50 is the median frame, P99 is the slowest 1% of frames, and "slowest"
is the single slowest frame.

### Window resize with 24 saved results

The width changes on each frame.

| Target | FPS | UI P50 | Frames over budget, in 5 s |
| --- | --- | --- | --- |
| Chrome | 118 → 120 | 7.8 → 2.4 | 0 → 0 |
| Safari | 52 → 60 | 14.5 → 5.5 | 22 → 0 |
| Firefox | 42 → 60 | 20.5 → 7.5 | 207 → 7 |
| macOS | 120 → 120 | 4.7 → 3.3 | 3 → 8 |
| Pixel 8a | 119 → 118 | 6.9 → 3.0 | 94 → 24 |

The budget is 16.7 ms in a browser, because the web engine reports 60 Hz, and 8.3 ms on macOS
and the Pixel.

### Run: each chart frame and the readout

| Target | UI P50 of a chart frame | Slowest frame |
| --- | --- | --- |
| Chrome | 0.5 → 0.4 | 25.8 → 9.6 |
| Safari | 1 → 1 | 42.5 → 20 |
| Firefox | 2 → 1 | 49 → 24 |
| macOS | 1.0 → 0.4 | 16.9 → 4.6 |
| Pixel 8a | 2.3 → 1.1 | 42.3 → 25.3 |

### Scroll with 24 saved results

| Target | UI P50 | Slowest frame |
| --- | --- | --- |
| Chrome | 0.5 → 0.4 | 0.9 → 0.7 |
| Safari | 1 → 1 | 2.5 → 2 |
| Firefox | 2 → 1.5 | 7 → 7 |
| macOS | 0.8 → 0.2 | 3.2 → 0.7 |
| Pixel 8a | 2.4 → 0.8 | 19 → 2.4 |

Scrolling was already smooth on the Mac targets. The Pixel has the clear gain.

### Taps: UI P99

| Target | A library button | Run and Pause |
| --- | --- | --- |
| Chrome | 18.9 → 5.3 | 9.6 → 2.2 |
| Safari | 29.5 → 11 | 23 → 11.5 |
| Firefox | 50.5 → 20 | 43.5 → 21 |
| macOS | 18.5 → 2.7 | 16.2 → 2.2 |
| Pixel 8a | 17.9 → 8.4 | 20.8 → 8 |

### First load in a browser

These are release builds on a local server. Only the Chrome run has a throttled connection, of
20 Mbit/s with 40 ms of delay and gzip, and it ran headless. Safari and Firefox had no throttling.

| Browser | First paint | First frame of the app |
| --- | --- | --- |
| Chrome | 3,391 → 83 ms | 3,388 → 3,676 ms |
| Safari | 449 → 11 ms | 465 → 457 ms |
| Firefox | none before the app → 124 ms | 1,740 → 1,802 ms |

The first frame of the app shows no clear change. The two Chrome runs on each side differ by up
to 630 ms, so that 288 ms is inside the noise. The download stays at about 2.6 MB.

## What did not improve

The UI P99 of these taps stays high. When saved rows appear or vanish, they add about half or
more of the cost. It is possible that the rest is the rebuild of the settings panel and the mount
of the chart, but I did not measure these two parts apart.

| Target | A feature switch, no saved rows | A feature switch, 24 rows | A sort, 24 rows |
| --- | --- | --- | --- |
| Chrome | 10.9 → 10.2 | 31.3 → 31.6 | 13.8 → 12.2 |
| Safari | 18.5 → 18.5 | 48.5 → 40.5 | 17 → 15.5 |
| Firefox | 43.5 → 43.5 | 76.5 → 77 | 32.5 → 31 |
| macOS | 8.6 → 7.5 | 32.7 → 33.2 | 10.8 → 9 |
| Pixel 8a | not measured | 33 → 31.8 | 35 → 28.3 |

A pass of Capture all saves 4 rows, so 24 rows is the worst case. The table is a `DataTable`, and
that widget caused most of these builds. These are the two next steps that I see:

- Rebuild only the changed control in the settings panel. A library tap has no settings rebuild.
  It costs about 24 ms less than a switch tap in Firefox, and about 5 ms less in Chrome and on
  macOS. I estimate a part of that gain.
- Replace `DataTable` with a lighter table of fixed column widths.

## Costs of this change

- **Raster time on the Pixel:** the extra layers add about 0.5 ms to a frame. The P50 of a chart
  frame went from 2.4 to 2.9 ms, and that of a scroll frame from 2.6 to 3.1 ms. The UI time fell by
  more in the same frames. The Mac targets show no clear change.
- **Slowest frames of a resize:** the P99 went from 6.4 to 9.6 ms on macOS and from 11.7 to 14.2 ms
  on the Pixel, although the median improved. It is possible that the table rebuilds each time
  that the width passes the size of the saved rows. I did not confirm this cause.
- **Figures of a capture:** the UI time of a chart frame fell for each library, and the raster time
  rose on the Pixel. An older exported capture does not compare exactly with a new one.
- **A paused chart:** it now keeps its last step through a resize, and does not go back to step 0.

## Examined and dropped

- **Service worker for the document only:** a review predicted a faster repeat visit, because Chrome
  can then keep its compiled-code cache. Repeat visits took about 150 ms with and without the
  change, so I reverted it. Thread isolation worked in both forms.
- **Hiding the settings during a capture:** the earlier captures in this repository show too little
  raster time for the whole page to justify a visible jump. I did not test this change.
- **A faster data generator and overlay labels:** these are part of the shared workload that a test
  measures, so I left them as they are.

## Tests

All lab tests pass, and they include the new `test/page_work_test.dart`. A review found that its
first stale-screen check could never fail, and that the page had a fault that the check should have
caught. I fixed both, and I confirmed that the check now fails when each fault returns.

The raw lines are in `results/`, and `results/comparison.txt` has each scenario in full. The scripts
are in `scripts/`. They name the paths of the machine that ran them.
