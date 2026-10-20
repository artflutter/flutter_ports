// Probe variant of test/specs/platform.basic.tests.js:44-99 (the describe
// 'with offscreenCanvas'). The probe has no OffscreenCanvas. The variant
// gives the chart the BasicPlatform explicitly, as _detectPlatform does for
// an OffscreenCanvas. The rest of each case is unchanged.
describe('Platform.basic', function() {
  describe('with offscreenCanvas', function() {
    it('supports laying out a simple chart', function() {
      const chart = acquireChart({
        type: 'bar',
        platform: Chart.platforms.BasicPlatform,
        data: {
          datasets: [
            {data: [10, 5, 0, 25, 78, -10]}
          ],
          labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5', 'tick6']
        }
      }, {
        canvas: {
          height: 150,
          width: 250
        }
      });

      expect(chart.platform).toBeInstanceOf(Chart.platforms.BasicPlatform);

      expect(chart.chartArea.bottom).toBeCloseToPixel(120);
      expect(chart.chartArea.left).toBeCloseToPixel(31);
      expect(chart.chartArea.right).toBeCloseToPixel(250);
      expect(chart.chartArea.top).toBeCloseToPixel(32);
    });

    it('supports resizing a chart', function() {
      const chart = acquireChart({
        type: 'bar',
        platform: Chart.platforms.BasicPlatform,
        data: {
          datasets: [
            {data: [10, 5, 0, 25, 78, -10]}
          ],
          labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5', 'tick6']
        }
      }, {
        canvas: {
          height: 150,
          width: 250
        }
      });

      expect(chart.platform).toBeInstanceOf(Chart.platforms.BasicPlatform);

      const canvasElement = chart.canvas;
      canvasElement.height = 200;
      canvasElement.width = 300;
      chart.resize();

      expect(chart.chartArea.bottom).toBeCloseToPixel(150);
      expect(chart.chartArea.left).toBeCloseToPixel(31);
      expect(chart.chartArea.right).toBeCloseToPixel(300);
      expect(chart.chartArea.top).toBeCloseToPixel(32);
    });
  });
});
