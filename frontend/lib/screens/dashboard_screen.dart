import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const Color slateColor = Color(0xFF94A3B8);

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return 0;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = 'monthly';
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getDashboardAnalytics(_selectedPeriod);
    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              final headerContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Church Growth Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Attendance, Membership & Financial Intelligence',
                    style: TextStyle(color: slateColor, fontSize: 12),
                  ),
                ],
              );

              final periodSelector = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _periodChip('weekly', 'Weekly'),
                      _periodChip('monthly', 'Monthly'),
                      _periodChip('quarterly', 'Quarterly'),
                      _periodChip('yearly', 'Yearly'),
                    ],
                  ),
                ),
              );

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: headerContent),
                    periodSelector,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerContent,
                    const SizedBox(height: 14),
                    periodSelector,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_analyticsData == null)
            const Center(child: Text('Failed to load dashboard data'))
          else ...[
            _buildInsightBanner(),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final sundayAtt = _analyticsData!['sundayAttendance'] ?? {};
                final membership = _analyticsData!['membership'] ?? {};
                final financials = _analyticsData!['financials'];

                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  childAspectRatio: isWide ? 1.4 : 1.15,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _kpiCard(
                      title: 'Avg Sunday',
                      value: '${_toInt(sundayAtt['currentAverage'])}',
                      growth: _toDouble(sundayAtt['growthPercentage']),
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                    _kpiCard(
                      title: 'Active Members',
                      value: '${_toInt(membership['active'])}',
                      subtitle: '${_toInt(membership['total'])} Registered',
                      icon: Icons.person_add_alt_1_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _kpiCard(
                      title: 'New Converts',
                      value: '${_toInt(membership['newConverts']) + _toInt(membership['firstTimers'])}',
                      subtitle: 'This period',
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    if (financials != null)
                      _kpiCard(
                        title: 'Total Offerings',
                        value: currencyFmt.format(_toDouble(financials['currentTotal'])),
                        growth: _toDouble(financials['growthPercentage']),
                        icon: Icons.payments_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _attendanceChartCard()),
                          const SizedBox(width: 16),
                          if (_analyticsData!['financials'] != null)
                            Expanded(child: _financialBreakdownCard()),
                        ],
                      )
                    : Column(
                        children: [
                          _attendanceChartCard(),
                          const SizedBox(height: 16),
                          if (_analyticsData!['financials'] != null)
                            _financialBreakdownCard(),
                        ],
                      );
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _periodChip(String id, String label) {
    final isSelected = _selectedPeriod == id;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _selectedPeriod = id);
          _loadAnalytics();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : slateColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightBanner() {
    final sundayAtt = _analyticsData!['sundayAttendance'] ?? {};
    final sundayGrowth = _toDouble(sundayAtt['growthPercentage']);
    final isPositive = sundayGrowth >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFF991B1B), const Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? 'Growth Momentum: UP +$sundayGrowth%' : 'Attendance Alert: $sundayGrowth%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Average Sunday attendance is at ${_toInt(sundayAtt['currentAverage'])} vs ${_toInt(sundayAtt['previousAverage'])} prior period.',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    num? growth,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: slateColor, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          if (growth != null)
            Row(
              children: [
                Icon(
                  growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: growth >= 0 ? Colors.greenAccent : Colors.redAccent,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${growth.abs()}% vs prior',
                    style: TextStyle(
                      fontSize: 10,
                      color: growth >= 0 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(color: slateColor, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _attendanceChartCard() {
    final List<dynamic> trends = _analyticsData!['attendanceTrends'] ?? [];

    List<FlSpot> spots = [];
    double maxY = 10.0;
    for (int i = 0; i < trends.length; i++) {
      final val = _toDouble(trends[i]['total_attendance']);
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance History Trend',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text('Headcount recorded per service event', style: TextStyle(color: slateColor, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                maxY: maxY * 1.1,
                minY: 0,
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10)),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < trends.length && idx % 3 == 0) {
                          final dateStr = trends[idx]['event_date'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(dateStr.length >= 5 ? dateStr.substring(5) : dateStr, style: const TextStyle(color: slateColor, fontSize: 9)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialBreakdownCard() {
    final financials = _analyticsData!['financials'] ?? {};
    final List<dynamic> breakdown = financials['offeringBreakdown'] ?? [];
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Offering Categories',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text('Distribution by collection type', style: TextStyle(color: slateColor, fontSize: 11)),
          const SizedBox(height: 16),
          if (breakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No offerings recorded for this period', style: TextStyle(color: slateColor, fontSize: 12)),
            )
          else
            ...breakdown.map((item) {
              final type = item['offering_type'] ?? 'OTHER';
              final amount = _toDouble(item['total_amount']);
              final label = type.toString().replaceAll('_', ' ');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFmt.format(amount),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
