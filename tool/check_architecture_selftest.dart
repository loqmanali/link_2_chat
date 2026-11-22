// Seeded violations for tool/check_architecture.dart. Each rule gets a
// throw-away project that must FAIL naming that rule; a clean base and a few
// negative controls must PASS. Run from the project root:
//
//   dart run tool/check_architecture_selftest.dart
import 'dart:io';

const String appPubspec = '''
name: sample_app
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''';

const String kitPubspec = '''
name: sample_app_toast
resolution: workspace
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
''';

Map<String, String> base() => {
  'pubspec.yaml': '${appPubspec}workspace:\n  - packages/sample_app_toast\n',
  'lib/main.dart':
      "import 'package:flutter/material.dart';\n"
      "import 'package:sample_app/other.dart';\n"
      'class A extends StatelessWidget {\n'
      '  const A({super.key});\n'
      '  @override\n'
      '  Widget build(BuildContext context) =>\n'
      '      const Padding(padding: EdgeInsetsDirectional.only(start: 1));\n'
      '}\n',
  'lib/other.dart': 'const int x = 1;\n',
  'packages/sample_app_toast/pubspec.yaml': kitPubspec,
  'packages/sample_app_toast/lib/t.dart': 'const int t = 1;\n',
  '.env.example': 'FOO=\n',
};

const String pemHeader =
    '-----BEGIN '
    'PRIVATE KEY-----'; // split on purpose

class Seed {
  Seed(this.name, this.rule, this.files, {this.args = const []});
  final String name;
  final String? rule; // null: must pass
  final Map<String, String> files;
  final List<String> args;
}

String appWith(String extraPubspec) =>
    '$appPubspec$extraPubspec'
    'workspace:\n  - packages/sample_app_toast\n';

final List<Seed> seeds = [
  Seed('clean base', null, {}),
  Seed('relative import leaves the project', 'path-leaves-project', {
    'lib/bad.dart': "import '../../outside/x.dart';\n",
  }),
  Seed('pubspec path leaves the project', 'path-leaves-project', {
    'pubspec.yaml': appWith('  other:\n    path: ../other\n'),
  }),
  Seed('workspace member leaves the project', 'path-leaves-project', {
    'pubspec.yaml': '${appPubspec}workspace:\n  - ../elsewhere\n',
  }),
  Seed('package import not in pubspec', 'undeclared-package', {
    'lib/bad.dart': "import 'package:http/http.dart';\n",
  }),
  Seed('package import not in a kit pubspec', 'undeclared-package', {
    'packages/sample_app_toast/lib/t.dart': "import 'package:dio/dio.dart';\n",
  }),
  Seed('git dependency (block form)', 'git-dependency', {
    'pubspec.yaml': appWith(
      '  thing:\n    git:\n      url: https://example.com/x.git\n',
    ),
  }),
  Seed('git dependency (inline form)', 'git-dependency', {
    'pubspec.yaml': appWith('  thing: {git: https://example.com/x.git}\n'),
  }),
  Seed('git source in lockfile', 'git-dependency', {
    'pubspec.lock': 'packages:\n  thing:\n    source: git\n',
  }),
  Seed('part g.dart', 'codegen', {'lib/bad.dart': "part 'bad.g.dart';\n"}),
  Seed('@riverpod', 'codegen', {
    'lib/bad.dart': '@riverpod\nint foo(Ref ref) => 1;\n',
  }),
  Seed('@freezed', 'codegen', {'lib/bad.dart': '@freezed\nclass A {}\n'}),
  Seed('hooks widget', 'hooks', {
    'lib/bad.dart': 'class A extends HookConsumerWidget {}\n',
  }),
  for (final pkg in [
    'build_runner',
    'freezed',
    'json_serializable',
    'riverpod_generator',
    'drift',
    'flutter_hooks',
    'hooks_riverpod',
    'get_it',
  ])
    Seed('$pkg in the app pubspec', 'banned-package', {
      'pubspec.yaml': appWith('  $pkg: ^1.0.0\n'),
    }),
  Seed('banned package imported', 'banned-package', {
    'lib/bad.dart': "import 'package:get_it/get_it.dart';\n",
  }),
  Seed('build_runner in a package pubspec', 'banned-package', {
    'packages/sample_app_toast/pubspec.yaml':
        '${kitPubspec}dev_dependencies:\n  build_runner: ^2.0.0\n',
  }),
  Seed('widget-returning method', 'widget-method', {
    'lib/bad.dart':
        'class B {\n  Widget _buildThing() {\n    return x;\n  }\n}\n',
  }),
  Seed('widget-returning getter', 'widget-method', {
    'lib/bad.dart': 'class B {\n  Widget get thing => x;\n}\n',
  }),
  Seed('widget-returning top-level function', 'widget-method', {
    'lib/bad.dart': 'Widget row(int i) => x;\n',
  }),
  Seed('build() is the framework override, not a helper', null, {
    'lib/ok.dart':
        'class T {\n  @override\n  Widget build(Object c) => x;\n}\n',
  }),
  Seed('a helper widget in a test file is allowed', null, {
    'test/ok_test.dart': 'Widget _host() => x;\n',
  }),
  Seed('setState', 'set-state', {
    'lib/bad.dart': 'void f() {\n  setState(() {});\n}\n',
  }),
  Seed('setState in a package', 'set-state', {
    'packages/sample_app_toast/lib/t.dart': 'void f() { setState(() {}); }\n',
  }),
  Seed('setState in a comment is ignored', null, {
    'lib/ok.dart': '// never call setState(() {}) here\nconst int y = 1;\n',
  }),
  Seed('EdgeInsets.only(left:)', 'physical-direction', {
    'lib/bad.dart': 'final p = EdgeInsets.only(\n  left: 4,\n);\n',
  }),
  Seed('EdgeInsets.fromLTRB', 'physical-direction', {
    'lib/bad.dart': 'final p = EdgeInsets.fromLTRB(1, 2, 3, 4);\n',
  }),
  Seed('Alignment.centerLeft', 'physical-direction', {
    'lib/bad.dart': 'const a = Alignment.centerLeft;\n',
  }),
  Seed('Positioned(left:)', 'physical-direction', {
    'lib/bad.dart': 'final p = Positioned(left: 1, child: x);\n',
  }),
  Seed('TextAlign.right', 'physical-direction', {
    'lib/bad.dart': 'const t = TextAlign.right;\n',
  }),
  Seed('generated l10n files are skipped', null, {
    'lib/l10n/app_localizations.dart': 'Widget build() => x;\n',
  }),
  Seed('tracked .env', 'secret-file', {'.env': 'A=1\n'}),
  Seed('tracked .env.local', 'secret-file', {'env/.env.local': 'A=1\n'}),
  Seed('tracked .p8', 'secret-file', {'ios/AuthKey_X.p8': 'x\n'}),
  Seed('tracked .pem', 'secret-file', {'cert.pem': 'x\n'}),
  Seed('tracked keystore', 'secret-file', {'android/app/release.jks': 'x\n'}),
  Seed('tracked key.properties', 'secret-file', {
    'android/key.properties': 'x\n',
  }),
  Seed('tracked google-services.json', 'secret-file', {
    'android/app/google-services.json': '{}\n',
  }),
  Seed('tracked GoogleService-Info.plist', 'secret-file', {
    'ios/Runner/GoogleService-Info.plist': 'x\n',
  }),
  Seed('private key block in a source file', 'secret-content', {
    'lib/key.txt': '$pemHeader\nabc\n',
  }),
  // The exemption list: named kits are scanned, listed, and never fail.
  Seed(
    'an exempt kit with a violation passes, loudly',
    null,
    {'packages/sample_app_toast/lib/t.dart': 'void f() { setState(() {}); }\n'},
    args: ['--exempt', 'sample_app_toast'],
  ),
  Seed(
    'exempting one kit does not exempt the app',
    'set-state',
    {'lib/bad.dart': 'void f() { setState(() {}); }\n'},
    args: ['--exempt', 'sample_app_toast'],
  ),
];

String lastOutput = '';

Future<int> runChecker(Seed seed) async {
  final dir = Directory.systemTemp.createTempSync('arch_guard_');
  try {
    final files = base()..addAll(seed.files);
    files.forEach((p, c) {
      File('${dir.path}/$p')
        ..createSync(recursive: true)
        ..writeAsStringSync(c);
    });
    Process.runSync('git', ['init', '-q'], workingDirectory: dir.path);
    Process.runSync('git', ['add', '-A', '-f'], workingDirectory: dir.path);
    final r = await Process.run(Platform.resolvedExecutable, [
      'run',
      '${Directory.current.path}/tool/check_architecture.dart',
      '--root',
      dir.path,
      ...seed.args,
    ]);
    lastOutput = '${r.stdout}${r.stderr}';
    return r.exitCode;
  } finally {
    dir.deleteSync(recursive: true);
  }
}

Future<void> main() async {
  var bad = 0;
  for (final s in seeds) {
    final code = await runChecker(s);
    final String verdict;
    if (s.rule == null) {
      verdict = code == 0 ? 'ok' : 'WRONG (expected pass)';
    } else if (code != 1) {
      verdict = 'WRONG (expected failure, exit $code)';
    } else if (!lastOutput.contains('[${s.rule}]')) {
      verdict = 'WRONG (failed without [${s.rule}])';
    } else {
      verdict = 'ok';
    }
    final shown = s.rule == null ? 'PASS' : 'FAIL [${s.rule}]';
    stdout.writeln(
      '${verdict == 'ok' ? 'ok   ' : 'BAD  '}$shown  ${s.name}'
      '${verdict == 'ok' ? '' : '  -> $verdict\n$lastOutput'}',
    );
    if (verdict != 'ok') bad++;
  }
  // An exempt kit must be announced, never skipped silently.
  final exempt = seeds.firstWhere((s) => s.name.startsWith('an exempt kit'));
  await runChecker(exempt);
  final announced =
      lastOutput.contains('exempt [set-state]') &&
      lastOutput.contains('exempt-package: packages/sample_app_toast');
  stdout.writeln(
    '${announced ? 'ok   ' : 'BAD  '}an exempt kit is announced in the output',
  );
  if (!announced) bad++;
  stdout.writeln(
    bad == 0
        ? 'selftest: all ${seeds.length + 1} cases behaved as expected'
        : 'selftest: $bad of ${seeds.length + 1} cases wrong',
  );
  exit(bad == 0 ? 0 : 1);
}
