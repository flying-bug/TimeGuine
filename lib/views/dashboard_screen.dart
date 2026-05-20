import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/task_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final viewModel = context.read<TaskViewModel>();
    final stats = await viewModel.getWeeklyStats();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F8FF),
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final int total = _stats!['total'];
    final int completed = _stats!['completed'];
    final List<double> completedPerDay = _stats!['completedPerDay'];
    final List<double> totalPerDay = _stats!['totalPerDay'];

    // Tính tỷ lệ % hoàn thành
    final double completionRate = total > 0 ? (completed / total) * 100 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text('Bảng Điểm Của Bé', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ Tổng Quan (Pie Chart)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Tiến Độ Tuần Này', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 50,
                        sections: _getPieSections(completed, total - completed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    total == 0 
                        ? 'Tuần này bé chưa có nhiệm vụ nào cả!' 
                        : 'Bé đã hoàn thành ${completionRate.toStringAsFixed(0)}% mục tiêu!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Biểu đồ Cột (Bar Chart)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Thành Tích Mỗi Ngày', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(totalPerDay),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: _getBottomTitles,
                              reservedSize: 38,
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: _getBarGroups(completedPerDay, totalPerDay),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers cho Biểu Đồ ---

  List<PieChartSectionData> _getPieSections(int completed, int notCompleted) {
    if (completed == 0 && notCompleted == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: '0%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
        )
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.greenAccent,
        value: completed.toDouble(),
        title: '$completed\nXong',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.redAccent.withOpacity(0.7),
        value: notCompleted.toDouble(),
        title: '$notCompleted\nChưa',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    ];
  }

  double _getMaxY(List<double> totalPerDay) {
    double max = 0;
    for (var val in totalPerDay) {
      if (val > max) max = val;
    }
    return max == 0 ? 5 : max + 1; // Mặc định là 5 nếu chưa có dữ liệu
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w900, fontSize: 13);
    
    // Tính ngày lùi lại dựa theo index (0 là 6 ngày trước, 6 là hôm nay)
    final now = DateTime.now();
    final day = now.subtract(Duration(days: 6 - value.toInt()));
    
    String text = DateFormat('dd/MM').format(day);
    if (value.toInt() == 6) text = "Hôm nay";

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(text, style: style),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<double> completed, List<double> total) {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < 7; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total[i], // Cột xám mờ hiện tổng task
              color: Colors.grey[200],
              width: 20,
              borderRadius: BorderRadius.circular(10),
              backDrawRodData: BackgroundBarChartRodData(show: false),
            ),
            BarChartRodData(
              toY: completed[i], // Cột màu xanh/hồng đè lên hiện số đã làm
              color: completed[i] == total[i] && total[i] > 0 ? Colors.greenAccent : Colors.pinkAccent,
              width: 20,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
          showingTooltipIndicators: [],
        ),
      );
    }
    return groups;
  }
}
