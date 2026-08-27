import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Initialize with current state if available
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _populateControllers(authState.user);
    }
  }

  void _populateControllers(UserModel user) {
    _nameController.text = user.fullName;
    _emailController.text = user.emailId ?? '';
    _phoneController.text = user.mobileNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values if cancelled
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          _populateControllers(authState.user);
        }
      }
    });
  }

  void _saveProfile() {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Phone are required')),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthUpdateProfileRequested(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _phoneController.text.trim(),
    ));
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _populateControllers(state.user);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        UserModel? user;
        bool isLoading = state is AuthLoading;
        if (state is AuthAuthenticated) {
          user = state.user;
        }

        return Scaffold(
          backgroundColor: AsmitaPalette.systemBG,
          body: SafeArea(
            child: Column(
              children: [
                AsmitaSubHeader(
                  title: 'Profile',
                  trailing: GestureDetector(
                    onTap: isLoading ? null : _toggleEdit,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                        color: AsmitaPalette.deepNavy,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  const LinearProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: user == null
                        ? const Center(child: Text('Failed to load profile data.'))
                        : Column(
                            children: [
                              _buildProfileHeader(textTheme, user),
                              const SizedBox(height: 24),
                              _buildDetailsSection(textTheme, user),
                              const SizedBox(height: 24),
                              if (_isEditing)
                                _buildSaveButton(textTheme, isLoading),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(TextTheme textTheme, UserModel user) {
    String initials = user.fullName.isNotEmpty 
        ? user.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AsmitaPalette.deepNavy,
            backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                ? NetworkImage(user.profilePictureUrl!)
                : null,
            child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                ? Text(initials, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 24))
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.fullName, style: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(user.userType.toUpperCase(), style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(user.accountType.toUpperCase(), style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.actionRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(TextTheme textTheme, UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
      ),
      child: Column(
        children: [
          _buildEditableRow(textTheme, Icons.person_rounded, 'Full Name', _nameController, true),
          _buildEditableRow(textTheme, Icons.email_rounded, 'Email', _emailController, true),
          _buildEditableRow(textTheme, Icons.phone_rounded, 'Phone', _phoneController, false),
        ],
      ),
    );
  }

  Widget _buildEditableRow(TextTheme textTheme, IconData icon, String label, TextEditingController controller, bool showBorder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AsmitaPalette.deepNavy, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight, fontSize: 12)),
                const SizedBox(height: 2),
                if (_isEditing)
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                    ),
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  )
                else
                  Text(controller.text.isEmpty ? 'Not provided' : controller.text, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSaveButton(TextTheme textTheme, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AsmitaPalette.deepNavy,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Save Profile', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

