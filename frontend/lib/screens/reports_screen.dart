import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _selectedPeriod = 'weekly';
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  final List<Map<String, String>> _periods = [
    {'id': 'weekly', 'label': 'Weekly Report', 'title': 'Weekly Church Ministry Report'},
    {'id': 'monthly', 'label': 'Monthly Review', 'title': 'Monthly Church Growth Review'},
    {'id': 'quarterly', 'label': 'Quarterly Review', 'title': 'Quarterly Executive Review'},
    {'id': 'yearly', 'label': 'Annual Report', 'title': 'Annual Church Ministry Report'},
  ];

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

  void _copyWhatsAppReport() {
    if (_data == null) return;
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final periodTitle = _periods.firstWhere((p) => p['id'] == _selectedPeriod)['title'] ?? 'Church Report';
    final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    final sundayAtt = _data!['sundayAttendance'] ?? {};
    final midweekAtt = _data!['midweekAttendance'] ?? {};
    final membership = _data!['membership'] ?? {};
    final financials = _data!['financials'];
    final cells = (_data!['cellBreakdown'] as List<dynamic>?) ?? [];

    final buffer = StringBuffer();
    buffer.writeln('⛪ *CHRIST EMBASSY - $periodTitle*');
    buffer.writeln('📅 Date: $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👥 *SERVICE ATTENDANCE:*');
    buffer.writeln('• Sunday Service Avg: ${_toInt(sundayAtt['currentAverage'])} (Growth: ${_toDouble(sundayAtt['growthPercentage'])}%)');
    if (midweekAtt['currentAverage'] != null) {
      buffer.writeln('• Midweek Service Avg: ${_toInt(midweekAtt['currentAverage'])} (Growth: ${_toDouble(midweekAtt['growthPercentage'])}%)');
    }
    buffer.writeln('');
    buffer.writeln('🌟 *SOUL WINNING & RETENTION:*');
    buffer.writeln('• Active Members: ${_toInt(membership['active'])}');
    buffer.writeln('• New Converts Added: ${_toInt(membership['newConverts'])}');
    buffer.writeln('• First Time Visitors: ${_toInt(membership['firstTimers'])}');
    buffer.writeln('• Total Registered: ${_toInt(membership['total'])}');

    if (financials != null) {
      buffer.writeln('');
      buffer.writeln('💰 *FINANCIAL COLLECTIONS:*');
      buffer.writeln('• Total Inflow: ${currencyFmt.format(_toDouble(financials['currentTotal']))} (${_toDouble(financials['growthPercentage'])}% vs prior)');
      final breakdown = (financials['offeringBreakdown'] as List<dynamic>?) ?? [];
      for (final item in breakdown) {
        final type = (item['offering_type'] ?? '').toString().replaceAll('_', ' ');
        buffer.writeln('  - $type: ${currencyFmt.format(_toDouble(item['total_amount']))}');
      }
    }

    if (cells.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🏢 *CELL MINISTRY RANKING:*');
      for (final c in cells) {
        buffer.writeln('• ${c['name']} (${c['leaderName'] ?? 'Leader'}): ${c['memberCount']} members');
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generated via *Framz Reporting System*');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('WhatsApp Church Report copied! Ready to paste into chat.', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _updateFollowUp(int memberId, String newStage) async {
    final success = await ApiService.updateFollowUpStage(memberId, newStage);
    if (success) {
      _loadReport();
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
            // Responsive Hierarchy Selector Bar & Action Button
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                final periodButtons = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: _periods.map((p) {
                        final isSelected = _selectedPeriod == p['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedPeriod = p['id']!);
                            _loadReport();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : slateColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );

                final whatsappBtn = ElevatedButton.icon(
                  onPressed: _data == null ? null : _copyWhatsAppReport,
                  icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                  label: const Text('Copy WhatsApp Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );

                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      periodButtons,
                      whatsappBtn,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      periodButtons,
                      const SizedBox(height: 10),
                      whatsappBtn,
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
                        // Report Header Banner
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _periods.firstWhere((p) => p['id'] == _selectedPeriod)['title'] ?? 'Church Ministry Report',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Period: ${_selectedPeriod.toUpperCase()} • Generated ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
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
                              child: Text(
                                _selectedPeriod.toUpperCase(),
                                style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 28),

                        // Section 1: Service Attendance Breakdown
                        _sectionTitle('1. Service Attendance Metrics'),
                        const SizedBox(height: 10),
                        _metricRow(
                          'Sunday Service Average',
                          '${_toInt(_data!['sundayAttendance']?['currentAverage'])} attendees',
                        ),
                        _metricRow(
                          'Prior Period Sunday Average',
                          '${_toInt(_data!['sundayAttendance']?['previousAverage'])} attendees',
                        ),
                        _metricRow(
                          'Sunday Growth Momentum',
                          '${_toDouble(_data!['sundayAttendance']?['growthPercentage'])}%',
                          isHighlight: true,
                        ),
                        if (_data!['midweekAttendance'] != null) ...[
                          const SizedBox(height: 8),
                          _metricRow(
                            'Midweek Bible Study Average',
                            '${_toInt(_data!['midweekAttendance']?['currentAverage'])} attendees',
                          ),
                          _metricRow(
                            'Midweek Growth Momentum',
                            '${_toDouble(_data!['midweekAttendance']?['growthPercentage'])}%',
                            isHighlight: true,
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Section 2: Membership & Soul Winning
                        _sectionTitle('2. Soul Winning & Retention'),
                        const SizedBox(height: 10),
                        _metricRow(
                          'Active Church Members',
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
                          'Inactive Members (Follow-up list)',
                          '${_toInt(_data!['membership']?['inactive'])} members',
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Cell Ministry Ranking Leaderboard
                        if (_data!['cellBreakdown'] != null && (_data!['cellBreakdown'] as List).isNotEmpty) ...[
                          _sectionTitle('3. Cell Group Growth Leaderboard'),
                          const SizedBox(height: 10),
                          ...(_data!['cellBreakdown'] as List).map((cell) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.hub_rounded, size: 16, color: Color(0xFF3B82F6)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${cell['name']} (${cell['leaderName'] ?? 'Leader'})',
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${cell['memberCount']} members',
                                      style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],

                        // Section 4: First-Timer Follow-Up Pipeline
                        if (_data!['firstTimersList'] != null && (_data!['firstTimersList'] as List).isNotEmpty) ...[
                          _sectionTitle('4. First-Timer & New Convert Pipeline'),
                          const SizedBox(height: 10),
                          ...(_data!['firstTimersList'] as List).map((ft) {
                            final currentStage = ft['followUpStage'] ?? 'PENDING';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${ft['fullName']} (${ft['status'].toString().replaceAll('_', ' ')})',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Phone: ${ft['phone']} • Cell: ${ft['cellName']}',
                                          style: const TextStyle(color: slateColor, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: ['PENDING', 'CONTACTED', 'VISITED', 'FOUNDATION_SCHOOL', 'JOINED_CELL', 'BAPTIZED'].contains(currentStage)
                                          ? currentStage
                                          : 'PENDING',
                                      dropdownColor: const Color(0xFF1E293B),
                                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11),
                                      items: const [
                                        DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                                        DropdownMenuItem(value: 'CONTACTED', child: Text('Contacted')),
                                        DropdownMenuItem(value: 'VISITED', child: Text('Visited')),
                                        DropdownMenuItem(value: 'FOUNDATION_SCHOOL', child: Text('Foundation Sch')),
                                        DropdownMenuItem(value: 'JOINED_CELL', child: Text('Joined Cell')),
                                        DropdownMenuItem(value: 'BAPTIZED', child: Text('Baptized')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          _updateFollowUp(ft['id'], val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],

                        // Section 5: Financial Summary
                        if (_data!['financials'] != null) ...[
                          _sectionTitle('5. Financial Offerings & Tithes'),
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
                          const SizedBox(height: 10),
                          const Text('Breakdown by Offering Category:', style: TextStyle(color: slateColor, fontSize: 12)),
                          const SizedBox(height: 6),
                          ...((_data!['financials']?['offeringBreakdown'] as List<dynamic>?) ?? []).map((item) {
                            final type = (item['offering_type'] ?? '').toString().replaceAll('_', ' ');
                            final amt = _toDouble(item['total_amount']);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('  • $type', style: const TextStyle(color: slateColor, fontSize: 12)),
                                  Text(currencyFmt.format(amt), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }),
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
