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
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(totalPerDay),
                        barTouchData: BarTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.orangeAccent,
                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final dayIndex = group.x;
                              final comp = completedPerDay[dayIndex].toInt();
                              final tot = totalPerDay[dayIndex].toInt();
                              return BarTooltipItem(
                                '$comp/$tot Xong',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.greenAccent, 'Xong hết'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.pinkAccent, 'Chưa xong hết'),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.grey.shade200, 'Tổng số việc'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Chi tiết từng ngày
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chi Tiết Nhiệm Vụ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 7,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final dayIndex = index;
                      final now = DateTime.now();
                      final day = now.add(Duration(days: dayIndex));
                      final comp = completedPerDay[dayIndex].toInt();
                      final tot = totalPerDay[dayIndex].toInt();
                      
                      String dayStr = DateFormat('dd/MM').format(day);
                      if (dayIndex == 0) {
                        dayStr = "Hôm nay\n($dayStr)";
                      } else if (dayIndex == 1) {
                        dayStr = "Ngày mai\n($dayStr)";
                      } else {
                        dayStr = "${_getVNWeekday(day.weekday)}\n($dayStr)";
                      }

                      final double rate = tot > 0 ? (comp / tot) : 0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Icon(
                              tot == 0 
                                ? Icons.calendar_today_rounded 
                                : (comp == tot ? Icons.check_circle_rounded : Icons.pending_rounded),
                              color: tot == 0 
                                ? Colors.grey 
                                : (comp == tot ? Colors.greenAccent : Colors.orangeAccent),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayStr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: dayIndex == 0 ? Colors.orange : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tot == 0 
                                        ? 'Không có nhiệm vụ' 
                                        : 'Hoàn thành $comp trên $tot nhiệm vụ',
                                    style: TextStyle(
                                      color: tot == 0 ? Colors.grey : Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (tot > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: comp == tot ? Colors.green.shade50 : Colors.pink.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(rate * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: comp == tot ? Colors.green : Colors.pinkAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      ],
    );
  }

  String _getVNWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

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
    final isToday = value.toInt() == 0;
    final style = TextStyle(
      color: isToday ? Colors.orange : Colors.blueGrey,
      fontWeight: FontWeight.w900,
      fontSize: 12,
    );
    
    // Tính ngày tiến lên trong tương lai dựa theo index (0 là hôm nay, 6 là 6 ngày sau)
    final now = DateTime.now();
    final day = now.add(Duration(days: value.toInt()));
    
    final text = DateFormat('dd/MM').format(day);

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
              toY: completed[i],
              color: completed[i] == total[i] && total[i] > 0 ? Colors.greenAccent : Colors.pinkAccent,
              width: 20,
              borderRadius: BorderRadius.circular(10),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: total[i] == 0 ? 0.05 : total[i],
                color: Colors.grey[200],
              ),
            ),
          ],
          showingTooltipIndicators: [],
        ),
      );
    }
    return groups;
  }
}
