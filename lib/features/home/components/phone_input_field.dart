import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class PhoneInputField extends HookWidget {
  final TextEditingController controller;
  final String? initialCountryCode;
  final Function(PhoneNumber) onChanged;
  final String? errorText;
  final bool enabled;
  final FocusNode? focusNode;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.initialCountryCode,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    // State for selected country code
    final selectedCountryCode = useState(initialCountryCode ?? 'ID');

    // Controller for the IntlPhoneField
    final phoneFieldController = useTextEditingController();

    // إنشاء focusNode افتراضي إذا لم يتم تمريره
    final defaultFocusNode = useFocusNode();
    final effectiveFocusNode = focusNode ?? defaultFocusNode;

    // Reference to the IntlPhoneField key
    final phoneFieldKey = GlobalKey<FormFieldState>();

    // Function to parse full phone number with country code
    void parseFullPhoneNumber(String fullNumber) {
      if (fullNumber.isEmpty) return;

      String numberToCheck = fullNumber.trim();

      // Add + if it doesn't start with one
      if (!numberToCheck.startsWith('+')) {
        numberToCheck = '+$numberToCheck';
      }

      // Try to match country code
      for (final country in countries) {
        final countryDialCode = '+${country.dialCode}';
        if (numberToCheck.startsWith(countryDialCode)) {
          // Extract phone number without country code
          final phoneNumber = numberToCheck.substring(countryDialCode.length);

          // Update UI
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Set country code
            selectedCountryCode.value = country.code;

            // Update text field with phone number only (without country code)
            phoneFieldController.text = phoneNumber;

            // Notify parent about the change
            final completePhoneNumber = PhoneNumber(
              countryISOCode: country.code,
              countryCode: country.dialCode,
              number: phoneNumber,
            );
            onChanged(completePhoneNumber);

            // استعادة التركيز بعد تحديث البيانات
            effectiveFocusNode.requestFocus();
          });

          return;
        }
      }
    }

    // Check initial value
    useEffect(() {
      animationController.forward();

      // Check if controller has initial value
      if (controller.text.isNotEmpty) {
        parseFullPhoneNumber(controller.text);
        controller.clear(); // Clear original controller to avoid duplication
      }

      return () {
        animationController.dispose();
      };
    }, []);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
              child: Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: IntlPhoneField(
                key: phoneFieldKey,
                controller: phoneFieldController,
                focusNode: effectiveFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.green.shade400,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  errorStyle: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data != null && data.text != null) {
                        parseFullPhoneNumber(data.text!);
                        // استعادة التركيز بعد لصق الرقم
                        effectiveFocusNode.requestFocus();
                      }
                    },
                    tooltip: 'Paste phone number',
                  ),
                ),
                initialCountryCode: selectedCountryCode.value,
                invalidNumberMessage: errorText,
                disableLengthCheck: true,
                enabled: enabled,
                onChanged: (phone) {
                  // حافظ على التركيز بعد التغيير
                  effectiveFocusNode.requestFocus();
                  onChanged(phone);
                },
                onCountryChanged: (country) {
                  selectedCountryCode.value = country.code;
                  // حافظ على التركيز بعد تغيير الدولة
                  effectiveFocusNode.requestFocus();
                },
                dropdownTextStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 12),
                dropdownIconPosition: IconPosition.trailing,
                showDropdownIcon: true,
                dropdownIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
                flagsButtonMargin: const EdgeInsets.only(right: 8),
                showCountryFlag: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      parseFullPhoneNumber(data.text!);
                      // استعادة التركيز بعد لصق الرقم
                      effectiveFocusNode.requestFocus();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.content_paste_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'Paste Full Number',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
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
