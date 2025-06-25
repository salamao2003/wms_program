import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/supabase_service.dart';

class InvitationsManagementScreen extends StatefulWidget {
  const InvitationsManagementScreen({super.key});

  @override
  State<InvitationsManagementScreen> createState() => _InvitationsManagementScreenState();
}

class _InvitationsManagementScreenState extends State<InvitationsManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invitations = await _supabaseService.getPendingInvitations();
      setState(() {
        _invitations = invitations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createInvitation() async {
    final emailController = TextEditingController();
    String selectedRole = SupabaseService.ROLE_WAREHOUSE_MANAGER;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء دعوة جديدة'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني *',
                  hintText: 'example@company.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'الدور',
                  prefixIcon: Icon(Icons.admin_panel_settings),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: SupabaseService.ROLE_ADMIN,
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(SupabaseService.getRoleDisplayName(SupabaseService.ROLE_ADMIN)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: SupabaseService.ROLE_WAREHOUSE_MANAGER,
                    child: Row(
                      children: [
                        Icon(Icons.warehouse, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(SupabaseService.getRoleDisplayName(SupabaseService.ROLE_WAREHOUSE_MANAGER)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: SupabaseService.ROLE_PROJECT_MANAGER,
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(SupabaseService.getRoleDisplayName(SupabaseService.ROLE_PROJECT_MANAGER)),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('معلومات مهمة', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• الدعوة صالحة لمدة 7 أيام'),
                    Text('• سيتم إرسال كود الدعوة للإيميل المحدد'),
                    Text('• يمكن استخدام الدعوة مرة واحدة فقط'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isEmpty || !emailController.text.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال بريد إلكتروني صحيح')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('إنشاء الدعوة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final inviteCode = await _supabaseService.createInvitation(
          email: emailController.text.trim(),
          role: selectedRole,
        );

        if (inviteCode != null && mounted) {
          _showInviteCodeDialog(inviteCode, emailController.text.trim(), selectedRole);
          _loadInvitations(); // إعادة تحميل القائمة
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إنشاء الدعوة: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showInviteCodeDialog(String inviteCode, String email, String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('تم إنشاء الدعوة بنجاح!'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('البريد الإلكتروني:', email),
              _buildDetailRow('الدور:', SupabaseService.getRoleDisplayName(role)),
              _buildDetailRow('صالحة لمدة:', '7 أيام'),
              const SizedBox(height: 16),
              const Text(
                'كود الدعوة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        inviteCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ كود الدعوة!')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      tooltip: 'نسخ الكود',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('تنبيه مهم', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• احتفظ بهذا الكود في مكان آمن'),
                    Text('• شارك الكود مع المستخدم المطلوب'),
                    Text('• الكود صالح لمدة 7 أيام فقط'),
                    Text('• لا يمكن استرجاع الكود مرة أخرى'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _deleteInvitation(int invitationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدعوة'),
        content: const Text('هل أنت متأكد من حذف هذه الدعوة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteInvitation(invitationId);
        _loadInvitations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الدعوة بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف الدعوة: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case SupabaseService.ROLE_ADMIN:
        return Colors.red;
      case SupabaseService.ROLE_WAREHOUSE_MANAGER:
        return Colors.blue;
      case SupabaseService.ROLE_PROJECT_MANAGER:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case SupabaseService.ROLE_ADMIN:
        return Icons.admin_panel_settings;
      case SupabaseService.ROLE_WAREHOUSE_MANAGER:
        return Icons.warehouse;
      case SupabaseService.ROLE_PROJECT_MANAGER:
        return Icons.analytics;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الدعوات'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: _createInvitation,
            icon: const Icon(Icons.add),
            label: const Text('دعوة جديدة'),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadInvitations,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'خطأ: $_errorMessage',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInvitations,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _buildInvitationsContent(),
      ),
    );
  }

  Widget _buildInvitationsContent() {
    if (_invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد دعوات معلقة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('اضغط "دعوة جديدة" لإنشاء دعوة'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createInvitation,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء أول دعوة'),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الدعوات المعلقة (${_invitations.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('البريد الإلكتروني')),
                    DataColumn(label: Text('الدور')),
                    DataColumn(label: Text('تاريخ الإنشاء')),
                    DataColumn(label: Text('ينتهي خلال')),
                    DataColumn(label: Text('الإجراءات')),
                  ],
                  rows: _invitations.map((invitation) {
                    final expiresAt = DateTime.parse(invitation['expires_at']);
                    final timeLeft = expiresAt.difference(DateTime.now());
                    final daysLeft = timeLeft.inDays;
                    final hoursLeft = timeLeft.inHours % 24;

                    return DataRow(
                      cells: [
                        DataCell(Text(invitation['email'])),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(invitation['role']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRoleIcon(invitation['role']),
                                  size: 16,
                                  color: _getRoleColor(invitation['role']),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  SupabaseService.getRoleDisplayName(invitation['role']),
                                  style: TextStyle(
                                    color: _getRoleColor(invitation['role']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(
                          DateTime.parse(invitation['created_at']).toLocal().toString().split(' ')[0],
                        )),
                        DataCell(
                          Text(
                            daysLeft > 0 
                                ? '$daysLeft أيام' 
                                : hoursLeft > 0 
                                    ? '$hoursLeft ساعات'
                                    : 'منتهية',
                            style: TextStyle(
                              color: daysLeft > 2 
                                  ? Colors.green 
                                  : daysLeft > 0 
                                      ? Colors.orange 
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteInvitation(invitation['id']),
                            tooltip: 'حذف الدعوة',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}