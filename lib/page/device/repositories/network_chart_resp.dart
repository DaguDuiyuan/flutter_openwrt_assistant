class NetworkChartResp {
  final int time;
  final int rate;

  NetworkChartResp({required this.time, required this.rate});
}

List<List<NetworkChartResp>> convertToNetworkChartResp(List rawData) {
  if (rawData.length < 2) return [[], []];

  List<NetworkChartResp> rxList = [];
  List<NetworkChartResp> txList = [];

  for (int i = 1; i < rawData.length; i++) {
    final current = rawData[i];
    final previous = rawData[i - 1];

    final int timeCurr = current[0];
    final int timePrev = previous[0];
    final int timeDelta = timeCurr - timePrev;

    if (timeDelta <= 0) continue;

    final int rxBytesCurr = current[1];
    final int rxBytesPrev = previous[1];
    final int rxRate = (rxBytesCurr - rxBytesPrev) ~/ timeDelta;

    final int txBytesCurr = current[3];
    final int txBytesPrev = previous[3];
    final int txRate = (txBytesCurr - txBytesPrev) ~/ timeDelta;

    rxList.add(NetworkChartResp(time: timeCurr, rate: rxRate));
    txList.add(NetworkChartResp(time: timeCurr, rate: txRate));
  }

  // 从后往前抛弃大于120秒之前的所有数据
  while (rxList.isNotEmpty &&
      rxList.length > 2 &&
      rxList.last.time - rxList.first.time > 120) {
    rxList.removeAt(0);
  }

  while (txList.isNotEmpty &&
      txList.length > 2 &&
      txList.last.time - txList.first.time > 120) {
    txList.removeAt(0);
  }

  return [rxList, txList];
}
