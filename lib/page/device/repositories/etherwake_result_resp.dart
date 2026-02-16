class EtherwakeResultResp {
  final int code;
  final String? stdout;
  final String stderr;

  EtherwakeResultResp({
    required this.code,
    required this.stdout,
    required this.stderr,
  });

  factory EtherwakeResultResp.fromJson(Map<String, dynamic> json) => EtherwakeResultResp(
    code: json['code'],
    stdout: json.containsKey('stdout') ? json['stdout'] : null,
    stderr: json['stderr'],
  );
}