import 'package:flutter/material.dart';
import '../../models/pumper_preference_model.dart';
import '../../models/user_model.dart';
import '../../services/preference_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class PreferencesPage extends StatefulWidget {
  final UserModel user;
  const PreferencesPage({super.key, required this.user});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final PreferenceService _service = PreferenceService();

  // Form state
  String _preferredShift = "No Preference";
  bool _allowConsecutive = false;
  int _maxShiftsPerWeek = 5;
  List<int> _daysOff = [];
  List<String> _preferredPumps = [];
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isFetching = true;

  // Options
  final List<String> _pumps = [
    "Petrol 01",
    "Petrol 02",
    "Diesel 01",
    "Diesel 02",
    "Super Petrol",
    "Super Diesel",
  ];
  final List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  // Load existing preferences when page opens
  void _loadExistingPreferences() async {
    final prefs = await _service.getPreferences(widget.user.uid);
    if (prefs != null && mounted) {
      setState(() {
        _preferredShift = prefs.preferredShift;
        _allowConsecutive = prefs.allowConsecutiveShifts;
        _maxShiftsPerWeek = prefs.maxShiftsPerWeek;
        _daysOff = List.from(prefs.daysOff);
        _preferredPumps = List.from(prefs.preferredPumps);
        _isAvailable = prefs.isAvailable;
      });
    }
    if (mounted) setState(() => _isFetching = false);
  }

  void _savePreferences() async {
    setState(() => _isLoading = true);

    final prefs = PumperPreferenceModel(
      pumperId: widget.user.uid,
      preferredShift: _preferredShift,
      allowConsecutiveShifts: _allowConsecutive,
      maxShiftsPerWeek: _maxShiftsPerWeek,
      daysOff: _daysOff,
      preferredPumps: _preferredPumps,
      isAvailable: _isAvailable,
    );

    final result = await _service.savePreferences(prefs);
    if (mounted) setState(() => _isLoading = false);

    if (result == null) {
      showCustomSnackBar(context, "Preferences saved!");
    } else {
      showCustomSnackBar(context, result, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        title: const Text(
          "SHIFT PREFERENCES",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
          ),
        ),
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
                  // AVAILABILITY TOGGLE
                  _buildSectionLabel("AVAILABILITY"),
                  const SizedBox(height: 10),
                  _buildGlassBox(
                    child: SwitchListTile(
                      title: const Text(
                        "Available for Scheduling",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _isAvailable
                            ? "You will be included in auto-scheduling"
                            : "You will be excluded from scheduling",
                        style: TextStyle(
                          color: _isAvailable
                              ? AppColors.primaryGreen
                              : Colors.red[300],
                          fontSize: 11,
                        ),
                      ),
                      value: _isAvailable,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (v) => setState(() => _isAvailable = v),
                    ),
                  ),
            
              const SizedBox(height: 15),
            
                  // PREFERRED SHIFT
                  _buildSectionLabel("PREFERRED SHIFT"),
                  const SizedBox(height: 10),
                  Row(
                    children: ["Day Shift", "No Preference", "Night Shift"].map((
                      shift,
                    ) {
                      bool selected = _preferredShift == shift;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _preferredShift = shift),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryGreen.withOpacity(0.15)
                                  : AppColors.surface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryGreen
                                    : Colors.white10,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  shift == "Day Shift"
                                      ? Icons.wb_sunny_outlined
                                      : shift == "Night Shift"
                                      ? Icons.nights_stay_outlined
                                      : Icons.swap_horiz,
                                  color: selected
                                      ? AppColors.primaryGreen
                                      : AppColors.textDim,
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  shift.replaceAll(" ", "\n"),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textDim,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            
                  const SizedBox(height: 20),
            
                  // MAX SHIFTS PER WEEK
                  _buildSectionLabel(
                    "MAX SHIFTS PER WEEK  —  $_maxShiftsPerWeek",
                  ),
                  Slider(
                    value: _maxShiftsPerWeek.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    activeColor: AppColors.primaryGreen,
                    inactiveColor: AppColors.surface,
                    label: _maxShiftsPerWeek.toString(),
                    onChanged: (v) =>
                        setState(() => _maxShiftsPerWeek = v.toInt()),
                  ),
            
              const SizedBox(height: 10),
                  _buildGlassBox(
                    child: SwitchListTile(
                      title: const Text(
                        "Allow Back-to-Back Shifts",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Work both Day & Night on the same day",
                        style: TextStyle(color: AppColors.textDim, fontSize: 11),
                      ),
                      value: _allowConsecutive,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (v) => setState(() => _allowConsecutive = v),
                    ),
                  ),
            
              const SizedBox(height: 15),
            
                  // DAYS OFF
                  _buildSectionLabel("PREFERRED DAYS OFF"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (i) {
                      bool selected = _daysOff.contains(i);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected ? _daysOff.remove(i) : _daysOff.add(i);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.red.withOpacity(0.15)
                                : AppColors.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Colors.red.shade300
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            _days[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.red[300]
                                  : AppColors.textDim,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
            
                            const SizedBox(height: 15),
            
                  // PREFERRED PUMPS
                  _buildSectionLabel("PREFERRED PUMPS"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pumps.map((pump) {
                      bool selected = _preferredPumps.contains(pump);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected
                              ? _preferredPumps.remove(pump)
                              : _preferredPumps.add(pump);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryGreen.withOpacity(0.15)
                                : AppColors.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryGreen
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            pump,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.primaryGreen
                                  : AppColors.textDim,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            
                  const SizedBox(height: 20),
            
                  // SAVE BUTTON
                  FuelButton(
                    text: "SAVE PREFERENCES",
                    isLoading: _isLoading,
                    onPressed: _savePreferences,
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

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryGreen,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _buildGlassBox({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.8),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
    ),
    child: child,
  );
}
