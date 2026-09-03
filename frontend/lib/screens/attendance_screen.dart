import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const Color slateColor = Color(0xFF94A3B8);

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _attendances = [];
  List<dynamic> _serviceTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final logs = await ApiService.getAttendances();
    final types = await ApiService.getServiceTypes();
    if (mounted) {
      setState(() {
        _attendances = logs;
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
      builder: (ctx) => _RecordAttendanceModal(
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordModal,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Record Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        'Attendance Records',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Headcount logs by service and cell meetings',
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
            else if (_attendances.isEmpty)
              const Expanded(child: Center(child: Text('No attendance recorded yet', style: TextStyle(color: slateColor))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _attendances.length,
                  itemBuilder: (ctx, i) {
                    final item = _attendances[i];
                    final dateStr = item['event_date'] ?? '';
                    final male = item['headcount_male'] ?? 0;
                    final female = item['headcount_female'] ?? 0;
                    final children = item['headcount_children'] ?? 0;
                    final total = item['total_headcount'] ?? (male + female + children);

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
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.groups_rounded, color: Color(0xFF3B82F6), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['service_name'] ?? 'Church Service',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dateStr • M: $male | F: $female | Ch: $children',
                                  style: const TextStyle(color: slateColor, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$total',
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
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

class _RecordAttendanceModal extends StatefulWidget {
  final List<dynamic> serviceTypes;
  final VoidCallback onSuccess;

  const _RecordAttendanceModal({required this.serviceTypes, required this.onSuccess});

  @override
  State<_RecordAttendanceModal> createState() => _RecordAttendanceModalState();
}

class _RecordAttendanceModalState extends State<_RecordAttendanceModal> {
  int? _selectedServiceId;
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _maleCtrl = TextEditingController(text: '0');
  final _femaleCtrl = TextEditingController(text: '0');
  final _childrenCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.serviceTypes.isNotEmpty) {
      _selectedServiceId = widget.serviceTypes[0]['id'];
    }
  }

  void _save() async {
    if (_selectedServiceId == null) return;
    setState(() => _isSaving = true);

    final success = await ApiService.recordAttendance({
      'service_type_id': _selectedServiceId,
      'event_date': _dateCtrl.text.trim(),
      'headcount_male': int.tryParse(_maleCtrl.text) ?? 0,
      'headcount_female': int.tryParse(_femaleCtrl.text) ?? 0,
      'headcount_children': int.tryParse(_childrenCtrl.text) ?? 0,
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
          const Text('Record Attendance Event', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
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

          TextField(
            controller: _dateCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Event Date (YYYY-MM-DD)', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _maleCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Male', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _femaleCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Female', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _childrenCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Children', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Notes / Event Highlights', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Attendance Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
