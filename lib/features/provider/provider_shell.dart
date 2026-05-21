import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/brand_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_controller.dart';
import 'provider_controller.dart';

class ProviderShell extends ConsumerStatefulWidget {
  const ProviderShell({super.key});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
  int index = 0;

  final titles = const ['Dashboard', 'Consultations', 'Messages', 'Referrals', 'Clinics', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 920;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            _DashboardSidebar(
              selectedIndex: index,
              onIndexChanged: (i) => setState(() => index = i),
              role: 'Healthcare Provider',
            ),
          Expanded(
            child: Column(
              children: [
                _DashboardHeader(
                  title: titles[index],
                  isDesktop: isDesktop,
                ),
                Expanded(
                  child: _ProviderContent(index: index),
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
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Stats'),
                NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'Consults'),
                NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat), label: 'Chats'),
                NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Referrals'),
                NavigationDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: 'Clinics'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
              ],
            )
          : null,
    );
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
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              user?.fullName?.substring(0, 1).toUpperCase() ?? 'D',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: selectedIndex == 0,
            onTap: () => onIndexChanged(0),
          ),
          _SidebarItem(
            icon: Icons.medical_services_rounded,
            label: 'Consultations',
            selected: selectedIndex == 1,
            onTap: () => onIndexChanged(1),
          ),
          _SidebarItem(
            icon: Icons.chat_rounded,
            label: 'Messages',
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
            label: 'My Profile',
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

class _ProviderContent extends ConsumerWidget {
  const _ProviderContent({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (index == 0) return const _ProviderDashboard();
    if (index == 1) return const _ProviderConsultationsScreen();
    if (index == 2) return const _ProviderMessagesScreen();
    if (index == 3) return const _ProviderReferralsScreen();
    if (index == 4) return const _ProviderClinicsScreen();
    if (index == 5) return const _ProviderProfileScreen();
    return const SizedBox.shrink();
  }
}

class _ProviderConsultationsScreen extends ConsumerWidget {
  const _ProviderConsultationsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerControllerProvider);
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
            title: Text('Consultation #${c.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Patient ID: ${c.patientAnonymousId}'),
            trailing: _buildStatusBadge(c.status),
            onTap: () {
              ref.read(providerControllerProvider.notifier).selectConsultation(c.id);
              // Access the parent state to switch tab? 
              // Better to use a provider for the shared index.
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'open' ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _ProviderMessagesScreen extends ConsumerWidget {
  const _ProviderMessagesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerControllerProvider);
    final textController = TextEditingController();

    if (state.selectedConsultationId == null) {
      return const Center(child: Text('Please select a consultation first.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: state.messages.length,
            itemBuilder: (_, i) {
              final m = state.messages[i];
              final isMe = m.senderRole == 'provider';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFD6246F) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    m.body,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFFD6246F)),
                onPressed: () {
                  ref.read(providerControllerProvider.notifier).sendMessage(textController.text);
                  textController.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderReferralsScreen extends ConsumerWidget {
  const _ProviderReferralsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showIssueReferral(context),
        backgroundColor: const Color(0xFFD6246F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: const Center(child: Text('No referrals issued yet.')),
    );
  }

  void _showIssueReferral(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue New Referral'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Patient ID')),
            const TextField(decoration: InputDecoration(labelText: 'Reason for Referral')),
            const TextField(decoration: InputDecoration(labelText: 'Facility Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Issue')),
        ],
      ),
    );
  }
}

class _ProviderClinicsScreen extends ConsumerWidget {
  const _ProviderClinicsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search facilities...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const Expanded(child: Center(child: Text('Search for specialized facilities.'))),
      ],
    );
  }
}

class _ProviderProfileScreen extends ConsumerWidget {
  const _ProviderProfileScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, backgroundColor: Colors.blue, child: Icon(Icons.medical_services, size: 50, color: Colors.white)),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Provider Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Healthcare Provider', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone Number'),
            subtitle: Text(user?.phoneNumber ?? ''),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _showEditProfile(context, user),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Medical Profile'),
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
        title: const Text('Edit Provider Profile'),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}

class _ProviderDashboard extends ConsumerWidget {
  const _ProviderDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerControllerProvider);
    final open = state.consultations.where((e) => e.status == 'open').length;
    final total = state.consultations.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _DashboardStatCard(title: 'Active Consults', value: '$open', icon: Icons.pending_actions, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _DashboardStatCard(title: 'Completed', value: '${total - open}', icon: Icons.check_circle_outline, color: Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _DashboardStatCard(title: 'Pending Reports', value: '5', icon: Icons.description_outlined, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Recent Consultation Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.consultations.take(5).length,
            itemBuilder: (context, i) {
              final c = state.consultations[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text('Consultation #${c.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Patient ID: ${c.patientAnonymousId}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.status == 'open' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c.status.toUpperCase(),
                      style: TextStyle(color: c.status == 'open' ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
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
