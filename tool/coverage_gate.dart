// Fails when line coverage in coverage/lcov.info is below a minimum.
//
//   flutter test --coverage
//   dart run tool/coverage_gate.dart 60
//
// Generated files (*.g.dart) are left out of the count. Raise the minimum as
// coverage grows; never lower it to make a change pass.
import 'dart:io';

void main(List<String> args) {
  final minimum = double.parse(args.isEmpty ? '0' : args.first);
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('coverage/lcov.info not found; run flutter test --coverage');
    exit(2);
  }

  var found = 0;
  var hit = 0;
  var skip = false;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      skip = line.endsWith('.g.dart');
    } else if (!skip && line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (!skip && line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  final percent = found == 0 ? 0 : hit * 100 / found;
  stdout.writeln(
      'Line coverage: ${percent.toStringAsFixed(1)}% ($hit of $found lines)');
  if (percent < minimum) {
    stderr.writeln('Below the minimum of $minimum%.');
    exit(1);
  }
}
