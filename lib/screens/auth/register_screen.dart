import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:doss_core/doss_core.dart';
import '../../blocs/auth/driver_auth_bloc.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  String _governorate = 'Cairo';
  bool _obscure = true;

  static const _governorates = [
    'Cairo',
    'Giza',
    'Alexandria',
    'Luxor',
    'Aswan',
    'Mansoura',
    'Tanta',
    'Ismailia',
    'Suez',
    'Port Said',
    'Hurghada',
    'Sharm El Sheikh',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<DriverAuthBloc>().add(DriverAuthRegisterRequested(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passCtrl.text,
            vehiclePlate: _plateCtrl.text.trim().toUpperCase(),
            vehicleModel: _modelCtrl.text.trim(),
            governorate: _governorate,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAuthBloc, DriverAuthState>(
      listener: (context, state) {
        if (state is DriverAuthPending) {
          context.go('/terms');
        } else if (state is DriverAuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          title: const Text('Driver Application'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: AppTheme.inputDecoration(
                      label: 'Full Name',
                      hint: 'Ahmed Mohamed',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: AppTheme.inputDecoration(
                      label: 'Phone Number',
                      hint: '01XXXXXXXXX',
                      prefixIcon: Icons.phone_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 10) return 'Invalid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: AppTheme.inputDecoration(
                      label: 'Password',
                      hint: 'Min 8 characters',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 8) return 'At least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Vehicle Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: AppTheme.inputDecoration(
                      label: 'License Plate',
                      hint: 'ABC 1234',
                      prefixIcon: Icons.credit_card_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _modelCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: AppTheme.inputDecoration(
                      label: 'Vehicle Model',
                      hint: 'Toyota Corolla 2020',
                      prefixIcon: Icons.directions_car_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  // Governorate dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _governorate,
                    dropdownColor: AppTheme.primaryMid,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: AppTheme.inputDecoration(
                      label: 'Governorate',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                    items: _governorates
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _governorate = v!),
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<DriverAuthBloc, DriverAuthState>(
                    builder: (context, state) {
                      final loading = state is DriverAuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Application',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Applications are reviewed within 24 hours',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
