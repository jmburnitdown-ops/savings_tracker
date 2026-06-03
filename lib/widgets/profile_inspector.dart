import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../providers/savings_provider.dart';

class ProfileInspector extends StatefulWidget {
  final bool isBottomSheet;
  final VoidCallback? onClose;
  const ProfileInspector({super.key, required this.isBottomSheet, this.onClose});

  @override
  State<ProfileInspector> createState() => _ProfileInspectorState();
}

class _ProfileInspectorState extends State<ProfileInspector> with TickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _profileBirthday;
  String? _photoBase64;
  Uint8List? _photoBytes;
  bool _isSavingProfile = false;
  bool _isLoadingProfile = true;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoController.forward();
    _loadProfileData();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile data when dependencies change (e.g., when provider updates)
    _loadProfileData();
  }

  void _loadProfileData() {
    // First try to get data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Reload from Firebase to ensure we have the latest data
        await Provider.of<SavingsProvider>(context, listen: false)
            .loadUserProfileFromFirebase(currentUser.uid);
      }
      
      if (!mounted) return;
      
      final currentProfile = Provider.of<SavingsProvider>(context, listen: false).userProfile;
      
      setState(() {
        _isLoadingProfile = false;
        // Load the actual profile fields from Firebase data
        if (currentProfile.firstName != null && currentProfile.firstName!.isNotEmpty) {
          _firstNameController.text = currentProfile.firstName!;
        }
        if (currentProfile.middleName != null && currentProfile.middleName!.isNotEmpty) {
          _middleNameController.text = currentProfile.middleName!;
        }
        if (currentProfile.lastName != null && currentProfile.lastName!.isNotEmpty) {
          _lastNameController.text = currentProfile.lastName!;
        }
        if (currentProfile.birthday != null) {
          _profileBirthday = currentProfile.birthday;
        }
        
        if (currentProfile.profileImageBase64 != null) {
          _photoBase64 = currentProfile.profileImageBase64;
          _photoBytes = base64Decode(_photoBase64!);
        }
      });
    });
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('About ApexSaver'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ApexSaver Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent)),
              const SizedBox(height: 2),
              const Text('v1.0.0 | Desktop Application', style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 10),
              const Text('A professional savings tracking app to manage goals, track deposits, visualize progress, and achieve financial milestones.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              const Text('• User authentication & profile management\n• Multiple savings goals with deadlines\n• Real-time progress tracking\n• Gamification with milestones\n• Multi-currency support\n• Image cropping tools', style: TextStyle(fontSize: 11)),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Built With', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              const Text('Flutter & Dart • Firebase • Hive DB\nFL Chart • Provider State Management', style: TextStyle(fontSize: 11)),
              const SizedBox(height: 10),
              const Text('Platforms: Windows • macOS • iOS • Android • Web', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Developer: John Mark M. Bangud', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
              const Text('GitHub: jmburnitdown-ops', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('© 2026 ApexSaver Studio', style: TextStyle(fontSize: 10, color: Colors.white38)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndCropProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
    if (image != null) {
      final rawBytes = await image.readAsBytes();
      if (!mounted) return;

      final Uint8List? croppedBytes = await showDialog<Uint8List?>(
        context: context,
        builder: (context) => ManualCropDialog(imageBytes: rawBytes),
      );

      if (croppedBytes != null) {
        setState(() {
          _photoBytes = croppedBytes;
          _photoBase64 = base64Encode(croppedBytes);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool buildWideLayout = constraints.maxWidth > 600;

        Widget inputFormGrid = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (buildWideLayout) ...[
              Row(
                children: [
                  Expanded(child: TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _middleNameController, decoration: const InputDecoration(labelText: 'Middle Name (Optional)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54), alignment: Alignment.centerLeft),
                      icon: const Icon(Icons.cake, color: Colors.redAccent),
                      label: Text(_profileBirthday == null ? 'Select Birthday (Optional)' : '${_profileBirthday!.month}/${_profileBirthday!.day}/${_profileBirthday!.year}'),
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: _profileBirthday ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                        if (picked != null) setState(() => _profileBirthday = picked);
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _middleNameController, decoration: const InputDecoration(labelText: 'Middle Name (Optional)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft),
                icon: const Icon(Icons.cake, color: Colors.redAccent),
                label: Text(_profileBirthday == null ? 'Select Birthday (Optional)' : 'Birthday: ${_profileBirthday!.month}/${_profileBirthday!.day}/${_profileBirthday!.year}'),
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: _profileBirthday ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                  if (picked != null) setState(() => _profileBirthday = picked);
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _isSavingProfile ? null : () async {
                  setState(() => _isSavingProfile = true);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    final fName = _firstNameController.text.trim();
                    final mName = _middleNameController.text.trim();
                    final lName = _lastNameController.text.trim();
                    
                    // Save to Firebase
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
                        'firstName': fName,
                        'middleName': mName,
                        'lastName': lName,
                        'birthday': _profileBirthday != null ? Timestamp.fromDate(_profileBirthday!) : null,
                        'profileImageBase64': _photoBase64,
                      });
                    }

                    if (!mounted) return;

                    // Update the provider with the new data
                    String compoundName = fName.isEmpty ? "Apex User" : fName;
                    if (mName.isNotEmpty) compoundName += " $mName";
                    if (lName.isNotEmpty) compoundName += " $lName";

                    final updatedProfileModel = UserProfile(
                      username: compoundName,
                      profileImageBase64: _photoBase64,
                      firstName: fName.isNotEmpty ? fName : null,
                      middleName: mName.isNotEmpty ? mName : null,
                      lastName: lName.isNotEmpty ? lName : null,
                      birthday: _profileBirthday,
                    );

                    provider.updateProfile(updatedProfileModel);

                    setState(() => _isSavingProfile = false);
                    messenger.showSnackBar(const SnackBar(content: Text('Profile details updated successfully!')));
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isSavingProfile = false);
                      messenger.showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
                    }
                  }
                },
                child: _isSavingProfile 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Profile Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );

        Widget accountStatsSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${provider.goals.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      Text('Active Goals', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('₱${provider.goals.fold<double>(0, (sum, goal) => sum + goal.currentSavings).toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      Text('Total Saved', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        Widget accountInfoSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Account Created:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Text(FirebaseAuth.instance.currentUser?.metadata.creationTime?.toString().split(' ').first ?? 'N/A',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Email:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Text(FirebaseAuth.instance.currentUser?.email ?? 'N/A',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        Widget accountActionsSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                      content: const Text('Are you sure? This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance.currentUser?.delete();
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );

        Widget mainProfileColumn = Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Account Profile Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        tooltip: 'About This App',
                        onPressed: _showAboutAppDialog,
                      ),
                      if (widget.onClose != null)
                        IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
                          tooltip: 'Close Profile',
                          onPressed: widget.onClose,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (buildWideLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickAndCropProfileImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            backgroundImage: _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                            child: _photoBytes == null ? Icon(Icons.person, size: 55, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
                          ),
                          Positioned(bottom: 4, right: 4, child: CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary, child: Icon(Icons.edit, size: 14, color: Theme.of(context).colorScheme.onPrimary))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: inputFormGrid),
                  ],
                )
              else ...[
                Center(
                  child: GestureDetector(
                    onTap: _pickAndCropProfileImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                          backgroundImage: _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                          child: _photoBytes == null ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
                        ),
                        Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary, child: Icon(Icons.camera_alt, size: 14, color: Theme.of(context).colorScheme.onPrimary))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                inputFormGrid,
              ],
              const SizedBox(height: 32),
              Divider(color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              accountStatsSection,
              accountInfoSection,
              accountActionsSection,
            ],
          ),
        );

        if (_isLoadingProfile) {
          return widget.isBottomSheet 
            ? const Center(child: CircularProgressIndicator())
            : const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return widget.isBottomSheet ? mainProfileColumn : SingleChildScrollView(child: mainProfileColumn);
      },
    );
  }
}

class ManualCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const ManualCropDialog({super.key, required this.imageBytes});

  @override
  State<ManualCropDialog> createState() => _ManualCropDialogState();
}

class _ManualCropDialogState extends State<ManualCropDialog> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Position & Scale (1:1)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 240,
              height: 240, 
              color: Colors.black,
              child: GestureDetector(
                onPanUpdate: (details) => setState(() => _offset += details.delta),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: _offset,
                      child: Transform.scale(scale: _scale, child: Image.memory(widget.imageBytes, fit: BoxFit.contain)),
                    ),
                    Container(decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 2.5))),
                  ],
                ),
              ),
            ),
          ),
          Slider(
            value: _scale,
            min: 1.0,
            max: 4.0,
            activeColor: Colors.red,
            onChanged: (val) => setState(() => _scale = val),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, widget.imageBytes),
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
