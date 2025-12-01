import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/device_status_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/network_chart_resp.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/utils/utils.dart';
import 'device_status_provider.dart';

class DeviceStatusPage extends HookConsumerWidget {
  final Device device;

  const DeviceStatusPage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Timer? timer;
      void startPolling() {
        timer = Timer.periodic(const Duration(seconds: 3), (tick) {
          ref.read(statsProvider(device).notifier).getStatus();
          ref.read(chartProvider(device).notifier).getNetworkChartData();
        });
      }

      startPolling();
      return () {
        timer?.cancel();
      };
    }, [device]);

    final stats = ref.watch(statsProvider(device));
    final chartData = ref.watch(chartProvider(device));
    return Scaffold(
      body: stats == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  networkChartView(ref, chartData),
                  systemCpuInfoView(stats),
                  networkInfoView(stats),
                  diskInfoView(stats),
                  systemStatusView(stats),
                  SizedBox(
                    height: 16,
                  )
                ],
              ),
            ),
    );
  }

  systemStatusView(DeviceStatusResp stats) {
    var titles = ["主机名", "型号", "架构", "目标平台", "内核版本", "温度", "本地时间", "运行时间"];

    var values = [
      stats.hostname,
      stats.model,
      stats.system,
      stats.target,
      stats.kernel,
      stats.tempInfo,
      timeFormat.format(
        DateTime.fromMillisecondsSinceEpoch(stats.localtime * 1000).toUtc(),
      ),
      intToUsefulTime(stats.uptime),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: titles.length,
          itemBuilder: (context, i) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(titles[i])),
              Expanded(child: Text(values[i].toString())),
            ],
          ),
          separatorBuilder: (context, i) => SizedBox(height: 8),
        ),
      ),
    );
  }

  systemCpuInfoView(DeviceStatusResp stats) {
    var titles = ["CPU占用", "内存占用", "内存缓存", "连接数"];
    var icons = [
      Icons.memory_outlined,
      Icons.sd_storage_outlined,
      Icons.cached,
      Icons.link,
    ];
    var values = [
      [stats.cpuUsage.toInt(), "平均负载：${stats.cpuLoad}"],
      [stats.memoryUsage, stats.memoryDetail],
      [stats.memoryCachePercent, stats.memoryCacheDetail],
      [stats.connectionsPercent, stats.connectionsDetail],
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      padding: const EdgeInsets.symmetric(vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, i) => Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    titles[i],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Icon(icons[i]),
                ],
              ),
              Expanded(child: FittedBox(child: Text("${values[i][0]}%"))),
              Text(values[i][1].toString(), style: TextStyle(fontSize: 10)),
              SizedBox(height: 4),
              LinearProgressIndicator(value: (values[i][0] as int) / 100),
            ],
          ),
        ),
      ),
    );
  }

  networkInfoView(DeviceStatusResp stats) {
    var titles = ["WAN口IP", "LAN口IP", "网关", "DNS"];
    var values = [
      stats.wanIp,
      stats.lanIp,
      stats.gateway,
      stats.dns.isNotEmpty ? stats.dns.join("\n") : "--",
    ];
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "网络状态",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: titles.length,
              itemBuilder: (context, i) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(titles[i])),
                  Expanded(child: Text(values[i], textAlign: TextAlign.right)),
                ],
              ),
              separatorBuilder: (BuildContext context, int index) =>
                  SizedBox(height: 8),
            ),
          ],
        ),
      ),
    );
  }

  diskInfoView(DeviceStatusResp stats) {
    if (stats.disks.isEmpty) {
      return SizedBox();
    }
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "磁盘状态",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: stats.disks.length,
                itemBuilder: (context, i) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.disks[i].mount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(stats.disks[i].device, style: TextStyle(fontSize: 13)),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${stats.disks[i].usagePercent}%"),
                        LinearProgressIndicator(
                          value: stats.disks[i].usagePercent / 100,
                        ),
                        Text("${stats.disks[i].used}/${stats.disks[i].total}"),
                      ],
                    ),
                  ],
                ),
                separatorBuilder: (_, __) => SizedBox(height: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  networkChartView(WidgetRef ref, List<List<NetworkChartResp>> chartData) {
    if (chartData.isEmpty || chartData.length < 2) {
      return Opacity(opacity: 0);
    }

    buildLineChartData(
      List<NetworkChartResp> chartData,
      List<Color> gradientColors,
    ) {
      if (chartData.isEmpty) {
        return LineChartBarData(
          spots: [],
          isCurved: false,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );
      }

      if (chartData.length == 1) {
        return LineChartBarData(
          spots: [
            FlSpot(0, chartData.first.rate.toDouble()),
            FlSpot(1, chartData.first.rate.toDouble())
          ],
          isCurved: false,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );
      }

      return LineChartBarData(
        spots: chartData
            .map((e) => FlSpot(e.time.toDouble(), e.rate.toDouble()))
            .toList(),
        isCurved: false,
        gradient: LinearGradient(colors: gradientColors),
        barWidth: 2,
        isStrokeCapRound: false,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: gradientColors
                .map((color) => color.withValues(alpha: 0.3))
                .toList(),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // todo 切换接口
                Icon(Icons.arrow_downward, size: 18, color: Colors.blue.shade700),
                SizedBox(width: 4),
                Text(formatSpeed(chartData[1].last.rate.toDouble())),
                SizedBox(width: 32),
                Icon(
                  Icons.arrow_upward,
                  size: 18,
                  color: Colors.green.shade700,
                ),
                SizedBox(width: 4),
                Text(formatSpeed(chartData[0].last.rate.toDouble())),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: false),
                lineBarsData: [
                  buildLineChartData(chartData[0], [
                    Colors.green.shade700,
                    Colors.green.shade400,
                  ]),
                  buildLineChartData(chartData[1], [
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
