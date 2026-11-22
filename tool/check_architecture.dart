// Architecture guard. Plain Dart, no packages.
//
//   dart run tool/check_architecture.dart                (from the project root)
//   dart run tool/check_architecture.dart --root <dir> [--exempt a,b]
//
// Every rule is a text scan, so it is a heuristic; code review covers what it
// misses. Each rule has a seeded violation in tool/check_architecture_selftest.dart.
// Secret values are never printed: only the rule, the path and the line number.
//
// Rules (the source of truth is the list below; keep SKILL.md in step):
//   git-dependency       no git source in a pubspec or the lockfile
//   banned-package       no code generation, no hooks, no service locator
//   undeclared-package   every package: import is declared in the nearest pubspec
//   path-leaves-project  path dependencies and relative imports stay inside
//   codegen / hooks      no generated part files, no generator annotations
//   set-state            no setState: state lives in Riverpod
//   widget-method        no method, getter or function returning a Widget
//   physical-direction   start/end only, never left/right
//   secret-file/-content no tracked key, .env or service config; no key material
//   exempt-package       (informational) violations found in an exempt kit
import 'dart:convert';
import 'dart:io';

/// Copied kit packages that are allowed to break the rules above, by folder name
/// under `packages/`. `scripts/create.sh --kits ...` adds a name here when it
/// copies a kit (kits are the owner's code, copied as they are, and some of
/// them predate these rules).
///
/// An exempt package is still scanned: its violations are printed as
/// `exempt [rule] path:line` and counted, and never fail the run. A package is
/// never skipped silently. Remove a name here once the kit is fixed.
const Set<String> exemptPackages = {
  // __EXEMPT_KITS__ (create.sh inserts names above this line)
};

const Set<String> bannedPackages = {
  'bloc',
  'build_runner',
  'flutter_bloc',
  'hive',
  'hive_flutter',
  'hive_generator',
  'freezed',
  'freezed_annotation',
  'json_serializable',
  'json_annotation',
  'riverpod_generator',
  'riverpod_annotation',
  'riverpod_lint',
  'custom_lint',
  'drift',
  'drift_dev',
  'go_router_builder',
  'flutter_hooks',
  'hooks_riverpod',
  'get_it',
  'injectable',
};

const Set<String> skipDirs = {
  '.dart_tool',
  'build',
  'node_modules',
  'Pods',
  '.symlinks',
  '.git',
  '.gradle',
  'ephemeral',
};

class Violation {
  Violation(this.rule, this.path, this.line, this.message);
  final String rule;
  final String path;
  final int line;
  final String message;
  @override
  String toString() => '[$rule] $path:$line $message';
}

late String root; // project root, no trailing slash
final List<Violation> violations = [];

void report(String rule, String path, int line, String message) =>
    violations.add(Violation(rule, rel(path), line, message));

String rel(String path) =>
    path.startsWith('$root/') ? path.substring(root.length + 1) : path;

String normalize(String path) => Uri.file(path).normalizePath().toFilePath();

bool insideProject(String path) {
  final p = normalize(path);
  return p == root || p.startsWith('$root/');
}

List<File> walk(Directory dir, bool Function(String name) wanted) {
  final out = <File>[];
  for (final e in dir.listSync(followLinks: false)) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is Directory) {
      if (!skipDirs.contains(name)) out.addAll(walk(e, wanted));
    } else if (e is File && wanted(name)) {
      out.add(e);
    }
  }
  return out;
}

// ---------------------------------------------------------------- pubspecs

class Pubspec {
  Pubspec(this.file, this.name, this.deps);
  final File file;
  final String name;
  final Set<String> deps; // dependencies + dev_dependencies + overrides
}

final Map<String, Pubspec> pubspecs = {}; // by directory

Pubspec parsePubspec(File f) {
  final lines = f.readAsLinesSync();
  var name = '';
  final deps = <String>{};
  String? section;
  String? dep;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].replaceFirst(RegExp(r'\s+#.*$'), '');
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    final t = line.trim();
    if (indent == 0) {
      final m = RegExp(r'^([A-Za-z_]+):\s*(.*)$').firstMatch(t);
      section = m?.group(1);
      dep = null;
      if (section == 'name') name = m!.group(2)!.trim();
      continue;
    }
    if (section == 'workspace' && t.startsWith('- ')) {
      final w = t.substring(2).trim();
      if (!insideProject(normalize('${f.parent.path}/$w'))) {
        report(
          'path-leaves-project',
          f.path,
          i + 1,
          'workspace member "$w" resolves outside the project',
        );
      }
      continue;
    }
    if (section == 'dependencies' ||
        section == 'dev_dependencies' ||
        section == 'dependency_overrides') {
      if (indent == 2) {
        final m = RegExp(r'^([A-Za-z0-9_]+):\s*(.*)$').firstMatch(t);
        if (m == null) continue;
        dep = m.group(1);
        deps.add(dep!);
        checkDependency(f, i + 1, dep, m.group(2)!);
      } else if (dep != null) {
        // sub-keys: git:, path:, sdk:, hosted:, version:
        if (t.startsWith('git:')) {
          report('git-dependency', f.path, i + 1, 'git dependency "$dep"');
        }
        final p = RegExp(r'^path:\s*(.+)$').firstMatch(t);
        if (p != null) checkPath(f, i + 1, dep, p.group(1)!.trim());
      }
    }
  }
  return Pubspec(f, name, deps);
}

void checkDependency(File f, int line, String dep, String inline) {
  if (bannedPackages.contains(dep)) {
    report(
      'banned-package',
      f.path,
      line,
      '"$dep" is banned (no codegen, no hooks, no service locator)',
    );
  }
  if (inline.contains('git:')) {
    report('git-dependency', f.path, line, 'git dependency "$dep"');
  }
  final p = RegExp(r'path:\s*([^,}\s]+)').firstMatch(inline);
  if (p != null) checkPath(f, line, dep, p.group(1)!);
}

void checkPath(File f, int line, String dep, String path) {
  final cleaned = path.replaceAll(RegExp('^[\'"]|[\'"]\$'), '');
  final target =
      cleaned.startsWith('/')
          ? normalize(cleaned)
          : normalize('${f.parent.path}/$cleaned');
  if (!insideProject(target)) {
    report(
      'path-leaves-project',
      f.path,
      line,
      'path dependency "$dep" resolves outside the project',
    );
  }
}

Pubspec? pubspecFor(File f) {
  var dir = f.parent;
  while (normalize(dir.path).startsWith(root)) {
    final p = pubspecs[dir.path];
    if (p != null) return p;
    if (dir.path == root) return null;
    dir = dir.parent;
  }
  return null;
}

// ------------------------------------------------------------------- sources

final RegExp directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
);

final RegExp widgetMethod = RegExp(
  r'^\s*(?:static\s+|external\s+)?'
  r'(?:Widget|PreferredSizeWidget|List<Widget>|Iterable<Widget>|Widget\?)\s+'
  r'(?:get\s+)?(\w+)\s*(?:<[^>]*>)?\s*(?:\(|=>)',
);

final List<(String, RegExp, String)> physicalDirection = [
  (
    'physical-direction',
    RegExp(r'EdgeInsets\.(?:only\([^)]*\b(?:left|right)\s*:|fromLTRB)'),
    'use EdgeInsetsDirectional (start/end)',
  ),
  (
    'physical-direction',
    RegExp(r'\bAlignment\.(?:center|top|bottom)(?:Left|Right)\b'),
    'use AlignmentDirectional',
  ),
  (
    'physical-direction',
    RegExp(r'\bPositioned\((?:[^)]*\b)?(?:left|right)\s*:'),
    'use PositionedDirectional',
  ),
  (
    'physical-direction',
    RegExp(r'\bTextAlign\.(?:left|right)\b'),
    'use TextAlign.start / end',
  ),
];

final List<(String, RegExp, String)> codegenText = [
  (
    'codegen',
    RegExp(r'''part\s+['"][^'"]*\.(?:g|freezed)\.dart['"]'''),
    'generated part file',
  ),
  ('codegen', RegExp(r'@[Rr]iverpod\b'), '@riverpod annotation'),
  ('codegen', RegExp(r'@freezed\b|@Freezed\('), '@freezed annotation'),
  ('codegen', RegExp(r'@JsonSerializable\b'), '@JsonSerializable annotation'),
  (
    'hooks',
    RegExp(r'extends\s+(?:Hook\w*Widget|Hook\w*Component)\b'),
    'hooks widget',
  ),
];

bool isCommentOnly(String line) {
  final t = line.trimLeft();
  return t.startsWith('//') || t.startsWith('*') || t.startsWith('/*');
}

/// The widget, setState and direction rules cover app and package code under
/// `lib/` (tests build helper widgets freely).
bool uiRulesApply(String relPath) =>
    relPath.startsWith('lib/') ||
    (relPath.startsWith('packages/') && relPath.contains('/lib/'));

void scanDart(File f) {
  final relPath = rel(f.path);
  // Generated by `flutter gen-l10n`, committed, never edited by hand.
  if (relPath.startsWith('lib/l10n/app_localizations')) return;
  scanDirectives(f, pubspecFor(f));
  final lines = f.readAsLinesSync();
  final ui = uiRulesApply(relPath);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (isCommentOnly(line)) continue;
    final code = line.replaceFirst(RegExp(r'\s//.*$'), '');
    for (final (rule, re, msg) in codegenText) {
      if (re.hasMatch(code)) report(rule, f.path, i + 1, msg);
    }
    if (!ui) continue;
    if (RegExp(r'\bsetState\s*\(').hasMatch(code)) {
      report('set-state', f.path, i + 1, 'setState: state lives in Riverpod');
    }
    final m = widgetMethod.firstMatch(code);
    // `build` and `buildTransitions` are the framework's own overrides; they
    // cannot be extracted.
    if (m != null &&
        m.group(1) != 'build' &&
        m.group(1) != 'buildTransitions' &&
        m.group(1) != 'Function') {
      report(
        'widget-method',
        f.path,
        i + 1,
        'widget-returning "${m.group(1)}": extract a widget class',
      );
    }
  }
  if (ui) {
    final text = lines.where((l) => !isCommentOnly(l)).join('\n');
    for (final (rule, re, msg) in physicalDirection) {
      for (final m in re.allMatches(text)) {
        final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
        report(rule, f.path, line, '${m[0]!.split('(').first}: $msg');
      }
    }
  }
}

void scanDirectives(File f, Pubspec? ps) {
  final lines = f.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final m = directive.firstMatch(lines[i]);
    if (m == null) continue;
    final uri = m.group(1)!;
    if (uri.startsWith('dart:')) continue;
    if (uri.startsWith('package:')) {
      final pkg = uri.substring(8).split('/').first;
      if (bannedPackages.contains(pkg)) {
        report('banned-package', f.path, i + 1, 'import of "$pkg"');
        continue;
      }
      if (ps == null) {
        report(
          'undeclared-package',
          f.path,
          i + 1,
          'package:$pkg imported where no pubspec applies',
        );
      } else if (pkg != ps.name && !ps.deps.contains(pkg)) {
        report(
          'undeclared-package',
          f.path,
          i + 1,
          'package:$pkg is not in ${rel(ps.file.path)}',
        );
      }
    } else if (uri.startsWith('file:') || uri.startsWith('/')) {
      report('path-leaves-project', f.path, i + 1, 'absolute import $uri');
    } else if (uri.contains(':')) {
      continue; // other schemes
    } else if (!insideProject('${f.parent.path}/$uri')) {
      report(
        'path-leaves-project',
        f.path,
        i + 1,
        'relative import "$uri" leaves the project',
      );
    }
  }
}

// ------------------------------------------------------------------- secrets

final List<(String, RegExp)> secretNames = [
  ('.env file', RegExp(r'(^|/)\.env(\..*)?$')),
  ('.p8 key', RegExp(r'\.p8$')),
  ('.pem key', RegExp(r'\.pem$')),
  ('keystore', RegExp(r'\.(jks|keystore)$|(^|/)key\.properties$')),
  ('service account', RegExp(r'adminsdk.*\.json$')),
  (
    'firebase client config',
    RegExp(r'(^|/)(GoogleService-Info\.plist|google-services\.json)$'),
  ),
];

final List<(String, RegExp)> secretContent = [
  ('private key block', RegExp('-----BEGIN [A-Z ]*PRIVATE KEY-----')),
  ('google api key', RegExp(r'AIza[0-9A-Za-z_\-]{35}')),
  ('private_key json field', RegExp(r'"private_key"\s*:\s*"-----')),
  ('aws access key', RegExp(r'AKIA[0-9A-Z]{16}')),
];

/// The files git knows about or would add (tracked, plus untracked and not
/// ignored); every file under [root] when this is not a git repository.
List<String> projectFiles() {
  final r = Process.runSync('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
  ], workingDirectory: root);
  if (r.exitCode == 0) {
    return (r.stdout as String).split('\n').where((s) => s.isNotEmpty).toList();
  }
  return [for (final f in walk(Directory(root), (_) => true)) rel(f.path)];
}

void scanSecrets() {
  for (final p in projectFiles()) {
    if (p.endsWith('.env.example')) continue;
    for (final (label, re) in secretNames) {
      if (re.hasMatch(p))
        report('secret-file', '$root/$p', 0, 'tracked $label');
    }
    final f = File('$root/$p');
    if (!f.existsSync() || f.lengthSync() > 2000000) continue;
    // latin1 never throws, so binaries are scanned too.
    final lines = latin1.decode(f.readAsBytesSync()).split('\n');
    for (var i = 0; i < lines.length; i++) {
      for (final (label, re) in secretContent) {
        if (re.hasMatch(lines[i])) {
          report('secret-content', f.path, i + 1, label); // value not printed
        }
      }
    }
  }
}

void scanLockfile() {
  final f = File('$root/pubspec.lock');
  if (!f.existsSync()) return;
  final lines = f.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    if (RegExp(r'^\s+source:\s*git\s*$').hasMatch(lines[i])) {
      report('git-dependency', f.path, i + 1, 'git source in lockfile');
    }
  }
}

// ---------------------------------------------------------------------- main

void main(List<String> args) => exit(run(args));

/// The folder under `packages/` that [path] belongs to, or null.
String? packageOf(String path) {
  final seg = path.split('/');
  return seg.length > 2 && seg[0] == 'packages' ? seg[1] : null;
}

int run(List<String> args) {
  final rootArg = args.indexOf('--root');
  if (rootArg >= 0) {
    root = normalize(Directory(args[rootArg + 1]).absolute.path);
  } else {
    // tool/ -> project root
    final script = File.fromUri(Platform.script).absolute;
    root = normalize(script.parent.parent.path);
  }
  final exemptArg = args.indexOf('--exempt');
  final exempt = {
    ...exemptPackages,
    if (exemptArg >= 0)
      ...args[exemptArg + 1].split(',').where((s) => s.isNotEmpty),
  };

  final dirs = [
    for (final d in ['lib', 'test', 'packages'])
      if (Directory('$root/$d').existsSync()) Directory('$root/$d'),
  ];
  final pubs = [
    if (File('$root/pubspec.yaml').existsSync()) File('$root/pubspec.yaml'),
    for (final d in dirs.where((d) => d.path.endsWith('/packages')))
      ...walk(d, (n) => n == 'pubspec.yaml'),
  ];
  for (final p in pubs) {
    pubspecs[p.parent.path] = parsePubspec(p);
  }
  scanLockfile();
  for (final d in dirs) {
    for (final f in walk(d, (n) => n.endsWith('.dart'))) {
      scanDart(f);
    }
  }
  scanSecrets();

  violations.sort(
    (a, b) => '${a.path}:${a.line}'.compareTo('${b.path}:${b.line}'),
  );
  final enforced = <Violation>[];
  final exempted = <String, int>{for (final name in exempt) name: 0};
  for (final v in violations) {
    final pkg = packageOf(v.path);
    if (pkg != null && exempt.contains(pkg)) {
      exempted[pkg] = exempted[pkg]! + 1;
      stdout.writeln('exempt $v');
    } else {
      enforced.add(v);
      stdout.writeln(v);
    }
  }
  for (final e in exempted.entries) {
    stdout.writeln(
      'exempt-package: packages/${e.key} is exempt (copied kit): '
      '${e.value} violation(s) listed above are not enforced',
    );
  }
  stdout.writeln(
    enforced.isEmpty
        ? 'check_architecture: OK (${pubspecs.length} pubspecs'
            '${exempted.isEmpty ? '' : ', ${exempted.length} exempt package(s)'})'
        : 'check_architecture: FAILED with ${enforced.length} violation(s)',
  );
  return enforced.isEmpty ? 0 : 1;
}
