import 'dart:convert' show base64Encode;

import 'package:aaravpos/core/utils/extensions/context_extension.dart';
import 'package:aaravpos/core/utils/extensions/space_extension.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signature/signature.dart';

/// Standalone consent dialog widget.
/// Shown via showDialog() from ReviewScreen.
/// Reads ConsentBloc for heading / text / signatureType.
/// Dispatches ConsentSignRequested on confirm.
///
/// Layout (tablet ≥ 600 px wide):
///   ┌──────────────────────────────────────────────────┐
///   │  Title (centered, bold)                          │
///   ├──────────────────────────────────────────────────┤
///   │  Scrollable consent text (white box, scrollbar)  │
///   ├────────────────────────┬─────────────────────────┤
///   │  Sign Here / input     │  □ Email me             │
///   │  [signature pad]       │                         │
///   │  ↺ Clear               │  [Confirm]  [Cancel]    │
///   └────────────────────────┴─────────────────────────┘
///
/// Layout (mobile < 600 px):
///   Title → consent text → input → Email me → buttons (full-width row)

class ConsentDialog extends StatefulWidget {
  const ConsentDialog({super.key});

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final TextEditingController _typedNameController = TextEditingController();

  bool _emailMe = false;
  bool _checkboxAgreed = false;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _sigController.addListener(() {
      final has = _sigController.isNotEmpty;
      if (has != _hasSignature) setState(() => _hasSignature = has);
    });
  }

  @override
  void dispose() {
    _sigController.dispose();
    _typedNameController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool get _canConfirm {
    final type = context.read<ConsentBloc>().state.signatureType;
    switch (type) {
      case 'CHECKBOX_ONLY':
        return _checkboxAgreed;
      case 'TYPED_NAME':
        return _typedNameController.text.trim().isNotEmpty;
      default: // SIGNATURE_IMAGE
        return _hasSignature;
    }
  }

  Future<void> _confirm() async {
    if (!_canConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the consent form before confirming.'),
          backgroundColor: Color(0xFFE12242),
        ),
      );
      return;
    }

    final bloc = context.read<ConsentBloc>();
    final type = bloc.state.signatureType;

    if (type == 'SIGNATURE_IMAGE') {
      final bytes = await _sigController.toPngBytes();
      if (bytes == null || !mounted) return;
      final b64 = 'data:image/png;base64,${base64Encode(bytes)}';
      bloc.add(ConsentSignRequested(signatureType: type, imageUrl: b64));
    } else if (type == 'TYPED_NAME') {
      bloc.add(
        ConsentSignRequested(
          signatureType: type,
          typedName: _typedNameController.text.trim(),
        ),
      );
    } else {
      bloc.add(
        const ConsentSignRequested(signatureType: 'CHECKBOX_ONLY', isChecked: true),
      );
    }

    // Close the dialog — signed data is now in ConsentBloc state.
    // ReviewScreen button will change to "Continue" automatically.
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final hPad = isMobile ? 20.0 : 32.0;
    final vPad = isMobile ? 20.0 : 28.0;

    return BlocConsumer<ConsentBloc, ConsentState>(
      listener: (ctx, state) {
        // When more services need signing after this one, the dialog stays open
        // and the next service's content loads automatically (state updates).
        // No need to pop here — _confirm() already called Navigator.pop() via
        // the Confirm button tap. We only need to handle the case where
        // another service is pending (needsSign with remaining services).
        // The dialog is dismissed by the Confirm button directly.
      },
      builder: (ctx, state) {
        final type = state.signatureType;
        final isSigning = state.status == ConsentStatus.checking;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 48,
            vertical: isMobile ? 24 : 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title ────────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 16),
                    child: Text(
                      state.consentHeading.isNotEmpty
                          ? state.consentHeading
                          : 'Consent Form',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 17 : 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),

                  // ── Scrollable consent text ──────────────────────────────
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: isMobile ? 200 : 280,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              state.consentText.isNotEmpty
                                  ? state.consentText
                                  : 'Please read and acknowledge the consent form.',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                height: 1.65,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Bottom section ───────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad),
                    child: isMobile
                        ? _buildMobileBottom(type, isSigning)
                        : _buildTabletBottom(type, isSigning),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tablet layout ────────────────────────────────────────────────────────────
  // Left: input section  |  Right: Email me + buttons

  Widget _buildTabletBottom(String type, bool isSigning) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(flex: 5, child: _buildInputSection(type, isMobile: false)),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmailCheckbox(),
              const SizedBox(height: 20),
              _buildButtons(isSigning, isMobile: false),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────────
  // Stacked: input → Email me → buttons

  Widget _buildMobileBottom(String type, bool isSigning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputSection(type, isMobile: true),
        const SizedBox(height: 12),
        _buildEmailCheckbox(),
        const SizedBox(height: 16),
        _buildButtons(isSigning, isMobile: true),
      ],
    );
  }

  // ── Input section (varies by signing method) ──────────────────────────────────

  Widget _buildInputSection(String type, {required bool isMobile}) {
    if (type == 'TYPED_NAME') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type Your Name',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          8.vs,
          TextField(
            controller: _typedNameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Full name',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE12242), width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (type == 'CHECKBOX_ONLY') {
      return Row(
        children: [
          Checkbox(
            value: _checkboxAgreed,
            activeColor: const Color(0xFFE12242),
            onChanged: (v) => setState(() => _checkboxAgreed = v ?? false),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'I accept the terms and conditions',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }

    // SIGNATURE_IMAGE — draw pad
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign Here',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        8.vs,
        Container(
          height: isMobile ? 130 : 155,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hasSignature
                  ? const Color(0xFFE12242)
                  : const Color(0xFFD7D7DA),
              width: _hasSignature ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              children: [
                Signature(
                  controller: _sigController,
                  backgroundColor: Colors.white,
                ),
                if (!_hasSignature)
                  const Center(
                    child: Text(
                      'Draw your signature here',
                      style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Clear link below pad
        GestureDetector(
          onTap: () {
            _sigController.clear();
            setState(() => _hasSignature = false);
          },
          child: const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 13, color: Color(0xFF888888)),
                SizedBox(width: 4),
                Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Email me checkbox ─────────────────────────────────────────────────────────

  Widget _buildEmailCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _emailMe,
            activeColor: const Color(0xFFE12242),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => setState(() => _emailMe = v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        const Text('Email me', style: TextStyle(fontSize: 14)),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────────

  Widget _buildButtons(bool isSigning, {required bool isMobile}) {
    final confirmBtn = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE12242),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFBDBDBD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        elevation: 0,
      ),
      onPressed: (_canConfirm && !isSigning) ? _confirm : null,
      child: isSigning
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
    );

    final cancelBtn = OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE12242), width: 1.5),
        foregroundColor: const Color(0xFFE12242),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      ),
      onPressed: isSigning ? null : () => Navigator.of(context).pop(),
      child: const Text(
        'Cancel',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );

    if (isMobile) {
      return Row(
        children: [
          Expanded(child: cancelBtn),
          const SizedBox(width: 12),
          Expanded(child: confirmBtn),
        ],
      );
    }

    // Tablet: right-aligned fixed-width
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(width: 130, child: cancelBtn),
        const SizedBox(width: 12),
        SizedBox(width: 130, child: confirmBtn),
      ],
    );
  }
}
