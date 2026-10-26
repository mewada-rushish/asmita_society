import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:asmita_society/core/network/config_version_interceptor.dart';

void main() {
  group('ConfigVersionInterceptor (Stale Client Protocol [R6])', () {
    late Dio dio;
    late ConfigVersionInterceptor interceptor;
    int refreshCallCount = 0;

    setUp(() {
      dio = Dio();
      refreshCallCount = 0;
      interceptor = ConfigVersionInterceptor(
        dio: dio,
        initialConfigVersion: '1',
        onRefreshConfig: () async {
          refreshCallCount++;
          return '2'; // bumped config version
        },
      );
      dio.interceptors.add(interceptor);
    });

    test('attaches current x-config-version header to outgoing requests', () async {
      final options = RequestOptions(path: '/test');
      interceptor.onRequest(options, RequestInterceptorHandler());
      expect(options.headers['x-config-version'], '1');
    });

    test('updates config version via updateConfigVersion', () {
      interceptor.updateConfigVersion('5');
      expect(interceptor.currentConfigVersion, '5');

      final options = RequestOptions(path: '/test2');
      interceptor.onRequest(options, RequestInterceptorHandler());
      expect(options.headers['x-config-version'], '5');
    });

    test('HTTP 426 triggers configuration refresh and retries once with new version', () async {
      final clientDio = Dio();
      int callCount = 0;

      // Mock HTTP adapter
      clientDio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        callCount++;
        final version = options.headers['x-config-version'];
        if (version == '1') {
          // Stale version: return 426 Upgrade Required
          return ResponseBody.fromString(
            '{"success":false,"message":"Client configuration stale"}',
            426,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else {
          // Updated version: return 200 OK
          return ResponseBody.fromString(
            '{"success":true,"message":"Processed with updated config"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
      });

      final testInterceptor = ConfigVersionInterceptor(
        dio: clientDio,
        initialConfigVersion: '1',
        onRefreshConfig: () async {
          refreshCallCount++;
          return '2';
        },
      );
      clientDio.interceptors.add(testInterceptor);

      final response = await clientDio.post('/app-api/industrial/visits/1/action', data: {'action': 'APPROVE'});

      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(refreshCallCount, 1);
      expect(callCount, 2); // Initial request (426) + 1 automatic retry (200)
      expect(testInterceptor.currentConfigVersion, '2');
    });

    test('falls back to standard error state if retried request is still rejected with 426', () async {
      final clientDio = Dio();
      int callCount = 0;

      // Always returns 426
      clientDio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        callCount++;
        return ResponseBody.fromString(
          '{"success":false,"message":"Client configuration rejected permanently"}',
          426,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final testInterceptor = ConfigVersionInterceptor(
        dio: clientDio,
        initialConfigVersion: '1',
        onRefreshConfig: () async {
          refreshCallCount++;
          return '2';
        },
      );
      clientDio.interceptors.add(testInterceptor);

      bool threw = false;
      try {
        await clientDio.post('/app-api/industrial/visits/1/action', data: {'action': 'APPROVE'});
      } on DioException catch (e) {
        threw = true;
        expect(e.response?.statusCode, 426);
      }

      expect(threw, true);
      expect(refreshCallCount, 1);
      expect(callCount, 2);
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
