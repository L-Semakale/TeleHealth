import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final pages = const [
    PatientHomeScreen(),
    SymptomReportScreen(),
    PatientConsultationsScreen(),
    PatientReferralsScreen(),
    PatientClinicsScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.monitor_heart), label: 'Symptoms'),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: 'Consults'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Referrals'),
          NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Clinics'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final patientState = ref.watch(patientControllerProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, ${user?.fullName ?? 'Patient'}', style: Theme.of(context).textTheme.headlineSmall),
          Text('Anonymous ID: ${user?.anonymousId ?? '-'}'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _QuickCard(title: 'Submit symptoms', icon: Icons.monitor_heart),
              _QuickCard(title: 'Start consultation', icon: Icons.chat),
              _QuickCard(title: 'View referrals', icon: Icons.assignment),
              _QuickCard(title: 'Find clinic', icon: Icons.local_hospital),
            ],
          ),
          const SizedBox(height: 16),
          if (patientState.triage != null)
            Card(
              child: ListTile(
                title: Text('Recent triage: ${patientState.triage!.classification.toUpperCase()}'),
                subtitle: Text(patientState.triage!.recommendedAction),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [Icon(icon), const SizedBox(height: 6), Text(title)],
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
  final symptomOptions = const [
    'fever',
    'cough',
    'persistent cough',
    'headache',
    'night sweats',
    'weight loss',
    'chest pain',
    'fatigue',
    'sore throat',
    'shortness of breath',
  ];
  final selected = <String>{};
  final duration = TextEditingController();
  final notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Select symptoms'),
          Wrap(
            children: symptomOptions
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s),
                      selected: selected.contains(s),
                      onSelected: (v) => setState(() => v ? selected.add(s) : selected.remove(s)),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration in days'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Additional notes'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.loading
                ? null
                : () async {
                    await ref.read(patientControllerProvider.notifier).submitSymptoms(
                          selected.toList(),
                          int.tryParse(duration.text) ?? 1,
                          notes.text,
                        );
                    if (!mounted) return;
                    final latest = ref.read(patientControllerProvider).triage;
                    if (latest != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TriageResultScreen(triage: latest)),
                      );
                    } else {
                      showInfoSnack(context, 'Saved offline. It will auto-submit when connection returns.');
                    }
                  },
            child: state.loading ? const CircularProgressIndicator() : const Text('Submit Symptoms'),
          ),
          if (state.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(state.error!)),
        ],
      ),
    );
  }
}

class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key, required this.triage});
  final dynamic triage;

  Color _statusColor(String status) {
    if (status == 'urgent') return Colors.red;
    if (status == 'self-care') return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Triage Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  triage.classification.toUpperCase(),
                  style: TextStyle(color: _statusColor(triage.classification), fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('Confidence: ${(triage.confidenceScore * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 8),
                Text(triage.recommendedAction),
                const SizedBox(height: 16),
                FilledButton(onPressed: () {}, child: const Text('Start Consultation')),
                TextButton(onPressed: () {}, child: const Text('Find Nearby Clinic')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PatientConsultationsScreen extends ConsumerWidget {
  const PatientConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Consultations')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(patientControllerProvider.notifier).loadConsultations(),
        child: ListView.builder(
          itemCount: state.consultations.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(state.consultations[i].id),
            subtitle: Text('Status: ${state.consultations[i].status}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showInfoSnack(context, 'Start consultation via /api/consultations'),
        label: const Text('Start'),
      ),
    );
  }
}

class PatientReferralsScreen extends ConsumerWidget {
  const PatientReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientControllerProvider);
    final notifier = ref.read(patientControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: FutureBuilder(
        future: notifier.loadReferrals(),
        builder: (_, snapshot) {
          if (state.loading) return const LoadingView();
          if (state.error != null) return ErrorView(message: state.error!, onRetry: notifier.loadReferrals);
          if (state.referrals.isEmpty) return const EmptyView(message: 'No referrals yet');
          return ListView.builder(
            itemCount: state.referrals.length,
            itemBuilder: (_, i) {
              final r = state.referrals[i];
              return ListTile(
                title: Text(r.facilityName),
                subtitle: Text('${r.address}\n${r.phone}\n${r.notes}'),
                isThreeLine: true,
              );
            },
          );
        },
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
  final search = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Clinic Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                labelText: 'Search facilities',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => ref.read(patientControllerProvider.notifier).loadFacilities(search: search.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.facilities.length,
              itemBuilder: (_, i) {
                final f = state.facilities[i];
                return ListTile(
                  title: Text(f.name),
                  subtitle: Text('${f.address}\n${f.phone}\n${f.latitude}, ${f.longitude}'),
                  isThreeLine: true,
                );
              },
            ),
          ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full name: ${user?.fullName ?? '-'}'),
            Text('Phone: ${user?.phoneNumber ?? '-'}'),
            Text('Anonymous ID: ${user?.anonymousId ?? '-'}'),
            const SizedBox(height: 16),
            const Text('Profile update and password forms are included as placeholders for API wiring.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
