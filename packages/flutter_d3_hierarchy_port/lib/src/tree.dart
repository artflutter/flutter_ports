// Ported from d3-hierarchy v3.1.2 src/tree.js (ISC, Mike Bostock).

/// Port of `src/tree.js` of d3-hierarchy 3.1.2: [TreeSeparation],
/// [TreeLayout], and [tree].
library;

import 'dart:typed_data';

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed TreeLayout<T>
// returning HierarchyPointNode<T> and using immutable `(double, double)?` size
// records.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, flat unboxed `Int32List`
// + `Float64List` Buchheim/Reingold-Tilford workspace eliminating per-node
// `_TreeNode` and child-list allocations and inlining default separation.

/// Separation function between two neighboring [HierarchyPointNode]s.
typedef TreeSeparation<T> = double Function(
  HierarchyPointNode<T> a,
  HierarchyPointNode<T> b,
);

double _defaultSeparation<T>(
  HierarchyPointNode<T> a,
  HierarchyPointNode<T> b,
) => identical(a.parent, b.parent) ? 1.0 : 2.0;

/// Node-link tree diagram using the Reingold-Tilford "tidy" algorithm
/// (Buchheim et al.'s linear-time implementation).
final class TreeLayout<T>({
  TreeSeparation<T>? separation,
  (double, double)? size,
  (double, double)? nodeSize,
}) {
  /// Creates a [TreeLayout] with optional [size], [nodeSize], and [separation].
  this;

  /// Separation function between adjacent nodes.
  TreeSeparation<T> separation = separation ?? _defaultSeparation<T>;

  double _dx = nodeSize != null ? nodeSize.$1 : (size != null ? size.$1 : 1.0);
  double _dy = nodeSize != null ? nodeSize.$2 : (size != null ? size.$2 : 1.0);
  bool _nodeSize = nodeSize != null;

  /// Overall layout size `(width, height)`, or `null` when [nodeSize] is
  /// active.
  (double, double)? get size => _nodeSize ? null : (_dx, _dy);

  /// Sets the overall layout size and disables [nodeSize].
  set size((double, double)? value) {
    if (value == null) {
      _nodeSize = true;
    } else {
      _nodeSize = false;
      _dx = value.$1;
      _dy = value.$2;
    }
  }

  /// Fixed node spacing `(dx, dy)`, or `null` when [size] is active.
  (double, double)? get nodeSize => _nodeSize ? (_dx, _dy) : null;

  /// Sets the fixed node spacing and disables [size].
  set nodeSize((double, double)? value) {
    if (value == null) {
      _nodeSize = false;
    } else {
      _nodeSize = true;
      _dx = value.$1;
      _dy = value.$2;
    }
  }

  /// Lays out [root] as a tidy tree and returns a [HierarchyPointNode<T>].
  HierarchyPointNode<T> call(HierarchyNode<T> root) {
    final pointRoot = hierarchyToPoint<T>(root);

    // Collect all nodes in BFS order (guarantees children are contiguous and
    // reverse index order is a valid post-order!).
    final nodes = <HierarchyPointNode<T>>[pointRoot];
    var head = 0;
    while (head < nodes.length) {
      final ch = nodes[head++].children;
      if (ch != null) {
        for (var i = 0, len = ch.length; i < len; ++i) {
          nodes.add(ch[i]);
        }
      }
    }
    final n = nodes.length;
    final sentinel = n;
    final cap = n + 1;

    // Flat unboxed tree workspace (indices 0..n-1 are nodes, index n is root's
    // sentinel parent).
    final parentArr = Int32List(cap);
    final firstChild = Int32List(cap)..fillRange(0, cap, -1);
    final lastChild = Int32List(cap)..fillRange(0, cap, -1);
    final prevSib = Int32List(cap)..fillRange(0, cap, -1);
    final sibIdx = Int32List(cap);
    final thread = Int32List(cap)..fillRange(0, cap, -1);
    final defAnc = Int32List(cap)..fillRange(0, cap, -1);
    final anc = Int32List(cap);
    for (var i = 0; i < cap; ++i) {
      anc[i] = i;
    }

    // Fill topology from BFS order (children of node u are contiguous!).
    parentArr[0] = sentinel;
    parentArr[sentinel] = -1;
    firstChild[sentinel] = 0;
    lastChild[sentinel] = 0;
    var cursor = 1;
    for (var u = 0; u < n; ++u) {
      final ch = nodes[u].children;
      if (ch != null) {
        final len = ch.length;
        firstChild[u] = cursor;
        lastChild[u] = cursor + len - 1;
        for (var j = 0; j < len; ++j) {
          final v = cursor + j;
          parentArr[v] = u;
          sibIdx[v] = j;
          if (j > 0) prevSib[v] = v - 1;
        }
        cursor += len;
      }
    }

    final z = Float64List(cap);
    final m = Float64List(cap);
    final c = Float64List(cap);
    final s = Float64List(cap);

    final sep = separation;
    final isDefaultSep = identical(sep, _defaultSeparation<T>);

    @pragma('vm:prefer-inline')
    double sepNodes(int u, int v) => isDefaultSep
        ? (parentArr[u] == parentArr[v] ? 1.0 : 2.0)
        : sep(nodes[u], nodes[v]);

    // Buchheim et al.'s firstWalk in exact post-order (children left-to-right).
    // Note: in reverse BFS order, siblings at the same depth would be visited
    // right-to-left, so we run a lightweight post-order index traversal that
    // visits children strictly left-to-right, matching upstream order exactly.
    void firstWalk(int v) {
      final fc = firstChild[v];
      if (fc >= 0) {
        final lc = lastChild[v];
        for (var ch = fc; ch <= lc; ++ch) {
          firstWalk(ch);
        }
        // executeShifts(v)
        var shift = 0.0;
        var change = 0.0;
        for (var w = lc; w >= fc; --w) {
          z[w] += shift;
          m[w] += shift;
          shift += s[w] + (change += c[w]);
        }
        final midpoint = (z[fc] + z[lc]) * 0.5;
        final w = prevSib[v];
        if (w >= 0) {
          z[v] = z[w] + sepNodes(v, w);
          m[v] = z[v] - midpoint;
        } else {
          z[v] = midpoint;
        }
      } else {
        final w = prevSib[v];
        if (w >= 0) {
          z[v] = z[w] + sepNodes(v, w);
        }
      }

      // apportion(v, w, defaultAncestor)
      final pv = parentArr[v];
      final w = prevSib[v];
      var ancestor = defAnc[pv];
      if (ancestor < 0) ancestor = firstChild[pv];
      if (w >= 0) {
        var vip = v;
        var vop = v;
        var vim = w;
        var vom = firstChild[pv];
        var sip = m[vip];
        var sop = m[vop];
        var sim = m[vim];
        var som = m[vom];
        while (true) {
          final nextVim = lastChild[vim] >= 0 ? lastChild[vim] : thread[vim];
          final nextVip = firstChild[vip] >= 0 ? firstChild[vip] : thread[vip];
          if (nextVim < 0 || nextVip < 0) {
            if (nextVim >= 0 && lastChild[vop] < 0 && thread[vop] < 0) {
              thread[vop] = nextVim;
              m[vop] += sim - sop;
            }
            if (nextVip >= 0 && firstChild[vom] < 0 && thread[vom] < 0) {
              thread[vom] = nextVip;
              m[vom] += sip - som;
              ancestor = v;
            }
            break;
          }
          vim = nextVim;
          vip = nextVip;
          vom = firstChild[vom] >= 0 ? firstChild[vom] : thread[vom];
          vop = lastChild[vop] >= 0 ? lastChild[vop] : thread[vop];
          anc[vop] = v;
          final sh = z[vim] + sim - z[vip] - sip + sepNodes(vim, vip);
          if (sh > 0) {
            final av = anc[vim];
            final wm = parentArr[av] == pv ? av : ancestor;
            final chg = sh / (sibIdx[v] - sibIdx[wm]);
            c[v] -= chg;
            s[v] += sh;
            c[wm] += chg;
            z[v] += sh;
            m[v] += sh;
            sip += sh;
            sop += sh;
          }
          sim += m[vim];
          sip += m[vip];
          som += m[vom];
          sop += m[vop];
        }
      }
      defAnc[pv] = ancestor;
    }

    if (pointRoot.height <= 512) {
      firstWalk(0);
    } else {
      // Stack-safe iterative post-order (children left-to-right).
      final st = Int32List(n);
      final post = Int32List(n);
      var sp = 0;
      var pp = 0;
      st[sp++] = 0;
      while (sp > 0) {
        final u = st[--sp];
        post[pp++] = u;
        final fc = firstChild[u];
        if (fc >= 0) {
          final lc = lastChild[u];
          for (var ch = fc; ch <= lc; ++ch) {
            st[sp++] = ch;
          }
        }
      }
      while (pp > 0) {
        final v = post[--pp];
        final fc = firstChild[v];
        if (fc >= 0) {
          final lc = lastChild[v];
          var shift = 0.0;
          var change = 0.0;
          for (var w = lc; w >= fc; --w) {
            z[w] += shift;
            m[w] += shift;
            shift += s[w] + (change += c[w]);
          }
          final midpoint = (z[fc] + z[lc]) * 0.5;
          final w = prevSib[v];
          if (w >= 0) {
            z[v] = z[w] + sepNodes(v, w);
            m[v] = z[v] - midpoint;
          } else {
            z[v] = midpoint;
          }
        } else {
          final w = prevSib[v];
          if (w >= 0) {
            z[v] = z[w] + sepNodes(v, w);
          }
        }
        final pv = parentArr[v];
        final w = prevSib[v];
        var ancestor = defAnc[pv];
        if (ancestor < 0) ancestor = firstChild[pv];
        if (w >= 0) {
          var vip = v;
          var vop = v;
          var vim = w;
          var vom = firstChild[pv];
          var sip = m[vip];
          var sop = m[vop];
          var sim = m[vim];
          var som = m[vom];
          while (true) {
            final nextVim = lastChild[vim] >= 0 ? lastChild[vim] : thread[vim];
            final nextVip = firstChild[vip] >= 0
                ? firstChild[vip]
                : thread[vip];
            if (nextVim < 0 || nextVip < 0) {
              if (nextVim >= 0 && lastChild[vop] < 0 && thread[vop] < 0) {
                thread[vop] = nextVim;
                m[vop] += sim - sop;
              }
              if (nextVip >= 0 && firstChild[vom] < 0 && thread[vom] < 0) {
                thread[vom] = nextVip;
                m[vom] += sip - som;
                ancestor = v;
              }
              break;
            }
            vim = nextVim;
            vip = nextVip;
            vom = firstChild[vom] >= 0 ? firstChild[vom] : thread[vom];
            vop = lastChild[vop] >= 0 ? lastChild[vop] : thread[vop];
            anc[vop] = v;
            final sh = z[vim] + sim - z[vip] - sip + sepNodes(vim, vip);
            if (sh > 0) {
              final av = anc[vim];
              final wm = parentArr[av] == pv ? av : ancestor;
              final chg = sh / (sibIdx[v] - sibIdx[wm]);
              c[v] -= chg;
              s[v] += sh;
              c[wm] += chg;
              z[v] += sh;
              m[v] += sh;
              sip += sh;
              sop += sh;
            }
            sim += m[vim];
            sip += m[vip];
            som += m[vom];
            sop += m[vop];
          }
        }
        defAnc[pv] = ancestor;
      }
    }

    // secondWalk: forward BFS order visits every parent before its children!
    m[sentinel] = -z[0];
    if (_nodeSize) {
      final dx = _dx;
      final dy = _dy;
      for (var u = 0; u < n; ++u) {
        final pm = m[parentArr[u]];
        final xu = z[u] + pm;
        m[u] += pm;
        final node = nodes[u];
        node
          ..x = xu * dx
          ..y = node.depth * dy;
      }
    } else {
      var leftIdx = 0;
      var rightIdx = 0;
      var maxDepth = pointRoot.depth;
      var minX = double.infinity;
      var maxX = double.negativeInfinity;
      for (var u = 0; u < n; ++u) {
        final pm = m[parentArr[u]];
        final xu = z[u] + pm;
        m[u] += pm;
        z[u] = xu; // reuse z[] to hold final unscaled x
        if (xu < minX) {
          minX = xu;
          leftIdx = u;
        }
        if (xu > maxX) {
          maxX = xu;
          rightIdx = u;
        }
        final d = nodes[u].depth;
        if (d > maxDepth) maxDepth = d;
      }
      final sepLR = leftIdx == rightIdx
          ? 1.0
          : sepNodes(leftIdx, rightIdx) * 0.5;
      final tx = sepLR - minX;
      final kx = _dx / (maxX + sepLR + tx);
      final ky = _dy / (maxDepth != 0 ? maxDepth : 1);
      for (var u = 0; u < n; ++u) {
        final node = nodes[u];
        node
          ..x = (z[u] + tx) * kx
          ..y = node.depth * ky;
      }
    }

    return pointRoot;
  }
}

/// Creates a new [TreeLayout<T>] Reingold-Tilford tidy tree generator.
TreeLayout<T> tree<T>({
  TreeSeparation<T>? separation,
  (double, double)? size,
  (double, double)? nodeSize,
}) => TreeLayout<T>(separation: separation, size: size, nodeSize: nodeSize);
