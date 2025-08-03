import 'package:args/args.dart';

import 'compiler.dart';

Future<void> main(List<String> arguments) async {
  // TODO: Add exception handling
  // TODO: Add support for multiple module search paths

  final parser = ArgParser();
  
  parser.addOption('module-path',
      abbr: 'm',
      help: 'The path in which to search for modules.'
  );

  parser.addOption('output',
      abbr: 'o',
      help: 'Name of the output file to generate.',
      mandatory: true
  );

  final args = parser.parse(arguments);

  final modulePath = args.option('module-path')!;
  final outPath = args.option('output')!;

  final sources = args.rest;

  // TODO: Add support for multiple sources

  final compiler = Compiler(
    modulePath: modulePath
  );

  await compiler.compile(
      source: sources[0],
      output: outPath
  );
}
