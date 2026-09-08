import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _name = TextEditingController(text: profile?.name ?? '');
    _phone = TextEditingController(text: profile?.phone ?? '');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    if (auth.profile != null) {
      await AuthService().updateProfile(auth.profile!.uid, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
      });
      await auth.refreshProfile();
    }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  void _showAddPaymentMethodSheet() {
    final cardHolder = TextEditingController();
    final cardNumber = TextEditingController();
    final expiry = TextEditingController();
    String selectedType = 'card';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Payment Method', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Card'),
                      selected: selectedType == 'card',
                      onSelected: (_) => setModalState(() => selectedType = 'card'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Wallet'),
                      selected: selectedType == 'wallet',
                      onSelected: (_) => setModalState(() => selectedType = 'wallet'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Cash on Delivery'),
                      selected: selectedType == 'cod',
                      onSelected: (_) => setModalState(() => selectedType = 'cod'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (selectedType == 'card') ...[
                CustomTextField(controller: cardHolder, label: 'Cardholder Name'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: cardNumber,
                  label: 'Card Number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(controller: expiry, label: 'Expiry (MM/YY)'),
                const SizedBox(height: 8),
                const Text(
                  'For your security, only the card brand and last 4 digits are ever saved — never the full number.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ] else if (selectedType == 'wallet') ...[
                const Text('A digital wallet (e.g. PayPal, Apple Pay) will be linked at checkout.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ] else ...[
                const Text('Pay with cash when your order is delivered.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 20),
              CustomButton(
                label: 'Save Payment Method',
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  if (auth.profile == null) return;

                  late SavedPaymentMethod method;
                  if (selectedType == 'card') {
                    final digits = cardNumber.text.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 4) return;
                    final last4 = digits.substring(digits.length - 4);
                    method = SavedPaymentMethod(
                      id: const Uuid().v4(),
                      type: 'card',
                      label: '${cardHolder.text.trim().isEmpty ? 'Card' : cardHolder.text.trim()} •••• $last4',
                      last4: last4,
                      brand: digits.startsWith('4') ? 'Visa' : (digits.startsWith('5') ? 'Mastercard' : 'Card'),
                      expiry: expiry.text.trim(),
                      isDefault: auth.profile!.paymentMethods.isEmpty,
                    );
                  } else if (selectedType == 'wallet') {
                    method = SavedPaymentMethod(
                      id: const Uuid().v4(),
                      type: 'wallet',
                      label: 'Digital Wallet',
                      isDefault: auth.profile!.paymentMethods.isEmpty,
                    );
                  } else {
                    method = SavedPaymentMethod(
                      id: const Uuid().v4(),
                      type: 'cod',
                      label: 'Cash on Delivery',
                      isDefault: auth.profile!.paymentMethods.isEmpty,
                    );
                  }

                  final updated = [...auth.profile!.paymentMethods, method];
                  await AuthService().updateProfile(auth.profile!.uid, {
                    'paymentMethods': updated.map((p) => p.toMap()).toList(),
                  });
                  await auth.refreshProfile();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removePaymentMethod(String id) async {
    final auth = context.read<AuthProvider>();
    if (auth.profile == null) return;
    final updated = auth.profile!.paymentMethods.where((p) => p.id != id).toList();
    await AuthService().updateProfile(auth.profile!.uid, {
      'paymentMethods': updated.map((p) => p.toMap()).toList(),
    });
    await auth.refreshProfile();
  }

  Future<void> _setDefaultPaymentMethod(String id) async {
    final auth = context.read<AuthProvider>();
    if (auth.profile == null) return;
    final updated = auth.profile!.paymentMethods.map((p) {
      return SavedPaymentMethod(
        id: p.id,
        type: p.type,
        label: p.label,
        last4: p.last4,
        brand: p.brand,
        expiry: p.expiry,
        isDefault: p.id == id,
      );
    }).toList();
    await AuthService().updateProfile(auth.profile!.uid, {
      'paymentMethods': updated.map((p) => p.toMap()).toList(),
    });
    await auth.refreshProfile();
  }

  Future<void> _removeAddress(int index) async {
    final auth = context.read<AuthProvider>();
    if (auth.profile == null) return;
    final list = [...auth.profile!.addresses];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
        list[0] = Address(
          label: list[0].label,
          line1: list[0].line1,
          city: list[0].city,
          state: list[0].state,
          zip: list[0].zip,
          isDefault: true,
        );
      }
      await AuthService().updateProfile(auth.profile!.uid, {
        'addresses': list.map((a) => a.toMap()).toList(),
      });
      await auth.refreshProfile();
    }
  }

  Future<void> _setDefaultAddress(int index) async {
    final auth = context.read<AuthProvider>();
    if (auth.profile == null) return;
    final list = auth.profile!.addresses.asMap().entries.map((entry) {
      final a = entry.value;
      return Address(
        label: a.label,
        line1: a.line1,
        city: a.city,
        state: a.state,
        zip: a.zip,
        isDefault: entry.key == index,
      );
    }).toList();
    await AuthService().updateProfile(auth.profile!.uid, {
      'addresses': list.map((a) => a.toMap()).toList(),
    });
    await auth.refreshProfile();
  }

  void _showAddAddressSheet() {
    final label = TextEditingController(text: 'Home');
    final line1 = TextEditingController();
    final city = TextEditingController();
    final state = TextEditingController();
    final zip = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Shipping Address', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            CustomTextField(controller: label, label: 'Label (e.g. Home, Work)'),
            const SizedBox(height: 12),
            CustomTextField(controller: line1, label: 'Street Address'),
            const SizedBox(height: 12),
            CustomTextField(controller: city, label: 'City'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CustomTextField(controller: state, label: 'State')),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(controller: zip, label: 'ZIP Code')),
            ]),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Save Address',
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                if (auth.profile == null) return;
                if (line1.text.trim().isEmpty || city.text.trim().isEmpty) return;
                final newAddress = Address(
                  label: label.text.trim().isEmpty ? 'Address' : label.text.trim(),
                  line1: line1.text.trim(),
                  city: city.text.trim(),
                  state: state.text.trim(),
                  zip: zip.text.trim(),
                  isDefault: auth.profile!.addresses.isEmpty,
                );
                final updatedAddresses = [...auth.profile!.addresses, newAddress];
                await AuthService().updateProfile(auth.profile!.uid, {
                  'addresses': updatedAddresses.map((a) => a.toMap()).toList(),
                });
                await auth.refreshProfile();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CustomTextField(controller: _name, label: 'Full Name', prefixIcon: Icons.person_outline_rounded),
          const SizedBox(height: 16),
          CustomTextField(controller: _phone, label: 'Phone Number', prefixIcon: Icons.phone_outlined),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping Addresses', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _showAddAddressSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (profile?.addresses.isEmpty ?? true)
            const Text('No addresses saved yet.', style: TextStyle(color: AppColors.textSecondary))
          else
            ...profile!.addresses.asMap().entries.map((entry) {
              final idx = entry.key;
              final a = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  title: Row(
                    children: [
                      Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (a.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(a.formatted),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!a.isDefault)
                        IconButton(
                          tooltip: 'Set as Default',
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.textSecondary),
                          onPressed: () => _setDefaultAddress(idx),
                        ),
                      IconButton(
                        tooltip: 'Delete Address',
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () => _removeAddress(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Methods', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _showAddPaymentMethodSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (profile?.paymentMethods.isEmpty ?? true)
            const Text('No payment methods saved yet.', style: TextStyle(color: AppColors.textSecondary))
          else
            ...profile!.paymentMethods.map((p) => Card(
                  child: ListTile(
                    leading: Icon(_paymentIcon(p.type), color: AppColors.primary),
                    title: Row(
                      children: [
                        Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (p.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: p.expiry != null && p.expiry!.isNotEmpty ? Text('Expires ${p.expiry}') : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!p.isDefault)
                          IconButton(
                            tooltip: 'Set as Default',
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.textSecondary),
                            onPressed: () => _setDefaultPaymentMethod(p.id),
                          ),
                        IconButton(
                          tooltip: 'Delete Payment Method',
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () => _removePaymentMethod(p.id),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 28),
          CustomButton(label: 'Save Changes', isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }

  IconData _paymentIcon(String type) {
    switch (type) {
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'cod':
        return Icons.payments_outlined;
      case 'card':
      default:
        return Icons.credit_card_rounded;
    }
  }
}
