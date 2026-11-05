#!/usr/bin/env python3
# Copyright (c) 2026 Vasiliy Ditsyak. SPDX-License-Identifier: MIT
"""Apply the patch to a temporary source copy and test the exact writer/capacity."""
import argparse
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('flutter_checkout', type=Path)
parser.add_argument('--patched', action='store_true', help='Source already contains the patch')
args = parser.parse_args()
package = Path(__file__).resolve().parent
relative = Path('engine/src/flutter/impeller/tessellator/tessellator.cc')
with tempfile.TemporaryDirectory(prefix='impeller-balanced-check-') as directory:
    work = Path(directory)
    source = work / relative
    source.parent.mkdir(parents=True)
    source.write_bytes((args.flutter_checkout / relative).read_bytes())
    if not args.patched:
        subprocess.run(['git', 'apply', '--check', str(package / 'impeller-balanced-fill.patch')], cwd=work, check=True)
        subprocess.run(['git', 'apply', str(package / 'impeller-balanced-fill.patch')], cwd=work, check=True)
    text = source.read_text()
    begin = text.index('template <typename IndexT>\nclass StripPathVertexWriter')
    end = text.index('/// @brief A vertex writer that has no hardware requirements.', begin)
    capacity_begin = text.index('      const size_t max_indices =')
    capacity_end = text.index('      BufferView point_buffer', capacity_begin)
    header = '''// Flutter writer: BSD-3-Clause, see LICENSE-Flutter.txt.
#pragma once
#include <cstddef>
#include <cstdint>
#include <limits>
namespace impeller {
struct Point { float x,y; };
struct PathTessellator { struct VertexWriter { virtual ~VertexWriter()=default;virtual void Write(Point)=0;virtual void EndContour()=0; }; };
}
'''
    header += text[begin:end]
    header += '''\ntemplate<class IndexT> size_t Capacity(size_t point_count,size_t contour_count) {
const bool supports_triangle_fan=false;
struct { bool IsConvex() const { return false; } } path;
'''
    header += text[capacity_begin:capacity_end] + '\nreturn index_capacity;\n}\n'
    (work / 'exact_writer.h').write_text(header)
    (work / 'check.cpp').write_bytes((package / 'check.cpp').read_bytes())
    compiler = shlex.split(os.environ['CXX']) if 'CXX' in os.environ else (['xcrun', 'clang++'] if sys.platform == 'darwin' else ['c++'])
    subprocess.run(compiler + ['-std=c++17', '-O1', '-g', '-Wall', '-Wextra', '-Werror', '-fsanitize=address,undefined', '-fno-omit-frame-pointer', str(work / 'check.cpp'), '-o', str(work / 'check')], check=True)
    subprocess.run([str(work / 'check')], check=True)
print('PASS patch applies; extracted writer and allocation tested with ASan/UBSan; SDK unchanged')
