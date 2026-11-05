Impeller balanced-fill patch — iteration 2
2026-11-05

Purpose
Reduce GPU overdraw for large concave filled paths with balanced local strips.
This is an engine patch. It requires no changes to chart data or Dart paths.

Target
Flutter 3.50.0-0.4.pre, framework 368ac9e40bad0566927cc9428a42461152652c12,
engine artifact revision 1b9ee1a58581e9c51a5fc9b38d42ab80388c6d1d.
One modified file: engine/src/flutter/impeller/tessellator/tessellator.cc.

What improved in iteration 2
The index writer and triangle sequence are unchanged from the native-validated
prototype. The reservation is tightened from 2*N+C to:

    N + C + 6*floor(N/16)

where N is the preflight flattened-point count and C the contour count.
This adds at most 37.5% to point-related index capacity instead of 100%.
Selection includes overflow checks against the byte allocation limit.
Legacy paths keep N+C capacity when the balanced route is not selected.

Why the bound holds
Each eligible contour is recursively split until leaf strips span 16..32
edges. With n vertices and L leaves, emitted indices total n+6*L-5 and
L <= floor((n-1)/16). Summing the extra allowance across large contours is
bounded by 6*floor(N/16). The N+C base also covers unchanged small contours.
Eligibility remains non-convex, primitive-restart strip paths with >=1024
points, and >=1024 points in each contour being reordered. Leaf size is 32.

Measured path allocation (32-bit indices)
Original:                    241,584 indices /   966,336 bytes.
Iteration 1 reservation:     483,167 indices / 1,932,668 bytes.
Iteration 2 reservation:     332,172 indices / 1,328,688 bytes.
Actually emitted:           290,730 indices / 1,162,920 bytes.
Iteration 2 saves 603,980 reserved bytes, about 31.25%, versus iteration 1.
It does not reduce the number of emitted indices or change rendered pixels.

Apply (from the Flutter checkout root)
    git apply --check /path/to/impeller-balanced-fill.patch
    git apply /path/to/impeller-balanced-fill.patch

Undo
    git apply -R /path/to/impeller-balanced-fill.patch

Standalone verification without modifying that checkout
    python3 verify.py /path/to/flutter

Verify an already patched checkout
    python3 verify.py /path/to/flutter --patched

The verifier copies the source into a temporary directory, applies the patch
there, extracts the EXACT writer and allocation calculation, and compiles them
with minimal engine type stubs. It runs AddressSanitizer and UBSan tests.
Requires Python 3, git and a C++17 compiler with sanitizer support. On macOS
it uses xcrun clang++; elsewhere c++. CXX can override the compiler command.
Use DEVELOPER_DIR to select a matching Xcode/SDK if necessary; this machine
used /Applications/Xcode-27.1.0.app/Contents/Developer.

Validation performed for iteration 2
- Patch applied cleanly to a temporary copy of the pinned beta source.
- 4,099 index-capacity/count cases, including one million vertices.
- 170 random/reversed/repeated/collinear/self-intersecting polygons.
- 34,000 signed-winding samples; even-odd parity also checked.
- Signed area error: zero.
- Additional multiple-contour, legacy-mode, uint16 boundary and allocation-
  overflow selection checks passed under AddressSanitizer and UBSan.
- Index-emission code matches the earlier tested prototype unchanged.

Expected final output
PASS capacity=4099 polygons=170 winding_samples=34000 signed_area_max_error=0
PASS patch applies; extracted writer and allocation tested with ASan/UBSan; SDK unchanged

Prior native evidence (not remeasured as part of this allocation-only iteration)
An isolated Metal index-rewrite prototype of the same triangulation reduced
median GPU command time from ~23.5-24 ms to 0.808 ms for the original 20k-point
single-contour fill, reaching ~120 engine FPS. Three output PNGs were byte-
identical to the original engine's images; Metal validation reported no errors.
Included JSON files record timings and pixel checks. This is a fill-only
workload, not a claim of a 30x whole-application improvement.

Limits before shipping
This package is a candidate source patch, NOT a rebuilt Flutter engine.
The complete engine translation unit/build and engine test suite have not
been run: the installed SDK source lacks build dependencies such as Abseil.
The standalone tests cover extracted code, not the full renderer integration.
Use a complete engine development checkout to build and run native rendering
goldens, transform/clip/hole/antialiasing regressions, ordinary-path benchmarks
and additional applicable GPUs/backends before submitting or deploying it.
The reserved bound can still overallocate on paths containing many short
contours. Thresholds and leaf size remain benchmark-tuning candidates.

The installed SDK and project runtime have not been modified. No upstream
submission has been made. The code patch keeps the existing triangle-strip
pipeline, primitive restart, vertices, fill rule and stencil-cover stages.

Licensing
The Flutter source patch/extracted writer follows Flutter's BSD license;
see LICENSE-Flutter.txt. Standalone verification tooling is MIT (LICENSE.txt).
