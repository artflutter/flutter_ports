# Chart.js ADR 0070: Native rectangular bar drawing

- Status: implemented; macOS performance and VM/browser pixel/state validation.
- Related: ADRs 0066, 0067; performance.md §37.

## Decision

After the existing scalar geometry of an ordinary unrounded, uninflated bar,
offer an optional RectBarCanvas operation. Other contexts and declined cases
retain the exact Canvas 2D sequence. The native context accepts only finite
rectangles under an invertible axis-aligned transform, valid exact immutable
sRGB colors and a compatible nested/empty rectangle pair.

Draw a collapsed-interior border with drawRect, or a nonempty ring with the
existing drawDRRect selection. Draw the inner fill when it has area. The current
path still becomes the original inner rectangle, with the same commands and
winding, so later stroke/clip/append operations remain correct. Logical styles,
save depth and clipping are untouched. Pending circles flush in the same order.
Each fill that the ordinary path would process still advances drawing and
recording accounting, including an empty interior. An empty fill avoids only
private paint setup; it still obtains a recorder when the original would.

The method declines when onChanged could notify user code, when image/picture
allocation/disposal callbacks are installed, or when the path's transform is not
the current state transform. These observers must see the original intermediate
style, path and saved state, including reentrancy and exceptions. A false return
changes no observable canvas state. Invalid/unknown colors, gradients/patterns,
rotations, non-finite geometry, rounding and inflation use the existing path.
The ordinary error sequence remains, including a border painted before an invalid
background setter throws.

Validation of the last two colors is reused only by identity after proving the
exact immutable Color class, sRGB color space and normalized finite channels.
These small caches are cleared on disposal. No bar aggregation, atlas, triangle
approximation, new isolation layer or paint-order change is introduced.

## Validation

Exact pixel/state twins use a subclass that stays on the original path. They
cover all 26 composite modes, alpha, horizontal/vertical and thin/wide bars,
transforms/clips, subsequent current-path use, caller gradients, reflection,
notifications, picture hooks, pending circles, recording boundaries, errors,
snapshot/clear/disposal and unsupported inputs. Capability tests prove activation
and identical fallback calls. The prewritten protocol and raw results are in
benchmarks/bar-native/. Performance outcomes are recorded in performance.md §37.

At 20k, full draw calls improve 20.1%, updates 14.5% and animation CPU 19.8%.
Both draw pairs meet the 15% gate; controls remain within the regression limits.
The valid foreground update comparison is 31.15 → 35.61 FPS. Animation remains
about 60 FPS with lower CPU cost. All workspace tests, 35 targeted cases on each
browser backend, fixtures, analysis, formatting, parity and port checks pass.
No golden image changed.
