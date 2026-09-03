import 'package:flutter/material.dart';
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

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'quarterly';
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getDashboardAnalytics(_selectedPeriod);
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Top Header
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                final headerText = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Executive Church Reports',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Automated Quarterly & Annual Summary Reviews',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );

                final periodDropdown = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: 'quarterly', child: Text('Q3 2026 Review')),
                        DropdownMenuItem(value: 'yearly', child: Text('Annual 2026 Review')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPeriod = val);
                          _loadReport();
                        }
                      },
                    ),
                  ),
                );

                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: headerText),
                      const SizedBox(width: 12),
                      periodDropdown,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerText,
                      const SizedBox(height: 10),
                      periodDropdown,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_data == null)
              const Expanded(child: Center(child: Text('Unable to compile report', style: TextStyle(color: slateColor))))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Report Header (Overflow-safe)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPeriod == 'quarterly'
                                        ? 'Quarterly Executive Growth Report'
                                        : 'Annual Church Report',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Compiled on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                                    style: const TextStyle(color: slateColor, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OFFICIAL',
                                style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 28),

                        // Section 1: Attendance Growth
                        _sectionTitle('1. Service Attendance Metrics'),
                        const SizedBox(height: 10),
                        _metricRow(
                          'Average Sunday Attendance',
                          '${_toInt(_data!['sundayAttendance']?['currentAverage'])} attendees',
                        ),
                        _metricRow(
                          'Prior Period Average Sunday',
                          '${_toInt(_data!['sundayAttendance']?['previousAverage'])} attendees',
                        ),
                        _metricRow(
                          'Sunday Attendance Shift',
                          '${_toDouble(_data!['sundayAttendance']?['growthPercentage'])}%',
                          isHighlight: true,
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Membership Expansion
                        _sectionTitle('2. Membership Retention & Additions'),
                        const SizedBox(height: 10),
                        _metricRow(
                          'Active Registered Members',
                          '${_toInt(_data!['membership']?['active'])} members',
                        ),
                        _metricRow(
                          'New Converts Added',
                          '${_toInt(_data!['membership']?['newConverts'])} converts',
                        ),
                        _metricRow(
                          'First Time Visitors',
                          '${_toInt(_data!['membership']?['firstTimers'])} visitors',
                        ),
                        _metricRow(
                          'Inactive Members',
                          '${_toInt(_data!['membership']?['inactive'])} members',
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Financial Contributions
                        if (_data!['financials'] != null) ...[
                          _sectionTitle('3. Financial Offerings & Tithes'),
                          const SizedBox(height: 10),
                          _metricRow(
                            'Total Period Financial Collection',
                            currencyFmt.format(_toDouble(_data!['financials']?['currentTotal'])),
                          ),
                          _metricRow(
                            'Previous Period Financial Total',
                            currencyFmt.format(_toDouble(_data!['financials']?['previousTotal'])),
                          ),
                          _metricRow(
                            'Net Financial Growth Rate',
                            '${_toDouble(_data!['financials']?['growthPercentage'])}%',
                            isHighlight: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA)),
    );
  }

  Widget _metricRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: slateColor, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? const Color(0xFF10B981) : Colors.white,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
