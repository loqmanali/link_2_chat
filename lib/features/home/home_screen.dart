import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:link_2_chat/widgets/sync_status_widget.dart';

import '../../core/services/sync_service.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/sync_status_indicator.dart';
import 'components/action_buttons.dart';
import 'components/link_result_card.dart';
import 'components/phone_input_field.dart';
import 'components/qr_code_widget.dart';
import 'home_viewmodel.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create the bloc outside of BlocProvider to control its lifecycle
    final homeBloc = useMemoized(() => HomeBloc(), []);
    final focusNode = useFocusNode();

    // Animation controllers for various elements
    final headerAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
      initialValue: 0,
    );

    final inputFieldAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
      initialValue: 0,
    );

    final buttonsAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
      initialValue: 0,
    );

    // Animations
    final headerAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: headerAnimationController,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    final inputFieldAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: inputFieldAnimationController,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    final buttonsAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: buttonsAnimationController,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    // Animation controllers for result card and QR code
    final resultCardAnimController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    final qrCodeAnimController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    // Start animations sequentially
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 100), () {
        headerAnimationController.forward();
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        inputFieldAnimationController.forward();
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        buttonsAnimationController.forward();
      });

      return () {
        // Clean up resources when widget is disposed
        focusNode.dispose();
        headerAnimationController.dispose();
        inputFieldAnimationController.dispose();
        buttonsAnimationController.dispose();
        resultCardAnimController.dispose();
        qrCodeAnimController.dispose();
      };
    }, []);

    return BlocProvider(
      create: (_) => homeBloc,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          // Reset and start animations when state changes
          if (state.generatedLink != null && !state.isShowingQr) {
            resultCardAnimController.reset();
            resultCardAnimController.forward();
          }

          if (state.isShowingQr && state.generatedLink != null) {
            qrCodeAnimController.reset();
            qrCodeAnimController.forward();
          }

          return LoadingOverlay(
            isLoading: state.isLoading,
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              appBar: const CustomAppBar(),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, const Color(0xFFF5F7FA)],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with animation
                      Transform.translate(
                        offset: Offset(0, 20 * (1 - headerAnimation)),
                        child: Opacity(
                          opacity: headerAnimation,
                          child: _buildHeader(),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Phone input field with animation
                      Transform.translate(
                        offset: Offset(0, 20 * (1 - inputFieldAnimation)),
                        child: Opacity(
                          opacity: inputFieldAnimation,
                          child: PhoneInputField(
                            controller: homeBloc.phoneController,
                            focusNode: focusNode,
                            errorText: state.errorMessage,
                            onChanged: (PhoneNumber phoneNumber) {
                              homeBloc.add(
                                PhoneNumberChangedEvent(phoneNumber),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action buttons with animation
                      Transform.translate(
                        offset: Offset(0, 20 * (1 - buttonsAnimation)),
                        child: Opacity(
                          opacity: buttonsAnimation,
                          child: ActionButtons(
                            isEnabled: state.isValidNumber,
                            onWhatsAppPressed: () {
                              homeBloc.add(GenerateWhatsAppLinkEvent());
                              focusNode.unfocus();
                            },
                            onTelegramPressed: () {
                              homeBloc.add(GenerateTelegramLinkEvent());
                              focusNode.unfocus();
                            },
                            onQrPressed: () {
                              if (state.generatedLink != null) {
                                homeBloc.add(
                                  ShowQrCodeEvent(state.currentPlatform!),
                                );
                              } else if (state.isValidNumber) {
                                homeBloc.add(GenerateWhatsAppLinkEvent());
                                homeBloc.add(ShowQrCodeEvent('whatsapp'));
                              }
                              focusNode.unfocus();
                            },
                          ),
                        ),
                      ),

                      // Result card with animation
                      if (state.generatedLink != null && !state.isShowingQr)
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: resultCardAnimController,
                                curve: Curves.easeOutQuart,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 28),
                              child: LinkResultCard(
                                link: state.generatedLink!,
                                platform: state.currentPlatform!,
                                onQrPressed: () {
                                  homeBloc.add(
                                    ShowQrCodeEvent(state.currentPlatform!),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                      // QR code widget with animation
                      if (state.isShowingQr && state.generatedLink != null)
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: qrCodeAnimController,
                                curve: Curves.easeOutQuart,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 28),
                              child: QrCodeWidget(
                                data: state.generatedLink!,
                                title:
                                    '${state.currentPlatform == "whatsapp" ? "WhatsApp" : "Telegram"} QR Code',
                                qrKey: homeBloc.qrKey,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Sync status with animation
                      AnimatedOpacity(
                        opacity: headerAnimation,
                        duration: const Duration(milliseconds: 500),
                        child: SyncStatusIndicator(
                          status: SyncStatus(
                            lastSyncTime: DateTime.now(),
                            isOnline: true,
                            message: 'Syncing...',
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sync status widget with animation
                      AnimatedOpacity(
                        opacity: headerAnimation,
                        duration: const Duration(milliseconds: 500),
                        child: SyncStatusWidget(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAnimatedIcon(),
          const SizedBox(height: 24),
          const Text(
            'Convert Phone Numbers to Chat Links',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter a phone number to create instant chat links for WhatsApp and Telegram',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return HookBuilder(
      builder: (context) {
        final animationController = useAnimationController(
          duration: const Duration(seconds: 2),
        );

        final rotationAnimation = useAnimation(
          Tween<double>(begin: 0, end: 0.05).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Curves.easeInOut,
            ),
          ),
        );

        final scaleAnimation = useAnimation(
          Tween<double>(begin: 1.0, end: 1.1).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Curves.easeInOut,
            ),
          ),
        );

        useEffect(() {
          animationController.repeat(reverse: true);
          return animationController.dispose;
        }, []);

        return Transform.rotate(
          angle: rotationAnimation,
          child: Transform.scale(
            scale: scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const LoadingIndicator(message: 'Generating link...'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
