describe('Chart', function() {
describe('plugin.extensions', function() {
    var hooks = {
      install: ['install'],
      uninstall: ['uninstall'],
      init: [
        'beforeInit',
        'resize',
        'afterInit'
      ],
      start: ['start'],
      stop: ['stop'],
      update: [
        'beforeUpdate',
        'beforeLayout',
        'beforeDataLimits', // y-axis fit
        'afterDataLimits',
        'beforeBuildTicks',
        'afterBuildTicks',
        'beforeDataLimits', // x-axis fit
        'afterDataLimits',
        'beforeBuildTicks',
        'afterBuildTicks',
        // 'beforeBuildTicks', // y-axis re-fit
        // 'afterBuildTicks',
        'afterLayout',
        'beforeDatasetsUpdate',
        'beforeDatasetUpdate',
        'afterDatasetUpdate',
        'afterDatasetsUpdate',
        'afterUpdate',
      ],
      render: [
        'beforeRender',
        'beforeDraw',
        'beforeDatasetsDraw',
        'beforeDatasetDraw',
        'afterDatasetDraw',
        'afterDatasetsDraw',
        // 'beforeTooltipDraw',
        // 'afterTooltipDraw',
        'afterDraw',
        'afterRender',
      ],
      resize: [
        'resize'
      ],
      destroy: [
        'beforeDestroy',
        'afterDestroy'
      ]
    };

    it('variant: notify plugin in correct order with explicit resize', function() {
      var plugin = this.plugin = {};
      var sequence = [];
      Object.keys(hooks).forEach(function(group) {
        hooks[group].forEach(function(name) {
          plugin[name] = function() { sequence.push(name); };
        });
      });
      var chart = window.acquireChart({
        type: 'line',
        data: {datasets: [{}]},
        plugins: [plugin],
        options: {responsive: true}
      }, {wrapper: {style: 'width: 300px'}});
      expect(chart.attached).toBeTrue();
      expect(sequence.slice()).toEqual([].concat(hooks.install, hooks.start, hooks.init, hooks.update, hooks.render));
      sequence.length = 0;
      chart.resize(400, 400);
      expect(sequence.slice()).toEqual([].concat(hooks.resize, hooks.update, hooks.render));
      sequence.length = 0;
      chart.destroy();
      expect(sequence.slice()).toEqual([].concat(hooks.destroy, hooks.stop, hooks.uninstall));
    });
  });
});
