# Long paths on the web

These files are the evidence of [performance.md](../../performance.md) §68 and of Chart.js ADR 0105.

The runs used Chrome 156 on an Apple M3 Max, the built-in 120 Hz display, DPR 2, a plot of 964 x 420 logical pixels and a
release build of Flutter 3.50.0-0.4.pre with WebAssembly and skwasm.

- `forms-1.txt` and `forms-2.txt` are the raster times of a temporary test page with new data on each frame. Each line
  `FORM {json}` has the noise of the data, curved or straight, the point count, the form and the raster P50 and P90.
  `whole` is one stroke. `chunk:k` is a stroke cut each k points. `box:l:k` also cuts at a height or a width of l pixels.
  `fade` and `layer` are translucent strokes, direct and in one layer. `fill` is one fill. `fillpart:k` is one compound
  fill of Chart.js ADR 0089. `fillchunk:k` is a separate draw for each contour. `fillcol:k` also clips on whole pixels.
- `pixels.txt` compares the two forms of the library in Chrome, through `Picture.toImage`, at 1928 x 840 bitmap pixels.
  The tags `smooth*` have no noise and a line of 6 pixels, and `placed5000` has the bitmap at half a pixel.
- `truth.txt` has the inked area in Chrome of one draw and of pieces against the true area of a fill, sampled from its curve.
- `lab-*.txt` are the final passes of the lab on the new code. The old code is in [`../devices/`](../devices/README.md).
