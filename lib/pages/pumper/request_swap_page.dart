import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../models/swap_request_model.dart';
import '../../models/user_model.dart';
import '../../services/swap_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class RequestSwapPage extends StatefulWidget {
  final UserModel user;
  final ShiftModel myShift; // The shift the pumper wants to swap away

  const RequestSwapPage({super.key, required this.user, required this.myShift});

  @override
  State<RequestSwapPage> createState() => _RequestSwapPageState();
}

class _RequestSwapPageState extends State<RequestSwapPage> {
  final SwapService _swapService = SwapService();

  List<ShiftModel> _shiftsOnDate = [];
  ShiftModel? _selectedTargetShift;
  bool _isLoadingShifts = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadShiftsOnDate();
  }

  void _loadShiftsOnDate() async {
    final shifts = await _swapService.getShiftsOnDate(widget.myShift.date);
    setState(() {
      // Exclude the current pumper's own shift from the list
      _shiftsOnDate = shifts
          .where(
            (s) => s.pumperId != widget.user.uid && s.id != widget.myShift.id,
          )
          .toList();
      _isLoadingShifts = false;
    });
  }

  void _sendRequest() async {
    if (_selectedTargetShift == null) {
      showCustomSnackBar(
        context,
        "Please select a pumper to swap with.",
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);

    final request = SwapRequestModel(
      requesterId: widget.user.uid,
      requesterName: "${widget.user.firstName} ${widget.user.lastName}",
      targetId: _selectedTargetShift!.pumperId,
      targetName: _selectedTargetShift!.pumperName,
      requesterShiftId: widget.myShift.id!,
      targetShiftId: _selectedTargetShift!.id!,
      requesterShiftType: widget.myShift.shiftType,
      targetShiftType: _selectedTargetShift!.shiftType,
      requesterPump: widget.myShift.pumpNumber,
      targetPump: _selectedTargetShift!.pumpNumber,
      swapDate: widget.myShift.date,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final result = await _swapService.sendSwapRequest(request);
    if (mounted) setState(() => _isSending = false);

    if (result == null) {
      showCustomSnackBar(context, "Swap request sent!");
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      showCustomSnackBar(context, result, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "REQUEST SHIFT SWAP",
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
                  // YOUR SHIFT CARD
                  _buildLabel("YOUR SHIFT"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: _buildShiftCard(widget.myShift, isHighlighted: true),
                  ),

                  const SizedBox(height: 10),
                  Center(
                    child: Icon(
                      Icons.swap_vert,
                      color: AppColors.primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // PICK WHO TO SWAP WITH
                  Center(
                    child: _buildLabel(
                      "SELECT PUMPER TO SWAP WITH  —  ${DateFormat('dd MMM yyyy').format(widget.myShift.date)}",
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (_isLoadingShifts)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    )
                  else if (_shiftsOnDate.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          "No other pumpers are scheduled\non this date.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _shiftsOnDate.map((shift) {
                        final isSelected = _selectedTargetShift?.id == shift.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTargetShift = shift),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGreen.withOpacity(0.12)
                                  : AppColors.surface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.white10,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: _buildShiftCard(
                              shift,
                              showSelector: true,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 5),

                  // SWAP SUMMARY
                  if (_selectedTargetShift != null) ...[
                    _buildLabel("SWAP SUMMARY"),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSwapRow(
                            "You give up",
                            "${widget.myShift.shiftType} • ${widget.myShift.pumpNumber}",
                          ),
                          const Divider(color: Colors.white10, height: 20),
                          _buildSwapRow(
                            "You receive",
                            "${_selectedTargetShift!.shiftType} • ${_selectedTargetShift!.pumpNumber}",
                          ),
                          const Divider(color: Colors.white10, height: 20),
                          _buildSwapRow(
                            "Swap with",
                            _selectedTargetShift!.pumperName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  FuelButton(
                    text: "SEND SWAP REQUEST",
                    isLoading: _isSending,
                    onPressed: _sendRequest,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ],
  );

  Widget _buildShiftCard(
    ShiftModel shift, {
    bool isHighlighted = false,
    bool showSelector = false,
    bool isSelected = false,
  }) {
    final isDay = shift.shiftType == "Day Shift";
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDay
              ? Colors.amber.withOpacity(0.1)
              : Colors.indigo.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDay ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
          color: isDay ? Colors.amber : Colors.indigo[300],
          size: 20,
        ),
      ),
      title: Text(
        shift.pumperName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        shift.shiftType,
        style: const TextStyle(color: AppColors.textDim, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.2),
              ),
            ),
            child: Text(
              shift.pumpNumber.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          if (showSelector) ...[
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryGreen : AppColors.textDim,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

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
