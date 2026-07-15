import os
import re

target_dir = r"e:\Tahfidz\apps\tahfidzmu_app"

def fix_file(p):
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # match package:tahfidz_app/models/...
    c = re.sub(r"import\s+['\"]package:tahfidz_app/models/[^'\"]+\.dart['\"];", "import 'package:core_models/core_models.dart';", c)
    # match package:tahfidz_app/core/utils/quran_juz_utils.dart
    c = re.sub(r"import\s+['\"]package:tahfidz_app/core/utils/quran_juz_utils\.dart['\"];", "import 'package:core_models/core_models.dart';", c)
    # match relative paths ending with models/any.dart
    c = re.sub(r"import\s+['\"](?:\.\./)+models/[^'\"]+\.dart['\"];", "import 'package:core_models/core_models.dart';", c)
    # match relative paths ending with quran_juz_utils.dart
    c = re.sub(r"import\s+['\"](?:\.\./)+core/utils/quran_juz_utils\.dart['\"];", "import 'package:core_models/core_models.dart';", c)

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

for r, d, files in os.walk(target_dir):
    for f in files:
        if f.endswith('.dart'):
            fix_file(os.path.join(r, f))

pub_path = r'e:\Tahfidz\apps\tahfidzmu_app\pubspec.yaml'
with open(pub_path, 'r', encoding='utf-8') as f:
    pub = f.read()
if 'core_models:' not in pub:
    pub = pub.replace(
        'dependencies:\n  flutter:\n    sdk: flutter',
        'dependencies:\n  flutter:\n    sdk: flutter\n  core_models:\n    path: ../../packages/core_models'
    )
    with open(pub_path, 'w', encoding='utf-8') as f:
        f.write(pub)

print('Done!')
