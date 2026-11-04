// Original code, not ported from Chart.js: official-site design previews.
import 'package:chartjs_gallery/site_drafts/site_drafts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

void main() {
  Chart.register(registerables);
  final design = Uri.base.queryParameters['design'];
  final direction = switch (design) {
    'workbench' => 1,
    'fieldnotes' => 2,
    _ => 0,
  };
  runApp(SiteDraftsApp(initialDirection: direction));
}
