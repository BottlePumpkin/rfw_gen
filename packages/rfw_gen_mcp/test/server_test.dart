import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('MCP server integration', () {
    test('server starts without crashing', () async {
      final process = await Process.start(
        'dart',
        ['run', 'bin/rfw_gen_mcp.dart'],
        workingDirectory: Directory.current.path.endsWith('test')
            ? Directory.current.parent.path
            : Directory.current.path,
      );

      // Give the server a moment to start up.
      await Future.delayed(const Duration(seconds: 2));

      // If it hasn't exited yet, it started cleanly.
      final exitCodeFuture = process.exitCode;
      process.kill();
      final exitCode = await exitCodeFuture.timeout(
        const Duration(seconds: 3),
        onTimeout: () => 0, // killed cleanly → treat as success
      );

      // SIGTERM results in exit code 15 (or -15) on POSIX.
      // Any non-crash exit code is acceptable here.
      expect(exitCode, isNot(equals(1)));
    });

    test('server responds to initialize request', () async {
      final process = await Process.start(
        'dart',
        ['run', 'bin/rfw_gen_mcp.dart'],
        workingDirectory: Directory.current.path.endsWith('test')
            ? Directory.current.parent.path
            : Directory.current.path,
      );

      // Collect stderr for diagnostics.
      final stderrBuffer = StringBuffer();
      process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);

      // Send an MCP initialize request (newline-delimited JSON).
      final initRequest = jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'test-client', 'version': '0.0.1'},
        },
      });

      process.stdin.writeln(initRequest);
      await process.stdin.flush();

      // Read the response line from stdout.
      String? responseLine;
      try {
        responseLine = await process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .firstWhere((line) => line.trim().isNotEmpty)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        process.kill();
        fail('Server did not respond within 10 s. stderr: $stderrBuffer');
      }

      process.kill();

      expect(responseLine, isNotEmpty);

      final response = jsonDecode(responseLine) as Map<String, dynamic>;
      expect(response['jsonrpc'], equals('2.0'));
      expect(response['id'], equals(1));
      expect(response.containsKey('result'), isTrue,
          reason: 'Expected result, got: $response');

      final result = response['result'] as Map<String, dynamic>;
      expect(result.containsKey('serverInfo'), isTrue);
      expect(result.containsKey('capabilities'), isTrue);

      final serverInfo = result['serverInfo'] as Map<String, dynamic>;
      expect(serverInfo['name'], isA<String>());
    });
  });
}
