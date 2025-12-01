import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class JsonRpcResponse<T> {
  final T? result;
  final JsonRpcError? error;
  final int? id;

  JsonRpcResponse({this.result, this.error, this.id});

  bool get success =>
      error == null &&
      (result == null ||
          (result != null && ((result as List).first) as int == 0));

  @override
  String toString() {
    if (success) {
      return 'JsonRpcResponse(success: true, result: $result, id: $id)';
    } else {
      return 'JsonRpcResponse(success: false, error: $error, id: $id)';
    }
  }
}

class BatchResponse<T> {
  final List<JsonRpcResponse<T>> responses;

  BatchResponse(this.responses);

  bool get allSuccess => responses.every((r) => r.success);

  List<T?> get results => responses.map((r) => r.result).toList();

  List<JsonRpcError?> get errors => responses.map((r) => r.error).toList();

  bool get allAccessDenied =>
      responses.every((r) => r.error?.isAccessDenied ?? false);
}

class JsonRpcError {
  final int code;
  final String message;
  final dynamic data;

  get isAccessDenied => code == -32002;

  JsonRpcError({required this.code, required this.message, this.data});

  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'],
      message: json['message'],
      data: json['data'],
    );
  }

  @override
  String toString() =>
      'JsonRpcError(code: $code, message: "$message", data: $data)';
}

class JsonRpcException implements Exception {
  final String message;
  final dynamic cause;

  JsonRpcException(this.message, {this.cause});

  @override
  String toString() =>
      'JsonRpcException: $message${cause != null ? ', cause: $cause' : ''}';
}

class CallItem<T> {
  final String method;
  final dynamic params;
  final int id;

  CallItem({required this.method, this.params, required this.id});
}

class JsonRpcClient {
  final String _url;
  final Dio _dio;
  int _requestId = 1; // 请求ID计数器
  JsonRpcClient(this._url, {Dio? dio}) : _dio = dio ?? Dio() {
    // 添加日志拦截器
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        logPrint: (obj) {
          if (kDebugMode) {
            print(obj);
          }
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<JsonRpcResponse<T>> call<T>(String method, [dynamic params]) async {
    final id = _getNextId();
    final request = _createRequest(method, params, id);

    try {
      final response = await _dio.post(
        _url,
        options: Options(contentType: 'application/json'),
        data: request,
      );

      // 检查 HTTP 状态码
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw JsonRpcException(
          'HTTP Error: ${response.statusCode}',
          cause: response.statusMessage,
        );
      }

      return _parseResponse<T>(response.data, id);
    } on DioException catch (e) {
      throw JsonRpcException('Network or HTTP request failed', cause: e);
    } catch (e) {
      throw JsonRpcException('Unexpected error during request', cause: e);
    }
  }

  Future<BatchResponse<T>> batchCall<T>(List<CallItem<T>> calls) async {
    if (calls.isEmpty) {
      throw ArgumentError('Batch call cannot be empty');
    }

    // 构建批量请求的 JSON 数组
    final requests = calls.map((item) {
      return <String, dynamic>{
        'jsonrpc': '2.0',
        'method': item.method,
        'params': item.params,
        'id': item.id,
      };
    }).toList();

    try {
      final response = await _dio.post(
        _url,
        data: requests, // 直接发送数组
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw JsonRpcException(
          'HTTP Error in batch: ${response.statusCode}',
          cause: response.statusMessage,
        );
      }

      // 解析批量响应
      return _parseBatchResponse<T>(response.data, calls.length);
    } on DioException catch (e) {
      throw JsonRpcException('Network error during batch call', cause: e);
    } catch (e) {
      throw JsonRpcException('Unexpected error during batch call', cause: e);
    }
  }

  Future<void> notify(String method, [dynamic params]) async {
    final request = _createRequest(method, params, null); // 通知没有 ID

    try {
      await _dio.post(
        _url,
        options: Options(contentType: 'application/json'),
        data: request,
      );
    } catch (_) {}
  }

  void close() {
    _dio.close();
  }

  int _getNextId() => _requestId++;

  Map<String, dynamic> _createRequest(String method, dynamic params, int? id) {
    final request = <String, dynamic>{'jsonrpc': '2.0', 'method': method};
    if (params != null) {
      request['params'] = params;
    }
    if (id != null) {
      request['id'] = id;
    }
    return request;
  }

  JsonRpcResponse<T> _parseResponse<T>(dynamic jsonResponse, int expectedId) {
    try {
      if (jsonResponse is! Map || jsonResponse['jsonrpc'] != '2.0') {
        throw JsonRpcException(
          'Invalid JSON-RPC response format',
          cause: jsonResponse,
        );
      }

      final id = jsonResponse['id'];
      if (id != expectedId) {
        throw JsonRpcException(
          'Response ID mismatch',
          cause: 'Expected: $expectedId, Received: $id',
        );
      }

      if (jsonResponse.containsKey('error')) {
        final error = JsonRpcError.fromJson(jsonResponse['error']);
        return JsonRpcResponse<T>(error: error, id: id);
      } else {
        final result = jsonResponse['result'] as T?;
        return JsonRpcResponse<T>(result: result, id: id);
      }
    } on TypeError catch (e) {
      throw JsonRpcException('Type conversion error in response', cause: e);
    } catch (e) {
      throw JsonRpcException('Failed to parse response', cause: e);
    }
  }

  BatchResponse<T> _parseBatchResponse<T>(
    dynamic jsonResponse,
    int expectedCount,
  ) {
    if (jsonResponse is! List) {
      throw JsonRpcException(
        'Batch response must be a JSON array',
        cause: jsonResponse,
      );
    }

    if (jsonResponse.length != expectedCount) {
      throw JsonRpcException(
        'Batch response count mismatch',
        cause: 'Expected $expectedCount, got ${jsonResponse.length}',
      );
    }

    final responses = <JsonRpcResponse<T>>[];
    for (var i = 0; i < jsonResponse.length; i++) {
      final jsonItem = jsonResponse[i];
      final expectedId = (i + 1); // 假设 ID 是顺序的 1, 2, 3...
      // 实际项目中，最好从原始请求中获取确切的 ID
      try {
        final response = _parseResponseFromJsonForBatch<T>(
          jsonItem,
          expectedId,
        );
        responses.add(response);
      } on JsonRpcException {
        rethrow;
      } catch (e) {
        responses.add(
          JsonRpcResponse<T>(
            error: JsonRpcError(
              code: -32000,
              message: 'Internal parsing error',
              data: e.toString(),
            ),
            id: expectedId,
          ),
        );
      }
    }

    return BatchResponse<T>(responses);
  }

  JsonRpcResponse<T> _parseResponseFromJsonForBatch<T>(
    dynamic json,
    int expectedId,
  ) {
    if (json is! Map || json['jsonrpc'] != '2.0') {
      throw JsonRpcException('Invalid JSON-RPC response in batch', cause: json);
    }

    final id = json['id'];
    if (id == null) {
      throw JsonRpcException('Response in batch must have an ID', cause: json);
    }

    if (json.containsKey('error')) {
      final error = JsonRpcError.fromJson(json['error']);
      return JsonRpcResponse<T>(error: error, id: id);
    } else {
      final result = json['result'] as T?;
      return JsonRpcResponse<T>(result: result, id: id);
    }
  }
}
