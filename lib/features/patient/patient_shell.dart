import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/brand_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_controller.dart';
import 'patient_controller.dart';

class PatientShell extends ConsumerStatefulWidget {
  const PatientShell({super.key});

  @override
  ConsumerState<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends ConsumerState<PatientShell> {
  int index = 0;

  final List<Widget> Function(Function(int)) pages = (onNavigate) => [
    PatientHomeScreen(onNavigate: onNavigate),
    const SymptomReportScreen(),
    const PatientConsultationsScreen(),
    const PatientReferralsScreen(),
    const PatientClinicsScreen(),
    const PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 920;
    final currentPageList = pages((i) => setState(() => index = i));

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            _DashboardSidebar(
              selectedIndex: index,
              onIndexChanged: (i) => setState(() => index = i),
              role: 'Patient',
            ),
          Expanded(
            child: Column(
              children: [
                _DashboardHeader(
                  title: _getTitle(index),
                  isDesktop: isDesktop,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: currentPageList[index],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Symptoms'),
                NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Consults'),
                NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Referrals'),
                NavigationDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: 'Clinics'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
              ],
            )
          : null,
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Symptom Report';
      case 2: return 'My Consultations';
      case 3: return 'Referrals';
      case 4: return 'Clinic Directory';
      case 5: return 'My Profile';
      default: return 'Telemedicine';
    }
  }
}

class _DashboardHeader extends ConsumerWidget {
  final String title;
  final bool isDesktop;

  const _DashboardHeader({required this.title, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            const BrandLogo(size: 32),
            const SizedBox(width: 16),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFFD6246F).withOpacity(0.1),
            child: Text(
              user?.fullName?.substring(0, 1).toUpperCase() ?? 'P',
              style: const TextStyle(color: Color(0xFFD6246F), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final String role;

  const _DashboardSidebar({
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 260,
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: BrandLogo(size: 40, lightMode: true),
          ),
          const SizedBox(height: 20),
          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            selected: selectedIndex == 0,
            onTap: () => onIndexChanged(0),
          ),
          _SidebarItem(
            icon: Icons.monitor_heart_rounded,
            label: 'Symptom Report',
            selected: selectedIndex == 1,
            onTap: () => onIndexChanged(1),
          ),
          _SidebarItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Consultations',
            selected: selectedIndex == 2,
            onTap: () => onIndexChanged(2),
          ),
          _SidebarItem(
            icon: Icons.assignment_rounded,
            label: 'Referrals',
            selected: selectedIndex == 3,
            onTap: () => onIndexChanged(3),
          ),
          _SidebarItem(
            icon: Icons.local_hospital_rounded,
            label: 'Clinics',
            selected: selectedIndex == 4,
            onTap: () => onIndexChanged(4),
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            selected: selectedIndex == 5,
            onTap: () => onIndexChanged(5),
          ),
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            selected: false,
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD6246F) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey[400], size: 20),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[400],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientHomeScreen extends ConsumerWidget {
  final Function(int)? onNavigate;
  const PatientHomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final patientState = ref.watch(patientControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user?.fullName?.split(' ').first ?? 'Patient'}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep track of your health and consultations.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  title: 'Active Consults',
                  value: patientState.consultations.where((c) => c.status == 'open').length.toString(),
                  icon: Icons.chat_bubble_outline,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DashboardStatCard(
                  title: 'New Referrals',
                  value: patientState.referrals.length.toString(),
                  icon: Icons.assignment_outlined,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (patientState.triage != null) ...[
            const Text(
              'Latest Health Triage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD6246F), Color(0xFF9C1B52)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD6246F).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        patientState.triage!.classification.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    patientState.triage!.recommendedAction,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFD6246F)),
                    child: const Text('View Full Report'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _QuickActionCard(title: 'Report Symptoms', icon: Icons.monitor_heart, color: Colors.red, onTap: () => onNavigate?.call(1)),
              _QuickActionCard(title: 'Start Chat', icon: Icons.message, color: Colors.green, onTap: () => onNavigate?.call(2)),
              _QuickActionCard(title: 'Find Doctors', icon: Icons.people, color: Colors.purple, onTap: () => onNavigate?.call(4)),
              _QuickActionCard(title: 'Clinics Near Me', icon: Icons.map, color: Colors.blue, onTap: () => onNavigate?.call(4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({required this.title, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class SymptomReportScreen extends ConsumerStatefulWidget {
  const SymptomReportScreen({super.key});
  @override
  ConsumerState<SymptomReportScreen> createState() => _SymptomReportScreenState();
}

class _SymptomReportScreenState extends ConsumerState<SymptomReportScreen> {
  final symptomOptions = const [
    'fever', 'cough', 'persistent cough', 'headache', 'night sweats',
    'weight loss', 'chest pain', 'fatigue', 'sore throat', 'shortness of breath',
  ];
  final selected = <String>{};
  final duration = TextEditingController();
  final notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select your symptoms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptomOptions.map((s) => FilterChip(
              label: Text(s),
              selected: selected.contains(s),
              onSelected: (v) => setState(() => v ? selected.add(s) : selected.remove(s)),
              selectedColor: const Color(0xFFD6246F).withOpacity(0.2),
              checkmarkColor: const Color(0xFFD6246F),
            )).toList(),
          ),
          const SizedBox(height: 32),
          _buildInputLabel('Duration (days)'),
          TextField(
            controller: duration,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('e.g. 3'),
          ),
          const SizedBox(height: 24),
          _buildInputLabel('Additional Notes'),
          TextField(
            controller: notes,
            maxLines: 4,
            decoration: _inputDecoration('Describe how you feel...'),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: state.loading ? null : () async {
                final triage = await ref.read(patientControllerProvider.notifier).submitSymptoms(
                  selected.toList(),
                  int.tryParse(duration.text) ?? 1,
                  notes.text,
                );
                if (mounted && triage != null) {
                  _showTriageResult(context, triage);
                }
              },
              child: state.loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit for AI Triage'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  void _showTriageResult(BuildContext context, dynamic triage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(triage.classification.toUpperCase(), style: TextStyle(
          color: triage.classification == 'urgent' ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: ${(triage.confidenceScore * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            Text(triage.recommendedAction),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to consults or start one
            },
            child: const Text('Start Consultation'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
    );
  }
}

class PatientConsultationsScreen extends ConsumerWidget {
  const PatientConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientControllerProvider);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.consultations.length,
      itemBuilder: (_, i) {
        final c = state.consultations[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text('Consultation ID: ${c.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${c.status.toUpperCase()}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showConsultationDetails(context, c),
          ),
        );
      },
    );
  }

  void _showConsultationDetails(BuildContext context, dynamic c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Consultation Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(title: const Text('ID'), subtitle: Text(c.id)),
            ListTile(title: const Text('Status'), subtitle: Text(c.status.toUpperCase())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Open Chat')),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientReferralsScreen extends ConsumerWidget {
  const PatientReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientControllerProvider);
    return state.referrals.isEmpty 
      ? const Center(child: Text('No referrals found.'))
      : ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: state.referrals.length,
          itemBuilder: (_, i) {
            final r = state.referrals[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(r.facilityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(r.address),
                trailing: const Icon(Icons.map_outlined, color: Color(0xFFD6246F)),
              ),
            );
          },
        );
  }
}

class PatientClinicsScreen extends ConsumerStatefulWidget {
  const PatientClinicsScreen({super.key});
  @override
  ConsumerState<PatientClinicsScreen> createState() => _PatientClinicsScreenState();
}

class _PatientClinicsScreenState extends ConsumerState<PatientClinicsScreen> {
  final search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            controller: search,
            decoration: InputDecoration(
              hintText: 'Search for clinics or facilities...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {},
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            ),
            onSubmitted: (v) => ref.read(patientControllerProvider.notifier).loadFacilities(search: v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.facilities.length,
            itemBuilder: (_, i) {
              final f = state.facilities[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(f.address),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showClinicDetails(context, f),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showClinicDetails(BuildContext context, dynamic f) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(f.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.location_on), title: Text(f.address)),
            ListTile(leading: const Icon(Icons.phone), title: Text(f.phone)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: () {}, child: const Text('Book Appointment')),
        ],
      ),
    );
  }
}

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFD6246F),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Patient Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user?.phoneNumber ?? '', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          _buildProfileTile(Icons.fingerprint, 'Anonymous ID', user?.anonymousId ?? 'N/A'),
          _buildProfileTile(Icons.security, 'Account Security', 'Password & 2FA'),
          _buildProfileTile(Icons.language, 'Language', 'English'),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _showEditProfile(context, user),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, dynamic user) {
    final name = TextEditingController(text: user?.fullName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
