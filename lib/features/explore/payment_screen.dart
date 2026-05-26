import 'package:flutter/material.dart';
import 'package:salon_app_view/features/appointment/confirmation_screen.dart';


const kPurpleDark = Color(0xFF1A0A3B);
const kPurpleMid = Color(0xFF3D2080);
const kPurpleAccent = Color(0xFF7B2FBE);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);

class PaymentOptionsScreen extends StatefulWidget {
  final String salonName;
  final String salonLocation;
  final double totalAmount;

  const PaymentOptionsScreen({
    super.key,
    required this.salonName,
    required this.salonLocation,
    required this.totalAmount,
  });

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  String? _selectedPayment;

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: kWhite,
                        size: 24,
                      ),
                    ),
                  ),
                  const Text(
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
                    style: const TextStyle(
                      color: kPurpleLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: kPurpleLight,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.salonLocation,
                        style: const TextStyle(color: kTextMuted, fontSize: 12),
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
                       const Column(
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
                          SizedBox(height: 2),
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
                          '₹${widget.totalAmount.toInt()}',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Pre-payment ───────────────────────
                    _PaymentTile(
                      label: 'Pre-payment',
                      methodLabel: 'UPI/',
                      methodIcons: const [
                        Icons.account_balance_wallet_outlined,
                      ],
                      isSelected: _selectedPayment == 'pre',
                      onTap: () => setState(() => _selectedPayment = 'pre'),
                    ),

                    const SizedBox(height: 12),

                    // ── Post-payment ──────────────────────
                    _PaymentTile(
                      label: 'Post-payment',
                      methodLabel: 'Cash/ UPI/',
                      methodIcons: const [
                        Icons.payments_outlined,
                        Icons.account_balance_wallet_outlined,
                      ],
                      isSelected: _selectedPayment == 'post',
                      onTap: () => setState(() => _selectedPayment = 'post'),
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
                  onPressed: _selectedPayment == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmationScreen(
                                salonName: widget.salonName,
                                salonLocation: widget.salonLocation,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPayment == null
                        ? kPurpleAccent.withOpacity(0.4)
                        : kPurpleAccent,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
  });

  final String label;
  final String methodLabel;
  final List<IconData> methodIcons;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? kPurpleAccent.withOpacity(0.15)
              : kPurpleMid.withOpacity(0.5),
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
                color: isSelected ? kWhite : kTextMuted,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Row(
              children: [
                Text(
                  methodLabel,
                  style: const TextStyle(color: kTextMuted, fontSize: 13),
                ),
                ...methodIcons.map(
                  (ic) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(ic, color: kTextMuted, size: 18),
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
