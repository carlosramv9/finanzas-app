import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import 'access_token_provider.dart';

/// Cliente HTTP mínimo para Neon Data API (sintaxis PostgREST).
///
/// Todas las lecturas se resuelven en UNA petición: filtros, orden, paginación
/// y agregados (vía RPC) viajan al servidor; nunca se itera una lista para
/// pedir detalles fila por fila (evita N+1).
class DataApiClient {
  DataApiClient({required String baseUrl, required AccessTokenProvider tokens})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            listFormat: ListFormat.multi,
            headers: {'Accept': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(_AuthInterceptor(_dio, tokens));
  }

  final Dio _dio;

  /// GET /{tabla}?select=...&filtros
  Future<List<Map<String, dynamic>>> select(
    String table, {
    required Map<String, Object> query,
  }) =>
      _run(() async {
        final res = await _dio.get<List<dynamic>>('/$table', queryParameters: query);
        return _rows(res.data);
      });

  /// GET con `Accept: text/csv` (PostgREST serializa en el servidor).
  Future<String> selectCsv(String table, {required Map<String, Object> query}) =>
      _run(() async {
        final res = await _dio.get<String>(
          '/$table',
          queryParameters: query,
          options: Options(
            headers: {'Accept': 'text/csv'},
            responseType: ResponseType.plain,
          ),
        );
        return res.data ?? '';
      });

  /// POST /{tabla} — devuelve la fila creada.
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, Object?> body, {
    String select = '*',
  }) =>
      _run(() async {
        final res = await _dio.post<List<dynamic>>(
          '/$table',
          data: body,
          queryParameters: {'select': select},
          options: Options(headers: {'Prefer': 'return=representation'}),
        );
        return _rows(res.data).first;
      });

  /// PATCH /{tabla}?filtros — devuelve la fila actualizada.
  Future<Map<String, dynamic>> update(
    String table, {
    required Map<String, Object> filters,
    required Map<String, Object?> body,
    String select = '*',
  }) =>
      _run(() async {
        final res = await _dio.patch<List<dynamic>>(
          '/$table',
          data: body,
          queryParameters: {...filters, 'select': select},
          options: Options(headers: {'Prefer': 'return=representation'}),
        );
        final rows = _rows(res.data);
        if (rows.isEmpty) {
          throw const AppFailure('No se encontró el registro o no tienes permiso.');
        }
        return rows.first;
      });

  /// POST /rpc/{funcion} — agregados calculados en Postgres.
  Future<T> rpc<T>(String function, Map<String, Object?> params) =>
      _run(() async {
        final res = await _dio.post<T>('/rpc/$function', data: params);
        return res.data as T;
      });

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  static List<Map<String, dynamic>> _rows(List<dynamic>? data) =>
      (data ?? const []).cast<Map<String, dynamic>>();
}

/// Adjunta el JWT y, ante un 401, refresca una sola vez y reintenta.
class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._dio, this._tokens);

  final Dio _dio;
  final AccessTokenProvider _tokens;
  static const _retried = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.accessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final opts = err.requestOptions;
    if (err.response?.statusCode != 401 || opts.extra[_retried] == true) {
      if (err.response?.statusCode == 401) await _tokens.onUnauthorized();
      return handler.next(err);
    }
    try {
      final token = await _tokens.accessToken(forceRefresh: true);
      if (token == null) {
        await _tokens.onUnauthorized();
        return handler.next(err);
      }
      opts
        ..headers['Authorization'] = 'Bearer $token'
        ..extra[_retried] = true;
      handler.resolve(await _dio.fetch<dynamic>(opts));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
