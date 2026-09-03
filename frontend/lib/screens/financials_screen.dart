import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const Color slateColor = Color(0xFF94A3B8);

class FinancialsScreen extends StatefulWidget {
  const FinancialsScreen({super.key});

  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen> {
  List<dynamic> _offerings = [];
  List<dynamic> _serviceTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getOfferings();
    final types = await ApiService.getServiceTypes();
    if (mounted) {
      setState(() {
        _offerings = list;
        _serviceTypes = types;
        _isLoading = false;
      });
    }
  }

  void _showRecordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RecordOfferingModal(
        serviceTypes: _serviceTypes,
        onSuccess: () {
          Navigator.pop(ctx);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordModal,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Record Financial Seed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Financial Records',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tithes, Sunday offerings, special seeds & thanksgiving',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Refresh',
                )
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_offerings.isEmpty)
              const Expanded(child: Center(child: Text('No offerings recorded', style: TextStyle(color: slateColor))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _offerings.length,
                  itemBuilder: (ctx, i) {
                    final item = _offerings[i];
                    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                    final typeLabel = (item['offering_type'] ?? '').toString().replaceAll('_', ' ');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF8B5CF6), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  typeLabel,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Date: ${item['event_date']} • Service: ${item['service_name'] ?? 'Sunday'}',
                                  style: const TextStyle(color: slateColor, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currencyFmt.format(amount),
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordOfferingModal extends StatefulWidget {
  final List<dynamic> serviceTypes;
  final VoidCallback onSuccess;

  const _RecordOfferingModal({required this.serviceTypes, required this.onSuccess});

  @override
  State<_RecordOfferingModal> createState() => _RecordOfferingModalState();
}

class _RecordOfferingModalState extends State<_RecordOfferingModal> {
  int? _selectedServiceId;
  String _offeringType = 'SUNDAY_OFFERING';
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  final List<Map<String, String>> _offeringTypes = [
    {'value': 'SUNDAY_OFFERING', 'label': 'Sunday Offering'},
    {'value': 'TITHE', 'label': 'Tithe Collection'},
    {'value': 'SPECIAL_SEED', 'label': 'Special Seed / Partnership'},
    {'value': 'THANKSGIVING', 'label': 'Thanksgiving Offering'},
    {'value': 'BUILDING_FUND', 'label': 'Building Fund'},
    {'value': 'WELFARE', 'label': 'Welfare & Mercy Fund'},
    {'value': 'OTHER', 'label': 'Other Offering'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceTypes.isNotEmpty) {
      _selectedServiceId = widget.serviceTypes[0]['id'];
    }
  }

  void _save() async {
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (_selectedServiceId == null || amt == null || amt <= 0) return;
    setState(() => _isSaving = true);

    final success = await ApiService.recordOffering({
      'service_type_id': _selectedServiceId,
      'event_date': _dateCtrl.text.trim(),
      'offering_type': _offeringType,
      'amount': amt,
      'currency': 'NGN',
      'notes': _notesCtrl.text.trim(),
    });

    setState(() => _isSaving = false);
    if (success) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Record Financial Offering', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 14),

          DropdownButtonFormField<int>(
            initialValue: _selectedServiceId,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Service Type', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
            items: widget.serviceTypes.map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem<int>(
                value: s['id'],
                child: Text(s['name'] ?? ''),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedServiceId = val),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _offeringType,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Offering Category', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
            items: _offeringTypes.map<DropdownMenuItem<String>>((t) {
              return DropdownMenuItem<String>(
                value: t['value'],
                child: Text(t['label'] ?? ''),
              );
            }).toList(),
            onChanged: (val) => setState(() => _offeringType = val!),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Amount (₦)',
              labelStyle: TextStyle(color: slateColor, fontSize: 12),
              prefixText: '₦ ',
              prefixStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _dateCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Notes / Reference', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Offering Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
