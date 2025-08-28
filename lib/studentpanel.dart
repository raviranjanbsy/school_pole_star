import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/ui/student_class_dashboard.dart';
import 'package:school_management/ui/change_password_dialog.dart';
import 'package:school_management/providers/home_stream_provider.dart';
import 'package:school_management/utils/logout_helper.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'dart:math';

class StudentPanel extends ConsumerStatefulWidget {
  final Alluser currentUser;

  const StudentPanel({super.key, required this.currentUser});

  @override
  ConsumerState<StudentPanel> createState() => _StudentPanelState();
}

class _StudentPanelState extends ConsumerState<StudentPanel> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late Future<StudentTable> _studentProfileFuture;
  Future<SchoolClass?>? _classDetailsFuture;
  int _selectedIndex = 1; // Default to Home tab
  StudentTable? _currentStudentProfile; // Make it mutable
  bool _isEditingProfile = false; // New state variable for edit mode
  File? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadStudentProfile() {
    // Get the currently authenticated Firebase user to fetch the detailed profile.
    final firebaseUser = _authService.getAuth().currentUser;
    if (firebaseUser == null) {
      // Handle case where user is not logged in, though they shouldn't reach this screen.
      // You could pop the route or show an error.
      setState(() {
        _studentProfileFuture = Future.error("User not authenticated.");
      });
      return;
    }

    _studentProfileFuture = _authService.getOrCreateStudentProfile(
      firebaseUser,
      widget.currentUser,
    );

    // Once the profile is loaded, check for a class and load its details.
    _studentProfileFuture.then((studentProfile) {
      setState(() {
        _currentStudentProfile = studentProfile;
      });
      final classId = studentProfile.classId;
      if (classId != null && classId.isNotEmpty) {
        setState(() {
          _classDetailsFuture = _authService.fetchSchoolClassById(classId);
        });
      }
    }).catchError((_) {
      // Handle errors from fetching the profile if necessary
    });
  }

  void _refreshAllData() {
    setState(() {
      _loadStudentProfile();
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _logout() async {
    // Use the reusable logout helper
    await showLogoutConfirmationDialog(context, ref);
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadImageFile(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${_authService.getAuth().currentUser!.uid}.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<String?> _uploadImageBytes(Uint8List imageBytes) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${_authService.getAuth().currentUser!.uid}.jpg');
      await storageRef.putData(imageBytes);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "POLE STAR ACADEMY -",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                "SONITPUR ASSAM",
                style: TextStyle(color: Colors.green, fontSize: 20),
              ),
            ],
          ),
          leading: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
                'images/school_logo.png'), // Using consistent logo path
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black54),
              onPressed: _logout,
            ),
          ],
        ),
        body: FutureBuilder<StudentTable>(
          future: _studentProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshAllData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No profile data found.'));
            }

            final studentProfile = snapshot.data!;

            // Using a list of widgets for the body based on the selected index
            final List<Widget> pages = [
              _buildProfilePage(studentProfile), // Index 0: Profile
              _buildHomePage(studentProfile), // Index 1: Home (Assignments)
              _buildModulePage(studentProfile), // Index 2: Module (Class Info)
            ];

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: IndexedStack(index: _selectedIndex, children: pages),
              bottomNavigationBar: _buildBottomNavigationBar(studentProfile),
            );
          },
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(StudentTable studentProfile) {
    ImageProvider? profileImage;
    if (kIsWeb && _imageBytes != null) {
      profileImage = MemoryImage(_imageBytes!);
    } else if (!kIsWeb && _imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (studentProfile.imageUrl != null &&
        studentProfile.imageUrl!.isNotEmpty) {
      profileImage = NetworkImage(studentProfile.imageUrl!);
    }

    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: CircleAvatar(
            radius: 15,
            backgroundImage: profileImage,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image: $exception');
            },
            child: profileImage == null
                ? const Icon(Icons.person, size: 15)
                : null,
          ),
          label: 'Profile',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), label: 'Module'),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }

  // Page for Profile Tab (Index 0)
  Widget _buildProfilePage(StudentTable studentProfile) {
    return RefreshIndicator(
      onRefresh: () async => _refreshAllData(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildProfileHeader(context, _currentStudentProfile!),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildModernInfoCard(
                context,
                title: 'Academic Information',
                icon: Icons.school,
                children: [
                  _buildStudentIdSection(studentProfile),
                  _buildProfileInfoRow(
                    Icons.format_list_numbered,
                    'Roll Number',
                    studentProfile.rollNumber?.toString(),
                  ),
                  _buildProfileInfoRow(
                    Icons.class_,
                    'Class ID',
                    studentProfile.classId,
                  ),
                  _buildProfileInfoRow(
                    Icons.group_work,
                    'Section',
                    studentProfile.section,
                  ),
                  _buildProfileInfoRow(
                    Icons.calendar_today,
                    'Session',
                    studentProfile.session,
                  ),
                  _buildProfileInfoRow(
                    Icons.check_circle_outline,
                    'Status',
                    studentProfile.status,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildModernInfoCard(
                context,
                title: 'Personal Information',
                icon: Icons.person,
                children: [
                  _buildProfileInfoRow(
                    Icons.person_outline,
                    'Full Name',
                    studentProfile.fullName,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        fullName: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.cake_outlined,
                    'Date of Birth',
                    studentProfile.dob,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        dob: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.wc_outlined,
                    'Gender',
                    studentProfile.gender,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        gender: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.bloodtype_outlined,
                    'Blood Group',
                    studentProfile.bloodGroup,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        bloodGroup: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.school_outlined,
                    'Admission Year',
                    studentProfile.admissionYear,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        admissionYear: value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildModernInfoCard(
                context,
                title: 'Contact Information',
                icon: Icons.contact_mail,
                children: [
                  _buildProfileInfoRow(
                    Icons.email_outlined,
                    'Email',
                    studentProfile.email,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        email: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.phone_outlined,
                    'Mobile No.',
                    studentProfile.mob,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        mob: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.location_on_outlined,
                    'Present Address',
                    studentProfile.presentAddress,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        presentAddress: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.home_outlined,
                    'Permanent Address',
                    studentProfile.permanentAddress,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        permanentAddress: value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildModernInfoCard(
                context,
                title: "Parent's Information",
                icon: Icons.family_restroom,
                children: [
                  _buildProfileInfoRow(
                    Icons.male,
                    "Father's Name",
                    studentProfile.fatherName,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        fatherName: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.phone,
                    "Father's Mobile",
                    studentProfile.fatherMobile,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        fatherMobile: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.female,
                    "Mother's Name",
                    studentProfile.motherName,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        motherName: value,
                      ),
                    ),
                  ),
                  _buildProfileInfoRow(
                    Icons.phone,
                    "Mother's Mobile",
                    studentProfile.motherMobile,
                    isEditable: true,
                    onChanged: (value) => setState(
                      () => _currentStudentProfile = _currentStudentProfile?.copyWith(
                        motherMobile: value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildChangePasswordButton(),
          const SizedBox(height: 24),
          if (!_isEditingProfile)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditingProfile = true;
                });
              },
              child: const Text('Edit Profile'),
            ),
          if (_isEditingProfile)
            ElevatedButton(
              onPressed: () {
                // Save changes to the database
                // You'll need to implement the actual save logic here
                // For now, let's just print the updated profile
                _saveProfileChanges();
                setState(() {
                  _isEditingProfile = false;
                });
              },
              child: const Text('Save Changes'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    if (_currentStudentProfile == null) return;

    try {
      String? imageUrl;
      if (kIsWeb && _imageBytes != null) {
        imageUrl = await _uploadImageBytes(_imageBytes!);
      } else if (!kIsWeb && _imageFile != null) {
        imageUrl = await _uploadImageFile(_imageFile!);
      }

      if (imageUrl != null) {
        _currentStudentProfile =
            _currentStudentProfile?.copyWith(imageUrl: imageUrl);
      }

      // Assuming you have an update method in your AuthService
      await _authService.updateStudentProfile(_currentStudentProfile!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  // Page for Home Tab (Index 1)
  Widget _buildHomePage(StudentTable studentProfile) {
    if (studentProfile.classId != null && studentProfile.classId!.isNotEmpty) {
      final classId = studentProfile.classId!;
      final streamAsyncValue = ref.watch(homePageStreamProvider(classId));

      return RefreshIndicator(
        onRefresh: () async {
          // Invalidate the provider to force a re-fetch of the stream
          ref.invalidate(homePageStreamProvider(classId));
        },
        child: streamAsyncValue.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'No announcements or assignments yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                // Conditionally render the correct tile based on the item type
                if (item.type == 'assignment') {
                  return AssignmentTile(item: item);
                } else if (item.type == 'announcement') {
                  return AnnouncementTile(item: item);
                }
                // Return an empty container for unknown types
                return const SizedBox.shrink();
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      );
    } else {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "You are not enrolled in any class to see assignments or announcements.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  // Page for Module Tab (Index 2)
  Widget _buildModulePage(StudentTable studentProfile) {
    if (studentProfile.classId != null && studentProfile.classId!.isNotEmpty) {
      // Directly display the grid of class tools on this tab.
      return ClassToolsGrid(classId: studentProfile.classId!);
    } else {
      // If not enrolled, show an informational card.
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Card(
            child: ListTile(
              title: Text('Not Enrolled in a Class'),
              subtitle: Text(
                'Please contact an administrator to be assigned to a class.',
              ),
              leading: Icon(Icons.info_outline),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildProfileHeader(
    BuildContext context,
    StudentTable studentProfile,
  ) {
    ImageProvider? backgroundImage;
    if (kIsWeb && _imageBytes != null) {
      backgroundImage = MemoryImage(_imageBytes!);
    } else if (!kIsWeb && _imageFile != null) {
      backgroundImage = FileImage(_imageFile!);
    } else if (studentProfile.imageUrl != null &&
        studentProfile.imageUrl!.isNotEmpty) {
      backgroundImage = CachedNetworkImageProvider(studentProfile.imageUrl!);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: backgroundImage,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading image: $exception');
                  },
                  child: backgroundImage == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              if (_isEditingProfile)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            studentProfile.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Text(
            studentProfile.email,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: CardPainter(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.lock_outline),
        label: const Text('Change Password'),
        onPressed: _showChangePasswordDialog,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildStudentIdSection(StudentTable studentProfile) {
    final hasId = studentProfile.studentId != null &&
        studentProfile.studentId!.isNotEmpty;

    if (hasId) {
      return _buildProfileInfoRow(
        Icons.badge_outlined,
        'Student ID',
        studentProfile.studentId,
      );
    } else {
      // For other users (like teachers), just show 'Not Assigned'.
      return _buildProfileInfoRow(
        Icons.badge_outlined,
        'Student ID',
        'Not Assigned',
      );
    }
  }

  Widget _buildProfileInfoRow(
    IconData icon,
    String label,
    String? value, {
    bool isEditable = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: isEditable && _isEditingProfile
                ? TextFormField(
                    initialValue: value ?? '',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey.shade700),
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    value ?? 'N/A',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
          ),
        ],
      ),
    );
  }
}

class CardPainter extends CustomPainter {
  final Color color;

  CardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.1, size.width * 0.3, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.4, size.width, size.height * 0.1)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
