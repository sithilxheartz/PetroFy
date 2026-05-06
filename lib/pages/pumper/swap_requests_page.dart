import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/swap_request_model.dart';
import '../../models/user_model.dart';
import '../../services/swap_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class SwapRequestsPage extends StatelessWidget {
  final UserModel user;
  const SwapRequestsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final SwapService swapService = SwapService();

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "SWAP REQUESTS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INCOMING REQUESTS
                  _buildLabel("INCOMING REQUESTS"),
                  const SizedBox(height: 10),
                  StreamBuilder<List<SwapRequestModel>>(
                    stream: swapService.getIncomingRequests(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      final requests = snapshot.data ?? [];
                      if (requests.isEmpty) {
                        return _buildEmptyBox("No incoming swap requests");
                      }
                      return Column(
                        children: requests
                            .map(
                              (r) =>
                                  _buildIncomingCard(context, r, swapService),
                            )
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // OUTGOING REQUESTS
                  _buildLabel("SENT REQUESTS"),
                  const SizedBox(height: 10),
                  StreamBuilder<List<SwapRequestModel>>(
                    stream: swapService.getOutgoingRequests(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      final requests = snapshot.data ?? [];
                      if (requests.isEmpty) {
                        return _buildEmptyBox("No pending sent requests");
                      }
                      return Column(
                        children: requests
                            .map((r) => _buildOutgoingCard(r))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card for INCOMING requests — has Accept/Reject buttons
  Widget _buildIncomingCard(
    BuildContext context,
    SwapRequestModel r,
    SwapService service,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text(
                r.requesterName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM').format(r.swapDate),
                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // What they're offering
          Row(
            children: [
              Expanded(
                child: _buildShiftChip(
                  label: "They give",
                  shift: r.requesterShiftType,
                  pump: r.requesterPump,
                  color: Colors.orange,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.compare_arrows,
                  color: AppColors.textDim,
                  size: 18,
                ),
              ),
              Expanded(
                child: _buildShiftChip(
                  label: "You give",
                  shift: r.targetShiftType,
                  pump: r.targetPump,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Accept / Reject buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final result = await service.rejectSwap(r.id!);
                    if (context.mounted) {
                      showCustomSnackBar(
                        context,
                        result ?? "Swap request rejected.",
                        isError: result != null,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text(
                    "REJECT",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final result = await service.acceptSwap(r);
                    if (context.mounted) {
                      showCustomSnackBar(
                        context,
                        result ?? "Swap accepted! Shifts updated.",
                        isError: result != null,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: const Text(
                    "ACCEPT",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card for OUTGOING requests — just shows status
  Widget _buildOutgoingCard(SwapRequestModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.textDim, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Swap request to ${r.targetName}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "${r.requesterShiftType} • ${r.requesterPump}  →  ${r.targetShiftType} • ${r.targetPump}",
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Text(
              "PENDING",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftChip({
    required String label,
    required String shift,
    required String pump,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            shift,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            pump,
            style: const TextStyle(color: AppColors.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String message) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.3),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
      ),
    ),
  );

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.primaryGreen,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
  );
}
