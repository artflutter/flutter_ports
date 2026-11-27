// Ported from d3-hierarchy v3.1.2 test/stratify-test.js (ISC, Mike Bostock).
// Test helper value classes override == without package:meta @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

final class const _Row({
  @override final String? id,
  @override final String? parentId,
}) implements StratifyDatum {
  @override
  bool operator ==(Object other) =>
      other is _Row && id == other.id && parentId == other.parentId;

  @override
  int get hashCode => Object.hash(id, parentId);
}

final class const _FooRow({
  final String? id,
  final String? foo,
  final String? parentId,
}) {
  @override
  bool operator ==(Object other) =>
      other is _FooRow &&
      id == other.id &&
      foo == other.foo &&
      parentId == other.parentId;

  @override
  int get hashCode => Object.hash(id, foo, parentId);
}

final class const _PathRow(final String path, {final int? number}) {
  @override
  bool operator ==(Object other) =>
      other is _PathRow && path == other.path && number == other.number;

  @override
  int get hashCode => Object.hash(path, number);
}

Map<String, Object?> _noparent<T>(HierarchyNode<T> node) {
  final map = <String, Object?>{
    if (node.id != null) 'id': node.id,
    'depth': node.depth,
    'height': node.height,
    'data': node.data,
    if (node.children != null)
      'children': [for (final c in node.children!) _noparent(c)],
  };
  return map;
}

void main() {
  test('stratify() has the expected defaults', () {
    final s = stratify<_Row>();
    expect(s.id!(const _Row(id: 'foo')), 'foo');
    expect(s.parentId!(const _Row(parentId: 'bar')), 'bar');
  });

  test('stratify(data) returns the root node', () {
    final s = stratify<_Row>();
    final root = s(const [
      _Row(id: 'a'),
      _Row(id: 'aa', parentId: 'a'),
      _Row(id: 'ab', parentId: 'a'),
      _Row(id: 'aaa', parentId: 'aa'),
    ]);
    expect(root, isA<HierarchyNode<_Row>>());
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 2,
      'data': const _Row(id: 'a'),
      'children': [
        {
          'id': 'aa',
          'depth': 1,
          'height': 1,
          'data': const _Row(id: 'aa', parentId: 'a'),
          'children': [
            {
              'id': 'aaa',
              'depth': 2,
              'height': 0,
              'data': const _Row(id: 'aaa', parentId: 'aa'),
            },
          ],
        },
        {
          'id': 'ab',
          'depth': 1,
          'height': 0,
          'data': const _Row(id: 'ab', parentId: 'a'),
        },
      ],
    });
  });

  test(
    'stratify(data) does not require the data to be in topological order',
    () {
      final s = stratify<_Row>();
      final root = s(const [
        _Row(id: 'aaa', parentId: 'aa'),
        _Row(id: 'aa', parentId: 'a'),
        _Row(id: 'ab', parentId: 'a'),
        _Row(id: 'a'),
      ]);
      expect(_noparent(root), {
        'id': 'a',
        'depth': 0,
        'height': 2,
        'data': const _Row(id: 'a'),
        'children': [
          {
            'id': 'aa',
            'depth': 1,
            'height': 1,
            'data': const _Row(id: 'aa', parentId: 'a'),
            'children': [
              {
                'id': 'aaa',
                'depth': 2,
                'height': 0,
                'data': const _Row(id: 'aaa', parentId: 'aa'),
              },
            ],
          },
          {
            'id': 'ab',
            'depth': 1,
            'height': 0,
            'data': const _Row(id: 'ab', parentId: 'a'),
          },
        ],
      });
    },
  );

  test('stratify(data) preserves the input order of siblings', () {
    final s = stratify<_Row>();
    final root = s(const [
      _Row(id: 'aaa', parentId: 'aa'),
      _Row(id: 'ab', parentId: 'a'),
      _Row(id: 'aa', parentId: 'a'),
      _Row(id: 'a'),
    ]);
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 2,
      'data': const _Row(id: 'a'),
      'children': [
        {
          'id': 'ab',
          'depth': 1,
          'height': 0,
          'data': const _Row(id: 'ab', parentId: 'a'),
        },
        {
          'id': 'aa',
          'depth': 1,
          'height': 1,
          'data': const _Row(id: 'aa', parentId: 'a'),
          'children': [
            {
              'id': 'aaa',
              'depth': 2,
              'height': 0,
              'data': const _Row(id: 'aaa', parentId: 'aa'),
            },
          ],
        },
      ],
    });
  });

  test('stratify(data) accepts an iterable', () {
    final s = stratify<_Row>();
    final root = s({
      const _Row(id: 'aaa', parentId: 'aa'),
      const _Row(id: 'ab', parentId: 'a'),
      const _Row(id: 'aa', parentId: 'a'),
      const _Row(id: 'a'),
    });
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 2,
      'data': const _Row(id: 'a'),
      'children': [
        {
          'id': 'ab',
          'depth': 1,
          'height': 0,
          'data': const _Row(id: 'ab', parentId: 'a'),
        },
        {
          'id': 'aa',
          'depth': 1,
          'height': 1,
          'data': const _Row(id: 'aa', parentId: 'a'),
          'children': [
            {
              'id': 'aaa',
              'depth': 2,
              'height': 0,
              'data': const _Row(id: 'aaa', parentId: 'aa'),
            },
          ],
        },
      ],
    });
  });

  test('stratify(data) treats an empty parentId as the root', () {
    final s = stratify<_Row>();
    final root = s(const [
      _Row(id: 'a', parentId: ''),
      _Row(id: 'aa', parentId: 'a'),
      _Row(id: 'ab', parentId: 'a'),
      _Row(id: 'aaa', parentId: 'aa'),
    ]);
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 2,
      'data': const _Row(id: 'a', parentId: ''),
      'children': [
        {
          'id': 'aa',
          'depth': 1,
          'height': 1,
          'data': const _Row(id: 'aa', parentId: 'a'),
          'children': [
            {
              'id': 'aaa',
              'depth': 2,
              'height': 0,
              'data': const _Row(id: 'aaa', parentId: 'aa'),
            },
          ],
        },
        {
          'id': 'ab',
          'depth': 1,
          'height': 0,
          'data': const _Row(id: 'ab', parentId: 'a'),
        },
      ],
    });
  });

  test(
    'stratify(data) does not treat a falsy but non-empty parentId as the root',
    () {
      final s = stratify<({int id, int? parentId})>(
        id: (d) => '${d.id}',
        parentId: (d) => d.parentId?.toString(),
      );
      final root = s(const [
        (id: 0, parentId: null),
        (id: 1, parentId: 0),
        (id: 2, parentId: 0),
      ]);
      expect(_noparent(root), {
        'id': '0',
        'depth': 0,
        'height': 1,
        'data': (id: 0, parentId: null),
        'children': [
          {'id': '1', 'depth': 1, 'height': 0, 'data': (id: 1, parentId: 0)},
          {'id': '2', 'depth': 1, 'height': 0, 'data': (id: 2, parentId: 0)},
        ],
      });
    },
  );

  test(
    'stratify(data) throws an error if the data does not have a single root',
    () {
      final s = stratify<_Row>();
      expect(
        () => s(const [_Row(id: 'a'), _Row(id: 'b')]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('multiple roots'),
          ),
        ),
      );
      expect(
        () => s(const [_Row(id: 'a', parentId: 'a')]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('no root'),
          ),
        ),
      );
      expect(
        () => s(const [
          _Row(id: 'a', parentId: 'b'),
          _Row(id: 'b', parentId: 'a'),
        ]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('no root'),
          ),
        ),
      );
    },
  );

  test('stratify(data) throws an error if the hierarchy is cyclical', () {
    final s = stratify<_Row>();
    expect(
      () => s(const [_Row(id: 'root'), _Row(id: 'a', parentId: 'a')]),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('cycle'),
        ),
      ),
    );
    expect(
      () => s(const [
        _Row(id: 'root'),
        _Row(id: 'a', parentId: 'b'),
        _Row(id: 'b', parentId: 'a'),
      ]),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('cycle'),
        ),
      ),
    );
  });

  test(
    'stratify(data) throws an error if multiple parents have the same id',
    () {
      final s = stratify<_Row>();
      expect(
        () => s(const [
          _Row(id: 'a'),
          _Row(id: 'b', parentId: 'a'),
          _Row(id: 'b', parentId: 'a'),
          _Row(id: 'c', parentId: 'b'),
        ]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('ambiguous'),
          ),
        ),
      );
    },
  );

  test(
    'stratify(data) throws an error if the specified parent is not found',
    () {
      final s = stratify<_Row>();
      expect(
        () => s(const [_Row(id: 'a'), _Row(id: 'b', parentId: 'c')]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('missing'),
          ),
        ),
      );
    },
  );

  test('stratify(data) allows the id to be undefined for leaf nodes', () {
    final s = stratify<_Row>();
    final root = s(const [
      _Row(id: 'a'),
      _Row(parentId: 'a'),
      _Row(parentId: 'a'),
    ]);
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 1,
      'data': const _Row(id: 'a'),
      'children': [
        {'depth': 1, 'height': 0, 'data': const _Row(parentId: 'a')},
        {'depth': 1, 'height': 0, 'data': const _Row(parentId: 'a')},
      ],
    });
  });

  test('stratify(data) allows the id to be non-unique for leaf nodes', () {
    final s = stratify<_Row>();
    final root = s(const [
      _Row(id: 'a'),
      _Row(id: 'b', parentId: 'a'),
      _Row(id: 'b', parentId: 'a'),
    ]);
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 1,
      'data': const _Row(id: 'a'),
      'children': [
        {
          'id': 'b',
          'depth': 1,
          'height': 0,
          'data': const _Row(id: 'b', parentId: 'a'),
        },
        {
          'id': 'b',
          'depth': 1,
          'height': 0,
          'data': const _Row(id: 'b', parentId: 'a'),
        },
      ],
    });
  });

  test(
    'stratify(data) coerces the id to a string, if not null and not empty',
    () {
      final s = stratify<_Row>();
      expect(s(const [_Row(id: 'a')]).id, 'a');
      expect(s(const [_Row(id: '')]).id, isNull);
      expect(s(const [_Row()]).id, isNull);
    },
  );

  test(
    'stratify(data) allows the id to be undefined for leaf nodes (toString '
    'parentId)',
    () {},
    skip: 'diverges: adapt-hierarchy-typed-api',
  );

  test('stratify.id(id) observes the specified id function', () {
    String? foo(_FooRow d) => d.foo;
    final s = stratify<_FooRow>(id: foo, parentId: (d) => d.parentId);
    final root = s(const [
      _FooRow(foo: 'a'),
      _FooRow(foo: 'aa', parentId: 'a'),
      _FooRow(foo: 'ab', parentId: 'a'),
      _FooRow(foo: 'aaa', parentId: 'aa'),
    ]);
    expect(s.id, foo);
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 2,
      'data': const _FooRow(foo: 'a'),
      'children': [
        {
          'id': 'aa',
          'depth': 1,
          'height': 1,
          'data': const _FooRow(foo: 'aa', parentId: 'a'),
          'children': [
            {
              'id': 'aaa',
              'depth': 2,
              'height': 0,
              'data': const _FooRow(foo: 'aaa', parentId: 'aa'),
            },
          ],
        },
        {
          'id': 'ab',
          'depth': 1,
          'height': 0,
          'data': const _FooRow(foo: 'ab', parentId: 'a'),
        },
      ],
    });
  });

  test(
    'stratify.id(id) tests that id is a function',
    () {},
    skip: 'diverges: adapt-hierarchy-typed-api',
  );

  test('stratify.parentId(id) observes the specified parent id function', () {
    String? foo(_FooRow d) => d.foo;
    final s = stratify<_FooRow>(id: (d) => d.id, parentId: foo);
    final root = s(const [
      _FooRow(id: 'a'),
      _FooRow(id: 'aa', foo: 'a'),
      _FooRow(id: 'ab', foo: 'a'),
      _FooRow(id: 'aaa', foo: 'aa'),
    ]);
    expect(s.parentId, foo);
    expect(_noparent(root), {
      'id': 'a',
      'depth': 0,
      'height': 2,
      'data': const _FooRow(id: 'a'),
      'children': [
        {
          'id': 'aa',
          'depth': 1,
          'height': 1,
          'data': const _FooRow(id: 'aa', foo: 'a'),
          'children': [
            {
              'id': 'aaa',
              'depth': 2,
              'height': 0,
              'data': const _FooRow(id: 'aaa', foo: 'aa'),
            },
          ],
        },
        {
          'id': 'ab',
          'depth': 1,
          'height': 0,
          'data': const _FooRow(id: 'ab', foo: 'a'),
        },
      ],
    });
  });

  test(
    'stratify.parentId(id) tests that id is a function',
    () {},
    skip: 'diverges: adapt-hierarchy-typed-api',
  );

  test('stratify.path(path) returns the root node', () {
    final root = stratify<_PathRow>(path: (d) => d.path)(const [
      _PathRow('/'),
      _PathRow('/aa'),
      _PathRow('/ab'),
      _PathRow('/aa/aaa'),
    ]);
    expect(root, isA<HierarchyNode<_PathRow>>());
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': const _PathRow('/'),
      'children': [
        {
          'id': '/aa',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('/aa'),
          'children': [
            {
              'id': '/aa/aaa',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('/aa/aaa'),
            },
          ],
        },
        {'id': '/ab', 'depth': 1, 'height': 0, 'data': const _PathRow('/ab')},
      ],
    });
  });

  test('stratify.path(path) correctly handles single-character folders', () {
    final root = stratify<_PathRow>(path: (d) => d.path)(const [
      _PathRow('/'),
      _PathRow('/d'),
      _PathRow('/d/123'),
    ]);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': const _PathRow('/'),
      'children': [
        {
          'id': '/d',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('/d'),
          'children': [
            {
              'id': '/d/123',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('/d/123'),
            },
          ],
        },
      ],
    });
  });

  test('stratify.path(path) correctly handles empty folders', () {
    final root = stratify<_PathRow>(path: (d) => d.path)(const [
      _PathRow('/'),
      _PathRow('//'),
      _PathRow('///'),
    ]);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': const _PathRow('/'),
      'children': [
        {
          'id': '//',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('//'),
          'children': [
            {
              'id': '///',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('///'),
            },
          ],
        },
      ],
    });
  });

  test('stratify.path(path) correctly handles single-character folders with '
      'trailing slashes', () {
    final root = stratify<_PathRow>(path: (d) => d.path)(const [
      _PathRow('/'),
      _PathRow('/d/'),
      _PathRow('/d/123/'),
    ]);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': const _PathRow('/'),
      'children': [
        {
          'id': '/d',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('/d/'),
          'children': [
            {
              'id': '/d/123',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('/d/123/'),
            },
          ],
        },
      ],
    });
  });

  test(
    'stratify.path(path) correctly handles imputed single-character folders',
    () {
      final root = stratifyPath<_PathRow>(const [
        _PathRow('/'),
        _PathRow('/d/123'),
      ], (d) => d.path);
      expect(_noparent(root), {
        'id': '/',
        'depth': 0,
        'height': 2,
        'data': const _PathRow('/'),
        'children': [
          {
            'id': '/d',
            'depth': 1,
            'height': 1,
            'data': null,
            'children': [
              {
                'id': '/d/123',
                'depth': 2,
                'height': 0,
                'data': const _PathRow('/d/123'),
              },
            ],
          },
        ],
      });
    },
  );

  test('stratify.path(path) allows slashes to be escaped', () {
    final root = stratify<_PathRow>(path: (d) => d.path)(const [
      _PathRow('/'),
      _PathRow('/aa'),
      _PathRow(r'\/ab'),
      _PathRow(r'/aa\/aaa'),
    ]);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 1,
      'data': const _PathRow('/'),
      'children': [
        {'id': '/aa', 'depth': 1, 'height': 0, 'data': const _PathRow('/aa')},
        {
          'id': r'/\/ab',
          'depth': 1,
          'height': 0,
          'data': const _PathRow(r'\/ab'),
        },
        {
          'id': r'/aa\/aaa',
          'depth': 1,
          'height': 0,
          'data': const _PathRow(r'/aa\/aaa'),
        },
      ],
    });
  });

  test('stratify.path(path) imputes internal nodes', () {
    final root = stratifyPath<_PathRow>(const [
      _PathRow('/aa/aaa'),
      _PathRow('/ab'),
    ], (d) => d.path);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': null,
      'children': [
        {'id': '/ab', 'depth': 1, 'height': 0, 'data': const _PathRow('/ab')},
        {
          'id': '/aa',
          'depth': 1,
          'height': 1,
          'data': null,
          'children': [
            {
              'id': '/aa/aaa',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('/aa/aaa'),
            },
          ],
        },
      ],
    });
  });

  test('stratify.path(path) allows duplicate leaf paths', () {
    final root = stratifyPath<_PathRow>(const [
      _PathRow('/aa/aaa', number: 1),
      _PathRow('/aa/aaa', number: 2),
    ], (d) => d.path);
    expect(_noparent(root), {
      'id': '/aa',
      'depth': 0,
      'height': 1,
      'data': null,
      'children': [
        {
          'id': '/aa/aaa',
          'depth': 1,
          'height': 0,
          'data': const _PathRow('/aa/aaa', number: 1),
        },
        {
          'id': '/aa/aaa',
          'depth': 1,
          'height': 0,
          'data': const _PathRow('/aa/aaa', number: 2),
        },
      ],
    });
  });

  test('stratify.path(path) does not allow duplicate internal paths', () {
    expect(
      () => stratifyPath<_PathRow>(const [
        _PathRow('/aa'),
        _PathRow('/aa'),
        _PathRow('/aa/aaa'),
        _PathRow('/aa/aaa'),
      ], (d) => d.path),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('ambiguous'),
        ),
      ),
    );
  });

  test('stratify.path(path) implicitly adds leading slashes', () {
    final root = stratify<_PathRow>(path: (d) => d.path)(const [
      _PathRow(''),
      _PathRow('aa'),
      _PathRow('ab'),
      _PathRow('aa/aaa'),
    ]);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': const _PathRow(''),
      'children': [
        {
          'id': '/aa',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('aa'),
          'children': [
            {
              'id': '/aa/aaa',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('aa/aaa'),
            },
          ],
        },
        {'id': '/ab', 'depth': 1, 'height': 0, 'data': const _PathRow('ab')},
      ],
    });
  });

  test('stratify.path(path) implicitly trims trailing slashes', () {
    final root = stratifyPath<_PathRow>(const [
      _PathRow('/aa/'),
      _PathRow('/ab/'),
      _PathRow('/aa/aaa/'),
    ], (d) => d.path);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': null,
      'children': [
        {
          'id': '/aa',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('/aa/'),
          'children': [
            {
              'id': '/aa/aaa',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('/aa/aaa/'),
            },
          ],
        },
        {'id': '/ab', 'depth': 1, 'height': 0, 'data': const _PathRow('/ab/')},
      ],
    });
  });

  test(
    'stratify.path(path) does not trim trailing slashes preceded by a slash',
    () {
      final root = stratifyPath<_PathRow>(const [
        _PathRow('/aa//'),
        _PathRow('/b'),
      ], (d) => d.path);
      expect(_noparent(root), {
        'id': '/',
        'depth': 0,
        'height': 3,
        'data': null,
        'children': [
          {'id': '/b', 'depth': 1, 'height': 0, 'data': const _PathRow('/b')},
          {
            'id': '/aa',
            'depth': 1,
            'height': 2,
            'data': null,
            'children': [
              {
                'id': '/aa/',
                'depth': 2,
                'height': 1,
                'data': null,
                'children': [
                  {
                    'id': '/aa//',
                    'depth': 3,
                    'height': 0,
                    'data': const _PathRow('/aa//'),
                  },
                ],
              },
            ],
          },
        ],
      });
    },
  );

  test(
    'stratify.path(path) does not require the data to be in topological order',
    () {
      final root = stratifyPath<_PathRow>(const [
        _PathRow('/aa/aaa'),
        _PathRow('/aa'),
        _PathRow('/ab'),
      ], (d) => d.path);
      expect(_noparent(root), {
        'id': '/',
        'depth': 0,
        'height': 2,
        'data': null,
        'children': [
          {
            'id': '/aa',
            'depth': 1,
            'height': 1,
            'data': const _PathRow('/aa'),
            'children': [
              {
                'id': '/aa/aaa',
                'depth': 2,
                'height': 0,
                'data': const _PathRow('/aa/aaa'),
              },
            ],
          },
          {'id': '/ab', 'depth': 1, 'height': 0, 'data': const _PathRow('/ab')},
        ],
      });
    },
  );

  test('stratify.path(path) preserves the input order of siblings', () {
    final root = stratifyPath<_PathRow>(const [
      _PathRow('/ab'),
      _PathRow('/aa'),
      _PathRow('/aa/aaa'),
    ], (d) => d.path);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': null,
      'children': [
        {'id': '/ab', 'depth': 1, 'height': 0, 'data': const _PathRow('/ab')},
        {
          'id': '/aa',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('/aa'),
          'children': [
            {
              'id': '/aa/aaa',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('/aa/aaa'),
            },
          ],
        },
      ],
    });
  });

  test('stratify.path(path) accepts an iterable', () {
    final root = stratifyPath<_PathRow>({
      const _PathRow('/ab'),
      const _PathRow('/aa'),
      const _PathRow('/aa/aaa'),
    }, (d) => d.path);
    expect(_noparent(root), {
      'id': '/',
      'depth': 0,
      'height': 2,
      'data': null,
      'children': [
        {'id': '/ab', 'depth': 1, 'height': 0, 'data': const _PathRow('/ab')},
        {
          'id': '/aa',
          'depth': 1,
          'height': 1,
          'data': const _PathRow('/aa'),
          'children': [
            {
              'id': '/aa/aaa',
              'depth': 2,
              'height': 0,
              'data': const _PathRow('/aa/aaa'),
            },
          ],
        },
      ],
    });
  });

  test(
    'stratify.path(path) coerces paths to strings',
    () {},
    skip: 'diverges: adapt-hierarchy-typed-api',
  );
}
