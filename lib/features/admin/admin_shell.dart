import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/brand_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_controller.dart';
import 'admin_controller.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int index = 0;

  final titles = const [
    'System Dashboard',
    'User Management',
    'Consultations',
    'Triage Analytics',
    'Clinic Directory',
    'System Health',
    'Logout',
  ];

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
              role: 'System Administrator',
            ),
          Expanded(
            child: Column(
              children: [
                _DashboardHeader(
                  title: titles[index],
                  isDesktop: isDesktop,
                ),
                Expanded(
                  child: _AdminContent(index: index),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: index > 5 ? 0 : index, // Handle logout index safety
              onDestinationSelected: (v) {
                // Map bottom bar index to sidebar index
                final Map<int, int> mapping = {0: 0, 1: 1, 2: 2, 3: 3, 4: 5};
                setState(() => index = mapping[v] ?? 0);
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Stats'),
                NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Users'),
                NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Consults'),
                NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
                NavigationDestination(icon: Icon(Icons.health_and_safety_outlined), selectedIcon: Icon(Icons.health_and_safety), label: 'Health'),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ADMIN MODE',
              style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.settings_outlined),
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
            icon: Icons.people_rounded,
            label: 'User Management',
            selected: selectedIndex == 1,
            onTap: () => onIndexChanged(1),
          ),
          _SidebarItem(
            icon: Icons.list_alt_rounded,
            label: 'Consultations',
            selected: selectedIndex == 2,
            onTap: () => onIndexChanged(2),
          ),
          _SidebarItem(
            icon: Icons.analytics_rounded,
            label: 'Triage Analytics',
            selected: selectedIndex == 3,
            onTap: () => onIndexChanged(3),
          ),
          _SidebarItem(
            icon: Icons.local_hospital_rounded,
            label: 'Clinic Directory',
            selected: selectedIndex == 4,
            onTap: () => onIndexChanged(4),
          ),
          _SidebarItem(
            icon: Icons.health_and_safety_rounded,
            label: 'System Health',
            selected: selectedIndex == 5,
            onTap: () => onIndexChanged(5),
          ),
          const Spacer(),
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

class _AdminContent extends ConsumerWidget {
  const _AdminContent({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (index == 0) return const _AdminDashboard();
    if (index == 1) return const _AdminUsersScreen();
    if (index == 2) return const _AdminConsultationsScreen();
    if (index == 3) return const _AdminAnalyticsScreen();
    if (index == 4) return const _AdminClinicsScreen();
    if (index == 5) return const _AdminHealthScreen();
    return const SizedBox.shrink();
  }
}

class _AdminUsersScreen extends ConsumerWidget {
  const _AdminUsersScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.users.length,
      itemBuilder: (_, i) {
        final u = state.users[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${u.phoneNumber} | Role: ${u.role}'),
            trailing: Switch(
              value: u.isActive,
              onChanged: (v) => ref.read(adminControllerProvider.notifier).toggleUserStatus(u.id, v),
              activeColor: const Color(0xFFD6246F),
            ),
            onTap: () => _showUserDetails(context, ref, u),
          ),
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Phone'), subtitle: Text(user.phoneNumber)),
            ListTile(title: const Text('Role'), subtitle: Text(user.role)),
            const Divider(),
            if (user.role == 'patient')
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.blue),
                title: const Text('Promote to Provider'),
                onTap: () {
                  ref.read(adminControllerProvider.notifier).toggleUserStatus(user.id, true); // Dummy logic for promotion
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _AdminConsultationsScreen extends ConsumerWidget {
  const _AdminConsultationsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.consultations.length,
      itemBuilder: (_, i) {
        final c = state.consultations[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text('Consultation #${c.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Patient ID: ${c.patientAnonymousId}'),
            trailing: Text(c.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      },
    );
  }
}

class _AdminAnalyticsScreen extends ConsumerWidget {
  const _AdminAnalyticsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(adminControllerProvider).analytics;
    if (analytics == null) return const LoadingView();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('System Usage Over Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildChartBar('Reports', analytics.totalReports / 100, Colors.blue),
        _buildChartBar('Urgent', analytics.urgent / 50, Colors.red),
        _buildChartBar('7 Days', analytics.last7Days / 30, Colors.green),
        const SizedBox(height: 40),
        _buildAnalyticsRow('Total Reports', '${analytics.totalReports}'),
        _buildAnalyticsRow('Urgent Cases', '${analytics.urgent}'),
        _buildAnalyticsRow('Average Confidence', '${(analytics.averageConfidence * 100).toStringAsFixed(1)}%'),
        _buildAnalyticsRow('Last 7 Days', '${analytics.last7Days}'),
      ],
    );
  }

  Widget _buildChartBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AdminClinicsScreen extends ConsumerWidget {
  const _AdminClinicsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClinicEditor(context, ref),
        backgroundColor: const Color(0xFFD6246F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: state.facilities.length,
        itemBuilder: (_, i) {
          final f = state.facilities[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(f.address),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showClinicEditor(context, ref, facility: f)),
                  IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showClinicEditor(BuildContext context, WidgetRef ref, {dynamic facility}) {
    final name = TextEditingController(text: facility?.name);
    final address = TextEditingController(text: facility?.address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(facility == null ? 'Add New Clinic' : 'Edit Clinic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}

class _AdminHealthScreen extends ConsumerWidget {
  const _AdminHealthScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(adminControllerProvider).health;
    if (health == null) return const LoadingView();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _HealthRow(label: 'API Service', status: health.apiStatus, color: _getStatusColor(health.apiStatus)),
        const Divider(),
        _HealthRow(label: 'Database', status: health.databaseStatus, color: _getStatusColor(health.databaseStatus)),
        const Divider(),
        _HealthRow(label: 'ML Engine', status: health.mlServiceStatus, color: _getStatusColor(health.mlServiceStatus)),
        const Divider(),
        _HealthRow(label: 'Redis Cache', status: health.redisStatus, color: _getStatusColor(health.redisStatus)),
        const SizedBox(height: 32),
        Text('System Uptime: ${health.uptimeSeconds} seconds', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'healthy') return Colors.green;
    if (status == 'degraded') return Colors.orange;
    return Colors.red;
  }
}

class _AdminDashboard extends ConsumerWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final ctrl = ref.read(adminControllerProvider.notifier);

    if (state.analytics == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.loadDashboard());
      return const LoadingView();
    }

    final analytics = state.analytics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _DashboardStatCard(title: 'Total Reports', value: '${analytics.totalReports}', icon: Icons.description_outlined, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _DashboardStatCard(title: 'Urgent Cases', value: '${analytics.urgent}', icon: Icons.warning_amber_rounded, color: Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _DashboardStatCard(title: 'Self Care', value: '${analytics.selfCare}', icon: Icons.health_and_safety_outlined, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('System Health Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              children: [
                _HealthRow(label: 'API Service', status: 'Healthy', color: Colors.green),
                const Divider(),
                _HealthRow(label: 'Database', status: 'Healthy', color: Colors.green),
                const Divider(),
                _HealthRow(label: 'ML Engine', status: 'Degraded', color: Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _HealthRow({required this.label, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
