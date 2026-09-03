import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const Color slateColor = Color(0xFF94A3B8);

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<dynamic> _members = [];
  String _selectedStatus = 'ALL';
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getMembers(status: _selectedStatus, search: _searchCtrl.text.trim());
    if (mounted) {
      setState(() {
        _members = list;
        _isLoading = false;
      });
    }
  }

  void _showAddMemberModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddMemberModal(
        onSuccess: () {
          Navigator.pop(ctx);
          _loadMembers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberModal,
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overflow-safe Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Membership Directory',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track active members, new converts, and first timers',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadMembers,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Refresh',
                )
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      hintStyle: const TextStyle(color: slateColor, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: slateColor, size: 20),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _loadMembers(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadMembers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Search', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('ALL', 'All Members'),
                  _filterChip('ACTIVE', 'Active Members'),
                  _filterChip('NEW_CONVERT', 'New Converts'),
                  _filterChip('FIRST_TIMER', 'First Timers'),
                  _filterChip('INACTIVE', 'Inactive'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_members.isEmpty)
              const Expanded(child: Center(child: Text('No members found', style: TextStyle(color: slateColor))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (ctx, i) {
                    final m = _members[i];
                    final fullName = '${m['first_name']} ${m['last_name']}';
                    final status = m['status'] ?? 'ACTIVE';
                    final phone = m['phone'] ?? 'No phone';

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
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            child: Text(
                              (m['first_name'] != null && m['first_name'].isNotEmpty)
                                  ? m['first_name'][0].toUpperCase()
                                  : 'M',
                              style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Phone: $phone • Cell: ${m['cell_name'] ?? 'Main'}',
                                  style: const TextStyle(color: slateColor, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _statusBadge(status),
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

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedStatus == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : slateColor, fontSize: 11)),
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: const Color(0xFF2563EB),
        onSelected: (val) {
          setState(() => _selectedStatus = id);
          _loadMembers();
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFF10B981);
    String label = status.replaceAll('_', ' ');

    if (status == 'NEW_CONVERT') bg = const Color(0xFFF59E0B);
    if (status == 'FIRST_TIMER') bg = const Color(0xFF3B82F6);
    if (status == 'INACTIVE') bg = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AddMemberModal extends StatefulWidget {
  final VoidCallback onSuccess;

  const _AddMemberModal({required this.onSuccess});

  @override
  State<_AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<_AddMemberModal> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _gender = 'Male';
  String _status = 'ACTIVE';
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  bool _isSaving = false;

  void _save() async {
    if (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);

    final success = await ApiService.addMember({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'gender': _gender,
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'status': _status,
      'date_joined': _dateCtrl.text.trim(),
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
          const Text('Register New Member', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'First Name', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lastNameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Last Name', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Gender', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (val) => setState(() => _gender = val!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(value: 'NEW_CONVERT', child: Text('New Convert')),
                    DropdownMenuItem(value: 'FIRST_TIMER', child: Text('First Timer')),
                  ],
                  onChanged: (val) => setState(() => _status = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _phoneCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Email Address (Optional)', labelStyle: TextStyle(color: slateColor, fontSize: 12)),
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Member Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
