import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/features/appointment/confirmation_screen.dart';
import 'package:salon_app_view/shared/providers/payment_provider.dart';

class PaymentOptionsScreen extends StatefulWidget {
  final String salonName;
  final String salonLocation;
  final double totalAmount;

  /// The saved `public.bookings.id` this payment is for. When null (the demo
  /// booking flow has not created a row yet) only "Pay at salon" is offered.
  final String? bookingId;

  const PaymentOptionsScreen({
    super.key,
    required this.salonName,
    required this.salonLocation,
    required this.totalAmount,
    this.bookingId,
  });

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  /// 'esewa' | 'khalti' | 'cash'
  String? _selectedPayment;
  bool _paying = false;

  AppThemeColors get colors => AppThemeColors.of(context);

  bool get _isOnline =>
      _selectedPayment == 'esewa' || _selectedPayment == 'khalti';

  Future<void> _continue() async {
    if (_selectedPayment == 'cash') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            salonName: widget.salonName,
            salonLocation: widget.salonLocation,
          ),
        ),
      );
      return;
    }

    final bookingId = widget.bookingId;
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Save the appointment first — online payment needs a booking.',
          ),
        ),
      );
      return;
    }

    setState(() => _paying = true);
    final payments = context.read<PaymentProvider>();
    final started = await payments.startCheckout(
      bookingId: bookingId,
      provider: _selectedPayment!,
    );
    if (!mounted) return;
    setState(() => _paying = false);

    if (!started) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(payments.error ?? 'Could not start the payment.'),
          duration: const Duration(seconds: 6),
          action: payments.notDeployed
              ? SnackBarAction(
                  label: 'Pay at salon',
                  textColor: colors.purpleLight,
                  onPressed: () => setState(() => _selectedPayment = 'cash'),
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: kWhite,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    'Payment Options',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Salon header ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: kPurpleMid,
              child: Column(
                children: [
                  Text(
                    widget.salonName,
                    style: TextStyle(
                      color: kPurpleLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: kPurpleLight,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.salonLocation,
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Total amount ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total amount',
                              style: TextStyle(
                                color: kWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Inclusive of all taxes & charges',
                              style: TextStyle(
                                color: kPurpleLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rs ${widget.totalAmount.toInt()}',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Online wallets ────────────────────
                    _PaymentTile(
                      label: 'eSewa',
                      methodLabel: 'Wallet',
                      methodIcons: const [
                        Icons.account_balance_wallet_outlined,
                      ],
                      isSelected: _selectedPayment == 'esewa',
                      enabled: widget.bookingId != null,
                      onTap: () => setState(() => _selectedPayment = 'esewa'),
                    ),

                    const SizedBox(height: 12),

                    _PaymentTile(
                      label: 'Khalti',
                      methodLabel: 'Wallet',
                      methodIcons: const [Icons.payments_outlined],
                      isSelected: _selectedPayment == 'khalti',
                      enabled: widget.bookingId != null,
                      onTap: () => setState(() => _selectedPayment = 'khalti'),
                    ),

                    if (widget.bookingId == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Save the appointment first to pay online.',
                        style: TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Pay at the salon ──────────────────
                    _PaymentTile(
                      label: 'Pay at salon',
                      methodLabel: 'Cash',
                      methodIcons: const [Icons.storefront_outlined],
                      isSelected: _selectedPayment == 'cash',
                      onTap: () => setState(() => _selectedPayment = 'cash'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Continue button ───────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedPayment == null || _paying)
                      ? null
                      : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_selectedPayment == null || _paying)
                        ? kPurpleAccent.withOpacity(0.4)
                        : kPurpleAccent,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _paying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isOnline ? 'Pay now' : 'Continue',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.label,
    required this.methodLabel,
    required this.methodIcons,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String methodLabel;
  final List<IconData> methodIcons;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    final labelColor = !enabled
        ? kTextMuted.withOpacity(0.5)
        : isSelected
            ? kWhite
            : kTextMuted;
    final mutedColor = kTextMuted.withOpacity(enabled ? 1 : 0.5);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? kPurpleAccent.withOpacity(0.15)
              : kPurpleMid.withOpacity(enabled ? 0.5 : 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPurpleAccent : kPurpleLight.withOpacity(0.3),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Row(
              children: [
                Text(
                  methodLabel,
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
                ...methodIcons.map(
                  (ic) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(ic, color: mutedColor, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
