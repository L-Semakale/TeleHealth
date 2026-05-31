import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/brand_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_controller.dart';
import '../patient/patient_controller.dart';
import 'provider_controller.dart';

class ProviderShell extends ConsumerStatefulWidget {
  const ProviderShell({super.key});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
  int _index = 0;
  String? _activeChatId;

  static const _titles = ['Dashboard', 'Consultations', 'Messages', 'Referrals', 'Clinics', 'Profile', 'Schedule'];

  void _openChat(String consultationId) {
    setState(() { _index = 2; _activeChatId = consultationId; });
    ref.read(providerControllerProvider.notifier).selectConsultation(consultationId);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 920;
    final totalUnread = ref.watch(providerControllerProvider).consultations.fold<int>(0, (s, c) => s + c.unreadCount);

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            _ProviderSidebar(selectedIndex: _index, onIndexChanged: (i) => setState(() { _index = i; if (i != 2) _activeChatId = null; })),
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                _ProviderHeader(title: _titles[_index], isDesktop: isDesktop, totalUnread: totalUnread),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey('$_index-$_activeChatId'),
                      child: _buildContent(),
                    ),
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
              onDestinationSelected: (v) => setState(() { _index = v; if (v != 2) _activeChatId = null; }),
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

  Widget _buildContent() {
    switch (_index) {
      case 0: return _ProviderDashboard(onOpenChat: _openChat, onViewAllConsultations: () => setState(() => _index = 1));
      case 1: return _ProviderInboxScreen(onOpenChat: _openChat);
      case 2: return _ProviderMessagesScreen(activeChatId: _activeChatId, onBack: () => setState(() { _activeChatId = null; _index = 1; }));
      case 3: return const _ProviderReferralsScreen();
      case 4: return const _ProviderClinicsScreen();
      case 5: return const _ProviderProfileScreen();
      case 6: return const _ProviderScheduleScreen();
      default: return const SizedBox.shrink();
    }
  }
}

class _ProviderHeader extends ConsumerWidget {
  final String title;
  final bool isDesktop;
  final int totalUnread;
  const _ProviderHeader({required this.title, required this.isDesktop, required this.totalUnread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'DR';
    final firstName = user?.fullName.split(' ').first ?? 'Doctor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            if (!isDesktop) ...[const BrandLogo(size: 30), const SizedBox(width: 14)],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                Text('Provider Portal', style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            if (isDesktop)
              Container(
                width: 220, height: 38,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
                child: Row(children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text('Search consultations…', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ]),
              ),
            // Notification bell
            GestureDetector(
              onTap: () => _showNotifications(context, ref),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
                    child: Icon(Icons.notifications_outlined, size: 18, color: Colors.grey[600]),
                  ),
                  if (totalUnread > 0)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(8)),
                        child: Text('$totalUnread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _showProfileMenu(context, ref, user?.fullName ?? 'Doctor', initials, user?.phoneNumber),
              child: Row(children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
                  child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                ),
                if (isDesktop) ...[const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Dr. $firstName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Provider', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ]), const SizedBox(width: 4), Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[400])],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final consultations = ref.read(providerControllerProvider).consultations;
    final unread = consultations.where((c) => c.unreadCount > 0).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.notifications_outlined, size: 20),
              const SizedBox(width: 8),
              const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (unread.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(10)),
                  child: Text('${unread.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 16),
            if (unread.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Column(children: [
                  Icon(Icons.notifications_none, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('No new notifications', style: TextStyle(color: Colors.grey[400])),
                ])),
              )
            else
              ...unread.take(5).map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1565C0), size: 18),
                ),
                title: Text('Message from ${c.patientAnonymousId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(c.lastMessagePreview.isNotEmpty ? c.lastMessagePreview : 'Tap to view', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(10)),
                  child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              )),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref, String fullName, String initials, String? phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.12))),
              child: Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
                  child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. $fullName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  if (phone != null && phone.isNotEmpty) Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Provider', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            _MenuTile(icon: Icons.person_outline, label: 'My Profile', accentColor: const Color(0xFF1565C0), onTap: () { Navigator.pop(ctx); }),
            _MenuTile(icon: Icons.settings_outlined, label: 'Settings', accentColor: const Color(0xFF1565C0), onTap: () { Navigator.pop(ctx); }),
            _MenuTile(icon: Icons.help_outline, label: 'Help & Support', accentColor: const Color(0xFF1565C0), onTap: () { Navigator.pop(ctx); }),
            const Divider(height: 24),
            _MenuTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? accentColor;
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[800]!;
    final ac = accentColor ?? c;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: ac.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c)),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}

class _ProviderSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  const _ProviderSidebar({required this.selectedIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final state = ref.watch(providerControllerProvider);
    final totalUnread = state.consultations.fold<int>(0, (s, c) => s + c.unreadCount);
    final urgentCount = state.consultations.where((c) => c.triageClassification == 'urgent' && c.status == 'open').length;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'DR';
    return Container(
      width: 272,
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(right: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: Column(
        children: [
          // ── Brand logo area ───────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1F2937)))),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/logo.png', width: 38, height: 38, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TeleHealth', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Provider Portal', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ]),
            ]),
          ),
          // ── User card ─────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF374151)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.3),
                child: Text(initials, style: const TextStyle(color: Color(0xFF90CAF9), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? 'Provider', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Healthcare Provider', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('MD', style: TextStyle(color: Color(0xFF90CAF9), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          // ── Navigation ────────────────────────────────
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: Text('NAVIGATION', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', selected: selectedIndex == 0, onTap: () => onIndexChanged(0), accentColor: const Color(0xFF1565C0)),
          _SidebarItem(icon: Icons.medical_services_rounded, label: 'Consultations', selected: selectedIndex == 1, onTap: () => onIndexChanged(1), badge: urgentCount > 0 ? urgentCount : null, accentColor: const Color(0xFF1565C0)),
          _SidebarItem(icon: Icons.chat_rounded, label: 'Messages', selected: selectedIndex == 2, onTap: () => onIndexChanged(2), badge: totalUnread > 0 ? totalUnread : null, accentColor: const Color(0xFF1565C0)),
          _SidebarItem(icon: Icons.assignment_rounded, label: 'Referrals', selected: selectedIndex == 3, onTap: () => onIndexChanged(3), accentColor: const Color(0xFF1565C0)),
          _SidebarItem(icon: Icons.local_hospital_rounded, label: 'Clinics', selected: selectedIndex == 4, onTap: () => onIndexChanged(4), accentColor: const Color(0xFF1565C0)),
          _SidebarItem(icon: Icons.schedule_rounded, label: 'Schedule', selected: selectedIndex == 6, onTap: () => onIndexChanged(6), accentColor: const Color(0xFF1565C0)),
          const Spacer(),
          // ── Bottom section ────────────────────────────
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: Text('ACCOUNT', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          _SidebarItem(icon: Icons.person_rounded, label: 'My Profile', selected: selectedIndex == 5, onTap: () => onIndexChanged(5), accentColor: const Color(0xFF1565C0)),
          _SidebarItem(
            icon: Icons.logout_rounded, label: 'Sign Out', selected: false, danger: true,
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 20),
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
  final bool danger;
  final int? badge;
  final Color? accentColor;
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap, this.danger = false, this.badge, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? const Color(0xFF1565C0);
    final Color fg = selected ? Colors.white : danger ? Colors.red[400]! : Colors.grey[400]!;
    return Semantics(
      label: label, selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Container(
                width: 3, height: 18,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: fg, size: 19),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: fg, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 13.5))),
              if (badge != null && badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFD6246F), borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ProviderInboxScreen extends ConsumerStatefulWidget {
  final void Function(String consultationId) onOpenChat;
  const _ProviderInboxScreen({required this.onOpenChat});

  @override
  ConsumerState<_ProviderInboxScreen> createState() => _ProviderInboxScreenState();
}

class _ProviderInboxScreenState extends ConsumerState<_ProviderInboxScreen> {
  String _filter = 'all';

  static const _urgencyOrder = {'urgent': 0, 'routine': 1, 'self-care': 2};

  List<Consultation> _sorted(List<Consultation> list) {
    final filtered = (_filter == 'all' ? list : list.where((c) => c.triageClassification == _filter || (_filter == 'open' && c.status == 'open') || (_filter == 'closed' && c.status == 'closed'))).toList();
    return filtered..sort((a, b) {
      final ua = _urgencyOrder[a.triageClassification] ?? 1;
      final ub = _urgencyOrder[b.triageClassification] ?? 1;
      if (ua != ub) return ua.compareTo(ub);
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  void _refreshConsultations(BuildContext context) {
    ref.read(providerControllerProvider.notifier).loadConsultations(refresh: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consultations refreshed. Patients start new chats from their app.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerControllerProvider);
    if (state.loading && state.consultations.isEmpty) return const LoadingView(message: 'Loading consultations...');
    final sorted = _sorted(state.consultations);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final f in [('all', 'All'), ('open', 'Open'), ('closed', 'Closed'), ('urgent', 'Urgent'), ('routine', 'Routine')])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f.$2),
                              selected: _filter == f.$1,
                              onSelected: (_) => setState(() => _filter = f.$1),
                              selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
                              checkmarkColor: const Color(0xFF1565C0),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _refreshConsultations(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: sorted.isEmpty
                  ? const EmptyView(message: 'No consultations match this filter.', icon: Icons.inbox_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: sorted.length,
                      itemBuilder: (_, i) {
                        final c = sorted[i];
                        return _ConsultationCard(consultation: c, onOpenChat: widget.onOpenChat);
                      },
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final Consultation consultation;
  final void Function(String) onOpenChat;
  const _ConsultationCard({required this.consultation, required this.onOpenChat});

  Color get _triageColor {
    switch (consultation.triageClassification) {
      case 'urgent': return Colors.red;
      case 'routine': return Colors.blue;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpenChat(c.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 4, height: 64, decoration: BoxDecoration(color: _triageColor, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(c.patientAnonymousId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 8),
                      _TriageBadge(classification: c.triageClassification, color: _triageColor),
                      const Spacer(),
                      _StatusBadge(status: c.status),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      c.lastMessagePreview.isNotEmpty ? c.lastMessagePreview : 'No messages yet',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(c.waitingLabel, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      const SizedBox(width: 12),
                      if (c.lastMessageAt != null) ...[  
                        Icon(Icons.chat_bubble_outline, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM, HH:mm').format(c.lastMessageAt!), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ],
                    ]),
                  ],
                ),
              ),
              if (c.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(12)),
                  child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

class _TriageBadge extends StatelessWidget {
  final String classification;
  final Color color;
  const _TriageBadge({required this.classification, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(classification.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'open' ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _ProviderMessagesScreen extends ConsumerStatefulWidget {
  final String? activeChatId;
  final VoidCallback onBack;
  const _ProviderMessagesScreen({this.activeChatId, required this.onBack});

  @override
  ConsumerState<_ProviderMessagesScreen> createState() => _ProviderMessagesScreenState();
}

class _ProviderMessagesScreenState extends ConsumerState<_ProviderMessagesScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final id = widget.activeChatId;
    if (id != null) {
      ref.read(providerControllerProvider.notifier).selectConsultation(id);
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final sid = widget.activeChatId ?? ref.read(providerControllerProvider).selectedConsultationId;
      if (sid != null) ref.read(providerControllerProvider.notifier).selectConsultation(sid);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerControllerProvider);
    final id = widget.activeChatId ?? state.selectedConsultationId;

    if (id == null) {
      return EmptyView(
        message: 'Select a consultation to open the chat.',
        icon: Icons.chat_bubble_outline,
      );
    }

    final consultation = state.consultations.where((c) => c.id == id).firstOrNull;
    final triageColor = consultation?.triageClassification == 'urgent' ? Colors.red : (consultation?.triageClassification == 'routine' ? Colors.blue : Colors.green);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(consultation?.patientAnonymousId ?? id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (consultation != null)
                Row(children: [
                  _TriageBadge(classification: consultation.triageClassification, color: triageColor),
                  const SizedBox(width: 8),
                  Text(consultation.waitingLabel, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ]),
            ])),
            if (consultation?.status == 'open')
              Semantics(
                label: 'Close consultation',
                child: TextButton.icon(
                  onPressed: () => _closeConsultation(context, id),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Close'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
              ),
            Semantics(
              label: 'Issue referral',
              child: TextButton.icon(
                onPressed: () => _issueReferral(context, ref, id),
                icon: const Icon(Icons.assignment_outlined, size: 16),
                label: const Text('Referral'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFD6246F)),
              ),
            ),
          ]),
        ),
        if (state.loading && state.messages.isEmpty)
          const Expanded(child: LoadingView(message: 'Loading messages...'))
        else if (state.messages.isEmpty)
          const Expanded(child: Center(child: Text('No messages yet. Send the first message.', style: TextStyle(color: Colors.grey))))
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: state.messages.length,
              itemBuilder: (_, i) {
                final m = state.messages[i];
                final isMe = m.senderRole == 'provider';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFD6246F) : Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Text(m.body, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                          ),
                          const SizedBox(height: 3),
                          Text(DateFormat('HH:mm').format(m.createdAt), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (consultation?.status == 'open' || consultation == null)
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
                child: IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFFD6246F)), onPressed: _send),
              ),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.all(16), color: Colors.grey[50],
            child: const Center(child: Text('This consultation has been closed.', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    ref.read(providerControllerProvider.notifier).sendMessage(text);
    _msgController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _closeConsultation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Consultation'),
        content: const Text('Mark this consultation as closed? The patient will no longer be able to send messages.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); ref.read(providerControllerProvider.notifier).closeConsultation(id); },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Close Consultation'),
          ),
        ],
      ),
    );
  }

  void _issueReferral(BuildContext context, WidgetRef ref, String consultationId) {
    final notes = TextEditingController();
    String? selectedFacilityId;
    String? error;

    // Load facilities from API
    ref.read(providerControllerProvider.notifier).loadFacilitiesForReferral();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final facilitiesState = ref.watch(providerControllerProvider);
          final facilities = facilitiesState.facilities;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Issue Referral'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (facilities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: CircularProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Clinic',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true, fillColor: Colors.grey[50],
                    ),
                    items: facilities.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setDlg(() => selectedFacilityId = v),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes for Patient',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.grey[50],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (selectedFacilityId == null) {
                    setDlg(() => error = 'Please select a clinic');
                    return;
                  }
                  Navigator.pop(ctx);
                  ref.read(providerControllerProvider.notifier).issueReferral(consultationId, selectedFacilityId!, notes.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral issued successfully.')));
                },
                child: const Text('Issue Referral'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProviderReferralsScreen extends ConsumerStatefulWidget {
  const _ProviderReferralsScreen();
  @override
  ConsumerState<_ProviderReferralsScreen> createState() => _ProviderReferralsScreenState();
}

class _ProviderReferralsScreenState extends ConsumerState<_ProviderReferralsScreen> {
  final List<_IssuedReferral> _issued = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(providerControllerProvider.notifier).loadConsultations(refresh: true);
    });
  }

  void _showIssueReferral(BuildContext context) {
    final state = ref.read(providerControllerProvider);
    final consultations = state.consultations.where((c) => c.status == 'open').toList();
    String? selectedConsultId;
    String? selectedFacilityId;
    final notesCtrl = TextEditingController();
    String? error;

    // Load facilities from API
    ref.read(providerControllerProvider.notifier).loadFacilitiesForReferral();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final facilitiesState = ref.watch(providerControllerProvider);
          final facilities = facilitiesState.facilities;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.assignment_outlined, color: Color(0xFFD6246F)),
              SizedBox(width: 10),
              Text('Issue Referral'),
            ]),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Select an open consultation:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Consultation',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.grey[50],
                  ),
                  items: consultations.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.patientAnonymousId} — ${c.id.substring(0, 8)}', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDlg(() => selectedConsultId = v),
                ),
                const SizedBox(height: 14),
                const Text('Select a clinic:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                if (facilities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Clinic / Facility',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true, fillColor: Colors.grey[50],
                    ),
                    items: facilities.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setDlg(() => selectedFacilityId = v),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes for Patient',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.grey[50],
                  ),
                ),
                if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD6246F)),
                onPressed: () {
                  if (selectedConsultId == null) {
                    setDlg(() => error = 'Please select a consultation');
                    return;
                  }
                  if (selectedFacilityId == null) {
                    setDlg(() => error = 'Please select a clinic');
                    return;
                  }
                  Navigator.pop(ctx);
                  final consult = consultations.firstWhere((c) => c.id == selectedConsultId!);
                  ref.read(providerControllerProvider.notifier).issueReferral(
                    selectedConsultId!, selectedFacilityId!, notesCtrl.text.trim());
                  setState(() {
                    _issued.add(_IssuedReferral(
                      patientId: consult.patientAnonymousId,
                      consultationId: selectedConsultId!,
                      notes: notesCtrl.text.trim(),
                      date: DateTime.now(),
                    ));
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral issued successfully.')));
                },
                child: const Text('Issue Referral'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showIssueReferral(context),
        backgroundColor: const Color(0xFFD6246F),
        tooltip: 'Issue Referral',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _issued.isEmpty
          ? const EmptyView(
              message: 'No referrals issued yet.\nTap + to issue a referral for a patient.',
              icon: Icons.assignment_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
              itemCount: _issued.length,
              itemBuilder: (_, i) {
                final r = _issued[_issued.length - 1 - i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(padding: const EdgeInsets.all(16), child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.assignment_outlined, color: Color(0xFFD6246F), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.patientId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Consult #${r.consultationId.substring(0, 8)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        if (r.notes.isNotEmpty) ...[const SizedBox(height: 4), Text(r.notes, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13))],
                      ])),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('ISSUED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Text('${r.date.day}/${r.date.month}/${r.date.year}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ]),
                    ],
                  )),
                );
              },
            ),
    );
  }
}

class _IssuedReferral {
  final String patientId;
  final String consultationId;
  final String notes;
  final DateTime date;
  const _IssuedReferral({required this.patientId, required this.consultationId, required this.notes, required this.date});
}

class _ProviderClinicsScreen extends ConsumerStatefulWidget {
  const _ProviderClinicsScreen();
  @override
  ConsumerState<_ProviderClinicsScreen> createState() => _ProviderClinicsScreenState();
}

class _ProviderClinicsScreenState extends ConsumerState<_ProviderClinicsScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(patientControllerProvider.notifier).loadFacilities();
    });
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search facilities...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _search.clear(); ref.read(patientControllerProvider.notifier).loadFacilities(); setState(() {}); })
                  : null,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) => ref.read(patientControllerProvider.notifier).loadFacilities(search: v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.loading
              ? const LoadingView(message: 'Searching facilities...')
              : state.facilities.isEmpty
                  ? const EmptyView(message: 'No facilities found.', icon: Icons.local_hospital_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      itemCount: state.facilities.length,
                      itemBuilder: (_, i) {
                        final f = state.facilities[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.local_hospital_outlined, color: Color(0xFF1565C0), size: 20),
                            ),
                            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 3),
                                Expanded(child: Text(f.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                              ]),
                              if (f.phone.isNotEmpty)
                                Row(children: [
                                  Icon(Icons.phone_outlined, size: 12, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  Text(f.phone, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ]),
                            ]),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ProviderProfileScreen extends ConsumerWidget {
  const _ProviderProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'DR';
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Gradient hero ─────────────────────────────────
          Stack(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF5B4AA0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                  InkWell(
                    onTap: () => _showEditProfile(context, ref, user),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 14, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(user?.fullName ?? 'Provider', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_outlined, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text('Healthcare Provider', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 6),
              Text(user?.phoneNumber ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
            ]),
          ),
          const NoiseOverlay(opacity: 0.08),
          ]),
          // ── Settings groups ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProviderSettingsGroup(
                  label: 'Account',
                  items: [
                    _ProviderSettingsTile(icon: Icons.person_outline, title: 'Full Name', value: user?.fullName ?? 'N/A', color: const Color(0xFF1565C0), onTap: () => _showEditProfile(context, ref, user)),
                    _ProviderSettingsTile(icon: Icons.phone_outlined, title: 'Phone Number', value: user?.phoneNumber ?? 'N/A', color: const Color(0xFF1565C0)),
                    _ProviderSettingsTile(icon: Icons.security_outlined, title: 'Account Security', value: 'Change Password', color: const Color(0xFF1565C0), onTap: () {}),
                  ],
                ),
                const SizedBox(height: 16),
                _ProviderSettingsGroup(
                  label: 'Preferences',
                  items: [
                    _ProviderSettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', value: 'Enabled', color: const Color(0xFF1565C0), onTap: () {}),
                    _ProviderSettingsTile(icon: Icons.language_outlined, title: 'Language', value: 'English', color: const Color(0xFF1565C0), onTap: () {}),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Sign Out')),
                        ],
                      ));
                      if (confirmed == true) {
                        await ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, dynamic user) {
    final name = TextEditingController(text: user?.fullName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Provider Profile'),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await ref.read(authControllerProvider.notifier).updateProfile(fullName: name.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Profile updated.' : ref.read(authControllerProvider).error ?? 'Update failed')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProviderSettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> items;
  const _ProviderSettingsGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: items.map((item) {
              final idx = items.indexOf(item);
              return Column(children: [
                item,
                if (idx < items.length - 1) Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProviderSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const _ProviderSettingsTile({required this.icon, required this.title, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 18, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}

class _ProviderDashboard extends ConsumerWidget {
  final void Function(String) onOpenChat;
  final VoidCallback? onViewAllConsultations;
  const _ProviderDashboard({required this.onOpenChat, this.onViewAllConsultations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final open = state.consultations.where((e) => e.status == 'open').length;
    final urgent = state.consultations.where((e) => e.triageClassification == 'urgent' && e.status == 'open').length;
    final total = state.consultations.length;
    final completed = total - open;
    final recent = (state.consultations.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(5).toList();
    final firstName = user?.fullName.split(' ').first ?? 'Doctor';
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'DR';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ─────────────────────────────────────
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ① Banner image — full bleed
                  Image.asset(
                    'assets/images/doctor_banner.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                  // ② Gradient scrim — left dark, right transparent
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.78), Colors.black.withValues(alpha: 0.15)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  const NoiseOverlay(opacity: 0.07, borderRadius: BorderRadius.all(Radius.circular(24))),
                  // ③ Content
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset('assets/logo.png', width: 30, height: 30, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 8),
                                Text('Welcome, Dr. $firstName', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                urgent > 0 ? '⚠️ $urgent urgent case${urgent > 1 ? 's' : ''} need attention' : 'All cases are up to date',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              Row(children: [
                                _DashStatPill(label: '$open', sublabel: 'Open', icon: Icons.pending_actions_outlined),
                                const SizedBox(width: 10),
                                _DashStatPill(label: '$urgent', sublabel: 'Urgent', icon: Icons.warning_amber_outlined),
                                const SizedBox(width: 10),
                                _DashStatPill(label: '$completed', sublabel: 'Done', icon: Icons.check_circle_outline),
                              ]),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          // ── Stat cards row ────────────────────────────────
          Row(children: [
            Expanded(child: _StatCard(title: 'Active', value: '$open', icon: Icons.pending_actions, color: const Color(0xFF1565C0))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: 'Urgent', value: '$urgent', icon: Icons.warning_amber_rounded, color: const Color(0xFFE53935))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: 'Completed', value: '$completed', icon: Icons.check_circle_outline, color: const Color(0xFF2E7D32))),
          ]),
          const SizedBox(height: 28),
          // ── Recent consultations ──────────────────────────
          _DashSectionHeader(title: 'Recent Consultations', actionLabel: 'View All', onAction: onViewAllConsultations),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            const EmptyView(message: 'No consultations yet.', icon: Icons.inbox_outlined)
          else
            ...recent.map((c) => _ConsultationCard(consultation: c, onOpenChat: onOpenChat)),
        ],
      ),
    );
  }
}

class _DashStatPill extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  const _DashStatPill({required this.label, required this.sublabel, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.1)),
          Text(sublabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9)),
        ]),
      ]),
    );
  }
}

class _DashSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _DashSectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF1565C0), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
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
        color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
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

class _ProviderScheduleScreen extends ConsumerStatefulWidget {
  const _ProviderScheduleScreen();

  @override
  ConsumerState<_ProviderScheduleScreen> createState() => _ProviderScheduleScreenState();
}

class _ProviderScheduleScreenState extends ConsumerState<_ProviderScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerControllerProvider.notifier).loadProviderSchedule();
    });
  }

  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerControllerProvider);
    final schedules = state.schedules;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Availability Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: () => _showAddScheduleDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Schedule'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Set your working hours so patients can book appointments with you.', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          if (state.loading && schedules.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (schedules.isEmpty)
            EmptyView(
              message: 'No schedule set yet.\nAdd your working hours to start receiving bookings.',
              icon: Icons.schedule_outlined,
              actionLabel: 'Add Schedule',
              onAction: () => _showAddScheduleDialog(context),
            )
          else
            ...schedules.map((s) => _ScheduleCard(
              schedule: s,
              dayName: _dayNames[s.dayOfWeek],
              onToggle: () => _toggleAvailability(s),
              onDelete: () => _confirmDelete(s),
            )),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    int selectedDay = 1;
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '17:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.schedule, color: Color(0xFF1565C0)),
          SizedBox(width: 10),
          Text('Add Working Hours'),
        ]),
        content: StatefulBuilder(
          builder: (ctx, setDlg) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Day', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final isSelected = selectedDay == i;
                  return ChoiceChip(
                    label: Text(_dayNames[i]),
                    selected: isSelected,
                    onSelected: (_) => setDlg(() => selectedDay = i),
                    selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.2),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Start Time', hintText: '09:00'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'End Time', hintText: '17:00'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(providerControllerProvider.notifier).addSchedule(
                dayOfWeek: selectedDay,
                startTime: startCtrl.text,
                endTime: endCtrl.text,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(ProviderSchedule schedule) {
    ref.read(providerControllerProvider.notifier).updateSchedule(
      schedule.id,
      isAvailable: !schedule.isAvailable,
    );
  }

  void _confirmDelete(ProviderSchedule schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Schedule?'),
        content: Text('Remove your ${_dayNames[schedule.dayOfWeek]} schedule (${schedule.startTime} - ${schedule.endTime})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(providerControllerProvider.notifier).deleteSchedule(schedule.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ProviderSchedule schedule;
  final String dayName;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.dayName,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: schedule.isAvailable ? const Color(0xFF1565C0).withValues(alpha: 0.3) : Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: schedule.isAvailable ? const Color(0xFF1565C0).withValues(alpha: 0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: schedule.isAvailable ? const Color(0xFF1565C0) : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${schedule.startTime} - ${schedule.endTime}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: schedule.isAvailable ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.isAvailable ? 'Available for bookings' : 'Temporarily unavailable',
                    style: TextStyle(fontSize: 13, color: schedule.isAvailable ? Colors.green : Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: schedule.isAvailable,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF1565C0),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
