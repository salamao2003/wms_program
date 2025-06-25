import 'package:flutter/material.dart';
import '../backend/signup_logic.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  // متغيرات معاينة الدعوة
  Map<String, dynamic>? _invitePreview;
  bool _isValidatingInvite = false;
  
  // متغيرات قوة كلمة المرور
  Map<String, dynamic>? _passwordStrength;

  final _signUpLogic = SignUpLogic();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    await _signUpLogic.handleSignUpWithInvite(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      inviteCode: _inviteCodeController.text.trim(),
      context: context,
      setLoading: (value) => setState(() => _isLoading = value),
      setError: (value) => setState(() => _errorMessage = value),
      onSuccess: () => Navigator.pop(context),
    );
  }

  Future<void> _validateInviteCode() async {
    final email = _emailController.text.trim();
    final inviteCode = _inviteCodeController.text.trim();
    
    if (email.isEmpty || inviteCode.isEmpty) return;

    setState(() {
      _isValidatingInvite = true;
      _invitePreview = null;
    });

    try {
      final preview = await _signUpLogic.previewInvitation(
        inviteCode: inviteCode,
        email: email,
      );

      setState(() {
        _invitePreview = preview;
        _isValidatingInvite = false;
      });
    } catch (e) {
      setState(() {
        _isValidatingInvite = false;
        _invitePreview = null;
      });
    }
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isNotEmpty) {
      setState(() {
        _passwordStrength = _signUpLogic.getPasswordStrength(password);
      });
    } else {
      setState(() {
        _passwordStrength = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رسالة ترحيبية
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مرحباً بك في نظام إدارة المخازن',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'لإنشاء حساب جديد، تحتاج إلى كود دعوة من الإدارة',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // رسالة خطأ
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // كود الدعوة
              TextFormField(
                controller: _inviteCodeController,
                decoration: InputDecoration(
                  labelText: 'كود الدعوة *',
                  hintText: 'أدخل كود الدعوة الذي تلقيته',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: _isValidatingInvite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _invitePreview != null
                          ? Icon(
                              _invitePreview!['is_valid'] ? Icons.check_circle : Icons.error,
                              color: _invitePreview!['is_valid'] ? Colors.green : Colors.red,
                            )
                          : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.length > 10) {
                    _validateInviteCode();
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال كود الدعوة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // معاينة الدعوة
              if (_invitePreview != null)
                Card(
                  color: _invitePreview!['is_valid']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _invitePreview!['is_valid'] ? Icons.check_circle : Icons.error,
                              color: _invitePreview!['is_valid'] ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _invitePreview!['is_valid'] ? 'كود دعوة صحيح' : 'كود دعوة منتهي الصلاحية',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _invitePreview!['is_valid'] ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (_invitePreview!['is_valid']) ...[
                          const SizedBox(height: 8),
                          Text('الدور: ${_invitePreview!['role_display_name']}'),
                          Text('صالح لمدة: ${_invitePreview!['time_left_days']} أيام'),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // البريد الإلكتروني
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني *',
                  hintText: 'example@company.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  if (value.contains('@') && _inviteCodeController.text.isNotEmpty) {
                    _validateInviteCode();
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@')) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الاسم الكامل
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل *',
                  hintText: 'أدخل اسمك الكامل',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال الاسم الكامل';
                  }
                  if (value.trim().length < 2) {
                    return 'الاسم يجب أن يكون حرفين على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // كلمة المرور
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور *',
                  hintText: 'أدخل كلمة مرور قوية',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => _updatePasswordStrength(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // مؤشر قوة كلمة المرور
              if (_passwordStrength != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'قوة كلمة المرور: ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _passwordStrength!['label'],
                              style: TextStyle(
                                color: _passwordStrength!['color'],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _passwordStrength!['strength'] / 100,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(_passwordStrength!['color']),
                        ),
                        if (_passwordStrength!['missing'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'مطلوب: ${_passwordStrength!['missing'].join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // زر إنشاء الحساب
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('جاري إنشاء الحساب...'),
                          ],
                        )
                      : const Text(
                          'إنشاء الحساب',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // العودة لتسجيل الدخول
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("لديك حساب بالفعل؟"),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('تسجيل الدخول'),
                  ),
                ],
              ),

              // معلومات إضافية
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ملاحظات مهمة',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• كود الدعوة صالح لمدة 7 أيام من تاريخ الإنشاء'),
                      const Text('• يجب أن يطابق البريد الإلكتروني المستخدم في الدعوة'),
                      const Text('• بعد إنشاء الحساب ستحتاج لتأكيد البريد الإلكتروني'),
                      const Text('• في حالة عدم وجود كود دعوة، تواصل مع الإدارة'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}