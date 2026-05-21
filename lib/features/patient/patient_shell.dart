import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_controller.dart';
import 'patient_controller.dart';

class PatientShell extends ConsumerStatefulWidget {
  const PatientShell({super.key});

  @override
  ConsumerState<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends ConsumerState<PatientShell> {
  int _index = 0;
  String? _openConsultationId;

  void _navigate(int i, {String? consultationId}) {
    setState(() {
      _index = i;
      _openConsultationId = consultationId;
    });
  }

  static const _titles = [
    'Dashboard', 'Symptom Report', 'My Consultations',
    'Referrals', 'Clinic Directory', 'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 920;

    final pages = [
      PatientHomeScreen(onNavigate: _navigate),
      const SymptomReportScreen(),
      PatientConsultationsScreen(openConsultationId: _openConsultationId, onNavigate: _navigate),
      const PatientReferralsScreen(),
      const PatientClinicsScreen(),
      const PatientProfileScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            _PatientSidebar(
              selectedIndex: _index,
              onIndexChanged: (i) => setState(() => _index = i),
            ),
          Expanded(
            child: Column(
              children: [
                _PatientHeader(title: _titles[_index], isDesktop: isDesktop),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (v) => setState(() { _index = v; _openConsultationId = null; }),
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
}

class _PatientHeader extends ConsumerWidget {
  final String title;
  final bool isDesktop;
  const _PatientHeader({required this.title, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[const BrandLogo(size: 32), const SizedBox(width: 16)],
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (user?.anonymousId != null && user!.anonymousId.isNotEmpty)
            Semantics(
              label: 'Your anonymous ID: ${user.anonymousId}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6246F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.anonymousId,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD6246F), letterSpacing: 0.5),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Semantics(
            label: 'Notifications',
            child: IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: const Color(0xFFD6246F).withValues(alpha: 0.1),
            child: Text(
              user?.fullName.isNotEmpty == true ? user!.fullName.substring(0, 1).toUpperCase() : 'P',
              style: const TextStyle(color: Color(0xFFD6246F), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  const _PatientSidebar({required this.selectedIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 260,
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(24), child: BrandLogo(size: 40, lightMode: true)),
          const SizedBox(height: 20),
          _SidebarItem(icon: Icons.home_rounded, label: 'Dashboard', selected: selectedIndex == 0, onTap: () => onIndexChanged(0)),
          _SidebarItem(icon: Icons.monitor_heart_rounded, label: 'Symptom Report', selected: selectedIndex == 1, onTap: () => onIndexChanged(1)),
          _SidebarItem(icon: Icons.chat_bubble_rounded, label: 'My Consultations', selected: selectedIndex == 2, onTap: () => onIndexChanged(2)),
          _SidebarItem(icon: Icons.assignment_rounded, label: 'Referrals', selected: selectedIndex == 3, onTap: () => onIndexChanged(3)),
          _SidebarItem(icon: Icons.local_hospital_rounded, label: 'Clinic Directory', selected: selectedIndex == 4, onTap: () => onIndexChanged(4)),
          const Spacer(),
          _SidebarItem(icon: Icons.person_rounded, label: 'My Profile', selected: selectedIndex == 5, onTap: () => onIndexChanged(5)),
          _SidebarItem(
            icon: Icons.logout_rounded, label: 'Logout', selected: false,
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
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Semantics(
        label: label, selected: selected,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFD6246F) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey[400], size: 20),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[400], fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title, button: true,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
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
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  int _durationDays = 1;
  TriageResult? _result;

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(patientControllerProvider);
    if (_result != null) {
      return _TriageResultView(result: _result!, onReset: () => setState(() => _result = null));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Describe Your Symptoms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Provide as much detail as possible for accurate triage.', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 28),
          TextField(
            controller: _symptomsController, maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Symptoms (comma-separated)',
              hintText: 'e.g. fever, headache, sore throat',
              filled: true, fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Duration: $_durationDays day${_durationDays > 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _durationDays.toDouble(), min: 1, max: 30,
            divisions: 29, label: '$_durationDays days',
            activeColor: const Color(0xFFD6246F),
            onChanged: (v) => setState(() => _durationDays = v.round()),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notesController, maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Additional Notes (optional)',
              filled: true, fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          if (ps.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(ps.error!, style: const TextStyle(color: Colors.red)),
            ),
          SizedBox(
            width: double.infinity, height: 54,
            child: FilledButton.icon(
              onPressed: ps.loading ? null : () async {
                final symptoms = _symptomsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                if (symptoms.isEmpty) return;
                final result = await ref.read(patientControllerProvider.notifier).submitSymptoms(symptoms, _durationDays, _notesController.text.trim());
                if (result != null && mounted) setState(() => _result = result);
              },
              icon: ps.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
              label: Text(ps.loading ? 'Analysing...' : 'Submit Symptoms'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriageResultView extends StatelessWidget {
  final TriageResult result;
  final VoidCallback onReset;
  const _TriageResultView({required this.result, required this.onReset});

  Color get _color {
    switch (result.classification.toLowerCase()) {
      case 'urgent': return Colors.red;
      case 'routine': return Colors.blue;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(radius: 40, backgroundColor: _color.withValues(alpha: 0.1), child: Icon(Icons.monitor_heart, color: _color, size: 40)),
          const SizedBox(height: 20),
          Text(result.classification.toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _color)),
          const SizedBox(height: 12),
          Text(result.recommendedAction, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 8),
          Text('Confidence: ${(result.confidenceScore * 100).toStringAsFixed(0)}%', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: onReset, icon: const Icon(Icons.refresh, size: 18), label: const Text('Submit New Report'))),
        ],
      ),
    );
  }
}

class PatientHomeScreen extends ConsumerWidget {
  final void Function(int, {String? consultationId})? onNavigate;
  const PatientHomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final ps = ref.watch(patientControllerProvider);
    final activeConsults = ps.consultations.where((c) => c.status == 'open').toList();
    final newReferrals = ps.referrals.where((r) => r.status == ReferralStatus.newReferral).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user?.fullName.split(' ').first ?? 'Patient'}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _StatusBanner(activeConsults: activeConsults, triage: ps.triage),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Active Consults', value: activeConsults.length.toString(), icon: Icons.chat_bubble_outline, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'New Referrals', value: newReferrals.length.toString(), icon: Icons.assignment_outlined, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 28),
          if (ps.triage != null) ...[_TriageCard(triage: ps.triage!, onNavigate: onNavigate), const SizedBox(height: 28)],
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _QuickActionCard(title: 'Report Symptoms', icon: Icons.monitor_heart, color: Colors.red, onTap: () => onNavigate?.call(1)),
              _QuickActionCard(
                title: 'Consult a Doctor',
                icon: Icons.message,
                color: Colors.green,
                onTap: () => _showConsultModal(context, ref, ps.triage, onNavigate),
              ),
              _QuickActionCard(title: 'Find a Clinic', icon: Icons.local_hospital, color: Colors.blue, onTap: () => onNavigate?.call(4)),
              _QuickActionCard(title: 'My Referrals', icon: Icons.assignment, color: Colors.purple, onTap: () => onNavigate?.call(3)),
            ],
          ),
          if (activeConsults.isNotEmpty) ...[const SizedBox(height: 28), _ActiveConsultationSection(consultations: activeConsults, onNavigate: onNavigate)],
          if (ps.referrals.isNotEmpty) ...[const SizedBox(height: 28), _RecentReferralsSection(referrals: ps.referrals, onNavigate: onNavigate)],
        ],
      ),
    );
  }

  void _showConsultModal(BuildContext context, WidgetRef ref, TriageResult? triage, void Function(int, {String? consultationId})? onNavigate) {
    if (triage != null) {
      onNavigate?.call(2);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.info_outline, color: Color(0xFFD6246F)),
          SizedBox(width: 10),
          Text('No Symptoms Submitted'),
        ]),
        content: const Text('You have not submitted symptoms yet. AI triage helps your doctor prioritise your case. Continue anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Submit Symptoms First')),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); onNavigate?.call(2); },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final List<Consultation> activeConsults;
  final TriageResult? triage;
  const _StatusBanner({required this.activeConsults, required this.triage});

  @override
  Widget build(BuildContext context) {
    final hasUrgent = triage?.classification == 'urgent';
    final Color bg = hasUrgent ? Colors.red.shade50 : (activeConsults.isEmpty ? Colors.grey.shade50 : Colors.blue.shade50);
    final Color fg = hasUrgent ? Colors.red.shade700 : (activeConsults.isEmpty ? Colors.grey.shade600 : Colors.blue.shade700);
    final IconData icon = hasUrgent ? Icons.warning_amber_rounded : (activeConsults.isEmpty ? Icons.check_circle_outline : Icons.chat_bubble_outline);
    final String text = hasUrgent
        ? 'Urgent: Please seek medical attention now.'
        : activeConsults.isEmpty
            ? 'No active consultations.'
            : '${activeConsults.length} active consultation${activeConsults.length > 1 ? 's' : ''}.';
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _TriageCard extends StatelessWidget {
  final TriageResult triage;
  final void Function(int, {String? consultationId})? onNavigate;
  const _TriageCard({required this.triage, this.onNavigate});

  Color get _bgColor {
    switch (triage.classification) {
      case 'urgent': return const Color(0xFFD6246F);
      case 'routine': return const Color(0xFF1976D2);
      default: return const Color(0xFF388E3C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = triage.classification == 'urgent';
    final isRoutine = triage.classification == 'routine';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Latest Health Triage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _bgColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.health_and_safety, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(triage.classification.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Text('${(triage.confidenceScore * 100).toStringAsFixed(0)}% confidence', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              Text(triage.recommendedAction, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, height: 1.4)),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, children: [
                if (isUrgent) ...[  
                  _TriageCTA(label: 'Find a Clinic', icon: Icons.local_hospital, onTap: () => onNavigate?.call(4)),
                  _TriageCTA(label: 'Start Consultation', icon: Icons.chat, onTap: () => onNavigate?.call(2)),
                ],
                if (isRoutine)
                  _TriageCTA(label: 'Start Consultation', icon: Icons.chat, onTap: () => onNavigate?.call(2)),
                if (!isUrgent && !isRoutine)
                  _TriageCTA(label: 'View Self-Care Advice', icon: Icons.self_improvement, onTap: () => _showAdvice(context)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  void _showAdvice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.self_improvement, color: Color(0xFF388E3C)), SizedBox(width: 8), Text('Self-Care Advice')]),
        content: Text(triage.recommendedAction),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
      ),
    );
  }
}

class _TriageCTA extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TriageCTA({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true, label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A))),
          ]),
        ),
      ),
    );
  }
}

class _ActiveConsultationSection extends StatelessWidget {
  final List<Consultation> consultations;
  final void Function(int, {String? consultationId})? onNavigate;
  const _ActiveConsultationSection({required this.consultations, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Consultations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...consultations.take(3).map((c) => _ConsultTile(consultation: c, onNavigate: onNavigate)),
      ],
    );
  }
}

class _ConsultTile extends StatelessWidget {
  final Consultation consultation;
  final void Function(int, {String? consultationId})? onNavigate;
  const _ConsultTile({required this.consultation, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final triageColor = c.triageClassification == 'urgent' ? Colors.red : (c.triageClassification == 'routine' ? Colors.blue : Colors.green);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onNavigate?.call(2, consultationId: c.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4, height: 48,
                decoration: BoxDecoration(color: triageColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(DateFormat('dd MMM y').format(c.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: triageColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(c.triageClassification.toUpperCase(), style: TextStyle(color: triageColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      c.lastMessagePreview.isNotEmpty ? c.lastMessagePreview : 'No messages yet.',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(c.status.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
              if (c.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(12)),
                  child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentReferralsSection extends StatelessWidget {
  final List<Referral> referrals;
  final void Function(int, {String? consultationId})? onNavigate;
  const _RecentReferralsSection({required this.referrals, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Referrals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...referrals.take(3).map((r) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.local_hospital_outlined, color: Color(0xFFD6246F)),
            title: Text(r.facilityName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('dd MMM y').format(r.issuedDate)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: r.status == ReferralStatus.newReferral ? Colors.orange.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r.status == ReferralStatus.newReferral ? 'NEW' : 'VIEWED',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: r.status == ReferralStatus.newReferral ? Colors.orange.shade700 : Colors.grey),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ]),
            onTap: () => onNavigate?.call(3),
          ),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}

class PatientConsultationsScreen extends ConsumerStatefulWidget {
  final String? openConsultationId;
  final void Function(int, {String? consultationId})? onNavigate;
  const PatientConsultationsScreen({super.key, this.openConsultationId, this.onNavigate});

  @override
  ConsumerState<PatientConsultationsScreen> createState() => _PatientConsultationsScreenState();
}

class _PatientConsultationsScreenState extends ConsumerState<PatientConsultationsScreen> {
  String? _activeChat;

  @override
  void initState() {
    super.initState();
    _activeChat = widget.openConsultationId;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    if (_activeChat != null) {
      final c = state.consultations.firstWhere((e) => e.id == _activeChat, orElse: () => state.consultations.isEmpty ? Consultation(id: _activeChat!, status: 'open', patientAnonymousId: '', providerId: '', createdAt: DateTime.now()) : state.consultations.first);
      return PatientChatScreen(consultation: c, onBack: () => setState(() => _activeChat = null));
    }
    if (state.loading && state.consultations.isEmpty) return const LoadingView(message: 'Loading consultations...');
    if (state.consultations.isEmpty) {
      return EmptyView(
        message: 'No consultations yet.',
        icon: Icons.chat_bubble_outline,
        actionLabel: 'Start a Consultation',
        onAction: () => widget.onNavigate?.call(1),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.consultations.length,
      itemBuilder: (_, i) {
        final c = state.consultations[i];
        final triageColor = c.triageClassification == 'urgent' ? Colors.red : (c.triageClassification == 'routine' ? Colors.blue : Colors.green);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _activeChat = c.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(width: 4, height: 56, decoration: BoxDecoration(color: triageColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(DateFormat('dd MMM y').format(c.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: triageColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(c.triageClassification.toUpperCase(), style: TextStyle(color: triageColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.status == 'open' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(c.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.status == 'open' ? Colors.green : Colors.grey)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          c.lastMessagePreview.isNotEmpty ? c.lastMessagePreview : 'Tap to open chat',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  if (c.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(12)),
                      child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  else
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PatientChatScreen extends ConsumerStatefulWidget {
  final Consultation consultation;
  final VoidCallback onBack;
  const PatientChatScreen({super.key, required this.consultation, required this.onBack});

  @override
  ConsumerState<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends ConsumerState<PatientChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ref.read(patientControllerProvider.notifier).loadMessages(widget.consultation.id);
      if (mounted) setState(() { _messages = msgs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    final optimistic = ChatMessage(id: 'local-${DateTime.now().millisecondsSinceEpoch}', senderRole: 'patient', body: text, createdAt: DateTime.now());
    setState(() => _messages.add(optimistic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
    try {
      await ref.read(patientControllerProvider.notifier).sendMessage(widget.consultation.id, text);
    } catch (_) {}
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final triageColor = widget.consultation.triageClassification == 'urgent' ? Colors.red : (widget.consultation.triageClassification == 'routine' ? Colors.blue : Colors.green);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Consultation ${widget.consultation.id.length >= 8 ? widget.consultation.id.substring(0, 8) : widget.consultation.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: triageColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(widget.consultation.triageClassification.toUpperCase(), style: TextStyle(color: triageColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(widget.consultation.status.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ]),
            ])),
          ]),
        ),
        if (_loading)
          const Expanded(child: LoadingView(message: 'Loading messages...'))
        else if (_messages.isEmpty)
          Expanded(child: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey), const SizedBox(height: 16), Text('No messages yet.', style: TextStyle(color: Colors.grey[500])), const SizedBox(height: 8), const Text('Send a message to start the conversation.')],
          )))
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m.senderRole == 'patient';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFD6246F) : Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Text(m.body, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat('HH:mm').format(m.createdAt),
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (widget.consultation.status == 'open')
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  onSubmitted: (_) => _send(),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true, fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                label: 'Send message',
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFFD6246F)),
                  onPressed: _send,
                ),
              ),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: const Center(child: Text('This consultation is closed.', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }
}

class PatientReferralsScreen extends ConsumerWidget {
  const PatientReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'Search referrals',
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for referrals...',
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.loading
              ? const LoadingView(message: 'Loading referrals...')
              : state.referrals.isEmpty
                  ? const EmptyView(message: 'No referrals yet. Your doctor will issue one after a consultation.', icon: Icons.assignment_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      itemCount: state.referrals.length,
                      itemBuilder: (_, i) {
                        final r = state.referrals[i];
                        final isNew = r.status == ReferralStatus.newReferral;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (isNew) ref.read(patientControllerProvider.notifier).markReferralViewed(r.id);
                              _showReferralDetails(context, r);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text(r.facilityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isNew ? Colors.orange.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(isNew ? 'NEW' : 'VIEWED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isNew ? Colors.orange.shade700 : Colors.grey)),
                                    ),
                                  ]),
                                  const SizedBox(height: 6),
                                  Row(children: [Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text(r.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)))]),
                                  const SizedBox(height: 2),
                                  Row(children: [Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Text('Issued: ${DateFormat('dd MMM y').format(r.issuedDate)}', style: TextStyle(color: Colors.grey[600], fontSize: 13))]),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        if (isNew) ref.read(patientControllerProvider.notifier).markReferralViewed(r.id);
                                        _showReferralDetails(context, r);
                                      },
                                      icon: const Icon(Icons.open_in_new, size: 16),
                                      label: const Text('View Referral'),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFD6246F)), foregroundColor: const Color(0xFFD6246F)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showReferralDetails(BuildContext context, Referral r) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(r.facilityName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.location_on_outlined), title: Text(r.address)),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.phone_outlined), title: Text(r.phone)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booking coming soon.')));
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientClinicsScreen extends ConsumerStatefulWidget {
  const PatientClinicsScreen({super.key});
  @override
  ConsumerState<PatientClinicsScreen> createState() => _PatientClinicsScreenState();
}

class _PatientClinicsScreenState extends ConsumerState<PatientClinicsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Semantics(
            label: 'Search clinics',
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search for clinics or facilities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _search.clear(); ref.read(patientControllerProvider.notifier).loadFacilities(); setState(() {}); })
                    : null,
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => ref.read(patientControllerProvider.notifier).loadFacilities(search: v),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.loading
              ? const LoadingView(message: 'Searching...')
              : state.facilities.isEmpty
                  ? const EmptyView(message: 'No clinics found. Try a different search term.', icon: Icons.local_hospital_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      itemCount: state.facilities.length,
                      itemBuilder: (_, i) {
                        final f = state.facilities[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.local_hospital, color: Color(0xFFD6246F), size: 20)),
                            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(f.address, style: TextStyle(color: Colors.grey[600])),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            onTap: () => _showClinicDetails(context, f),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showClinicDetails(BuildContext context, Facility f) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(f.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.location_on_outlined), title: Text(f.address)),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.phone_outlined), title: Text(f.phone)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booking coming soon.')));
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
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
            radius: 50, backgroundColor: Color(0xFFD6246F),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Patient Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.phoneNumber ?? '', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 28),
          _tile(Icons.fingerprint, 'Anonymous ID', user?.anonymousId ?? 'N/A'),
          _tile(Icons.security, 'Account Security', 'Password'),
          _tile(Icons.language, 'Language', 'English'),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _showEditProfile(context, user),
            icon: const Icon(Icons.edit), label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity, height: 54,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'), content: const Text('Are you sure you want to sign out?'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Sign Out'))],
                ));
                if (confirmed == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout), label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
