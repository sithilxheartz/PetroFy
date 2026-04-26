import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  // Target audience selection
  String _selectedTarget = "all";

  final List<Map<String, dynamic>> _targets = [
    {
      "label": "All Users",
      "value": "all",
      "icon": Icons.groups_rounded,
      "desc": "Customers, Pumpers & Admins",
    },
    {
      "label": "Customers Only",
      "value": "customer",
      "icon": Icons.person_rounded,
      "desc": "Shop & fuel customers",
    },
    {
      "label": "Pumpers Only",
      "value": "pumper",
      "icon": Icons.local_gas_station_rounded,
      "desc": "All fuel pumpers",
    },
  ];

  // Recent notifications stream
  final Stream<QuerySnapshot> _recentStream = FirebaseFirestore.instance
      .collection('adminNotifications')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots();

  Future<void> _handleSend() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      showCustomSnackBar(
        context,
        "Title and message are required",
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Writing to Firestore triggers the Cloud Function automatically
      await FirebaseFirestore.instance.collection('adminNotifications').add({
        'title': title,
        'body': body,
        'targetRole': _selectedTarget,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _bodyController.clear();

      if (mounted) {
        showCustomSnackBar(context, "✅ Notification sent successfully!");
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, "Error: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "SEND NOTIFICATION",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlow(AppColors.primaryGreen),
          ),


          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Compose Card ──
                  _buildSectionLabel("COMPOSE MESSAGE"),
                  const SizedBox(height: 10),
                  _buildComposeCard(),

                  const SizedBox(height: 20),

                  // ── Target Audience ──
                  _buildSectionLabel("SELECT AUDIENCE"),
                  const SizedBox(height: 10),
                  _buildAudiencePicker(),

                  const SizedBox(height: 20),

                  // ── Preview Card ──
                  _buildSectionLabel("NOTIFICATION PREVIEW"),
                  const SizedBox(height: 10),
                  _buildPreviewCard(),

                  const SizedBox(height: 20),

                  // ── Send Button ──
                  FuelButton(
                    text: "BROADCAST NOTIFICATION",
                    isLoading: _isSending,
                    onPressed: _handleSend,
                  ),

                  const SizedBox(height: 30),

                  // ── Recent Notifications ──
                  _buildSectionLabel("RECENT BROADCASTS"),
                  const SizedBox(height: 10),
                  _buildRecentList(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Title field
          TextField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: "Notification Title",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              prefixIcon: const Icon(
                Icons.title_rounded,
                color: AppColors.primaryGreen,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 15,
              ),
              border: InputBorder.none,
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Body field
          TextField(
            controller: _bodyController,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Write your message here...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(
                  Icons.message_rounded,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 15,
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudiencePicker() {
    return Row(
      children: _targets.map((target) {
        final bool isSelected = _selectedTarget == target['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTarget = target['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withOpacity(0.15)
                    : AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.white10,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    target['icon'] as IconData,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.textDim,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    target['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    target['desc'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard() {
    final title = _titleController.text.isEmpty
        ? "Your Title Here"
        : _titleController.text;
    final body = _bodyController.text.isEmpty
        ? "Your message will appear here..."
        : _bodyController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_gas_station,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Petrofy",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      "now",
                      style: TextStyle(color: AppColors.textDim, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _recentStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text(
                "No broadcasts yet",
                style: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool isSent = data['status'] == 'sent';
            final int success = data['successCount'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSent ? AppColors.primaryGreen : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['body'] ?? '',
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Target badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data['targetRole']?.toUpperCase() ?? 'ALL',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(height: 4),
                        Text(
                          "$success sent",
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.primaryGreen,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.05),
      ),
    );
  }
}