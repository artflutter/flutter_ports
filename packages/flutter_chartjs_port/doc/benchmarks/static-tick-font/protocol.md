# Static tick-font reuse: measurement protocol

2026-11-02. Compare against the retained category-layout optimization of
performance.md §27 (the B app of that experiment), not the earlier HEAD.
Candidate: guarded reuse of already cached scalar font inputs. Use the exact
same category_probe.dart, native profile AOT, 800 × 480 canvas, category x /
logarithmic y and linear x / logarithmic y, N=1000/5000/20000, update and draw.
Each cell: 1000 ms warmup and nine 250 ms batches. Order: A/B/B/A. Keep every run;
no builds or tests concurrently with timing.

Primary: category N=20000 update time must improve by at least 15% in both paired
comparisons. Compare x/y tick values and labels, rotation and chart bounds exactly
in all cells. Report total call cost (update + draw + recording completion) as well
as update and layout. Investigate any repeatable control regression exceeding
both 5% and 0.1 ms in full-call cost. Local timings do not establish an FPS or
mobile/web performance guarantee. Dynamic-font correctness is checked separately.
