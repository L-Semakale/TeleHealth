import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models.dart';
import '../../core/utils/formatters.dart';
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
    'Referrals', 'Clinic Directory', 'My Profile', 'Appointments',
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 920;

    final pages = [
      PatientHomeScreen(onNavigate: _navigate),
      SymptomReportScreen(onNavigate: _navigate),
      PatientConsultationsScreen(openConsultationId: _openConsultationId, onNavigate: _navigate),
      const PatientReferralsScreen(),
      const PatientClinicsScreen(),
      const PatientProfileScreen(),
      PatientAppointmentsScreen(onNavigate: _navigate),
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
                const OfflineBanner(),
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
          ? Consumer(builder: (context, ref, _) {
              final totalUnread = ref.watch(patientControllerProvider
                  .select((s) => s.consultations.fold(0, (sum, c) => sum + c.unreadCount)));
              return NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (v) => setState(() { _index = v; _openConsultationId = null; }),
                destinations: [
                  const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                  const NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Symptoms'),
                  NavigationDestination(
                    icon: Badge(isLabelVisible: totalUnread > 0, label: Text('$totalUnread'), child: const Icon(Icons.chat_bubble_outline)),
                    selectedIcon: Badge(isLabelVisible: totalUnread > 0, label: Text('$totalUnread'), child: const Icon(Icons.chat_bubble)),
                    label: 'Consults',
                  ),
                  const NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Referrals'),
                  const NavigationDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: 'Clinics'),
                  const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
                  const NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Bookings'),
                ],
              );
            })
          : null,
    );
  }
}

class _PatientHeader extends ConsumerWidget {
  final String title;
  final bool isDesktop;
  const _PatientHeader({required this.title, required this.isDesktop});

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final ps = ref.read(patientControllerProvider);
    final unread = ps.consultations.where((c) => c.unreadCount > 0).toList();
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
                  decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(10)),
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
                  backgroundColor: const Color(0xFFD6246F).withValues(alpha: 0.1),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD6246F), size: 18),
                ),
                title: Text('New message from Dr. ${c.providerId.isNotEmpty ? c.providerId : 'Provider'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${c.unreadCount} unread message${c.unreadCount > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFD6246F), shape: BoxShape.circle),
                ),
              )),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref, String firstName, String initials, String? phone) {
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
            // User card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD6246F).withValues(alpha: 0.12))),
              child: Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFD6246F).withValues(alpha: 0.15),
                  child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD6246F))),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(firstName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  if (phone != null && phone.isNotEmpty) Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Patient', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD6246F))),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            _MenuTile(icon: Icons.person_outline, label: 'My Profile', onTap: () { Navigator.pop(ctx); }),
            _MenuTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () { Navigator.pop(ctx); }),
            _MenuTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () { Navigator.pop(ctx); }),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final ps = ref.watch(patientControllerProvider);
    final unreadCount = ps.consultations.fold<int>(0, (s, c) => s + c.unreadCount);
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'P';
    final firstName = user?.fullName ?? 'Patient';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
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
                Text('Patient Portal', style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
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
                  Text('Search…', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ]),
              ),
            if (user?.anonymousId != null && user!.anonymousId.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6246F).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD6246F).withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.fingerprint, size: 12, color: Color(0xFFD6246F)),
                  const SizedBox(width: 4),
                  Text(user.anonymousId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD6246F), letterSpacing: 0.5)),
                ]),
              ),
            // ── Notification bell with dropdown ───────────────────
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
                  if (unreadCount > 0)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(8)),
                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── Avatar with profile menu ─────────────────────────
            GestureDetector(
              onTap: () => _showProfileMenu(context, ref, firstName, initials, user?.phoneNumber),
              child: Row(children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFD6246F).withValues(alpha: 0.12),
                  child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD6246F))),
                ),
                if (isDesktop) ...[const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(firstName.split(' ').first, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Patient', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ]), const SizedBox(width: 4), Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[400])],
              ]),
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
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[800]!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c)),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}

class _PatientSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  const _PatientSidebar({required this.selectedIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final ps = ref.watch(patientControllerProvider);
    final unreadConsults = ps.consultations.fold<int>(0, (s, c) => s + c.unreadCount);
    final newReferrals = ps.referrals.where((r) => r.status == ReferralStatus.newReferral).length;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'P';
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
                Text('Patient Portal', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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
                backgroundColor: const Color(0xFFD6246F).withValues(alpha: 0.25),
                child: Text(initials, style: const TextStyle(color: Color(0xFFD6246F), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? 'Patient', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(user?.phoneNumber ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('Patient', style: TextStyle(color: Color(0xFFD6246F), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          // ── Navigation ────────────────────────────────
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: Text('NAVIGATION', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          _SidebarItem(icon: Icons.home_rounded, label: 'Dashboard', selected: selectedIndex == 0, onTap: () => onIndexChanged(0)),
          _SidebarItem(icon: Icons.monitor_heart_rounded, label: 'Symptom Report', selected: selectedIndex == 1, onTap: () => onIndexChanged(1)),
          _SidebarItem(icon: Icons.chat_bubble_rounded, label: 'My Consultations', selected: selectedIndex == 2, onTap: () => onIndexChanged(2), badge: unreadConsults > 0 ? unreadConsults : null),
          _SidebarItem(icon: Icons.assignment_rounded, label: 'Referrals', selected: selectedIndex == 3, onTap: () => onIndexChanged(3), badge: newReferrals > 0 ? newReferrals : null),
          _SidebarItem(icon: Icons.local_hospital_rounded, label: 'Clinic Directory', selected: selectedIndex == 4, onTap: () => onIndexChanged(4)),
          _SidebarItem(icon: Icons.calendar_today_rounded, label: 'Appointments', selected: selectedIndex == 6, onTap: () => onIndexChanged(6)),
          const Spacer(),
          // ── Bottom section ────────────────────────────
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: Text('ACCOUNT', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          _SidebarItem(icon: Icons.person_rounded, label: 'My Profile', selected: selectedIndex == 5, onTap: () => onIndexChanged(5)),
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
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap, this.danger = false, this.badge});

  @override
  Widget build(BuildContext context) {
    final Color fg = selected
        ? Colors.white
        : danger
            ? Colors.red[400]!
            : Colors.grey[400]!;
    return Semantics(
      label: label, selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFD6246F) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              // left accent bar for selected
              Container(
                width: 3, height: 18,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.6) : Colors.transparent,
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
                  child: Text('$badge', style: TextStyle(color: selected ? Colors.white : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title, button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    NoiseOverlay(opacity: 0.10, borderRadius: BorderRadius.circular(12)),
                  ],
                ),
                const Spacer(),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String tip;
  const _HealthTipCard({required this.icon, required this.color, required this.title, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const SizedBox(height: 4),
                Text(tip, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  final void Function(int, {String? consultationId})? onNavigate;
  const _EmptyHomeState({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFFD6246F).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6246F).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFD6246F).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_outlined, size: 40, color: Color(0xFFD6246F)),
          ),
          const SizedBox(height: 16),
          const Text('Your health journey starts here', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Report symptoms to get AI triage, then connect with a doctor from your dashboard.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => onNavigate?.call(1),
            icon: const Icon(Icons.monitor_heart_outlined, size: 18),
            label: const Text('Report Symptoms Now'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD6246F), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }
}

class SymptomReportScreen extends ConsumerStatefulWidget {
  final void Function(int, {String? consultationId})? onNavigate;
  const SymptomReportScreen({super.key, this.onNavigate});

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
      return _TriageResultView(result: _result!, onReset: () => setState(() => _result = null), onNavigate: widget.onNavigate);
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
                if (!mounted) return;
                if (result != null) {
                  setState(() => _result = result);
                } else if (ref.read(patientControllerProvider).error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 10),
                        Expanded(child: Text('You\'re offline — symptoms saved and will be submitted automatically when you reconnect.')),
                      ]),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
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

class _TriageResultView extends ConsumerWidget {
  final TriageResult result;
  final VoidCallback onReset;
  final void Function(int, {String? consultationId})? onNavigate;
  const _TriageResultView({required this.result, required this.onReset, this.onNavigate});

  Color get _color {
    switch (result.classification.toLowerCase()) {
      case 'urgent': return Colors.red;
      case 'routine': return Colors.blue;
      default: return Colors.green;
    }
  }

  String get _urgencyMessage {
    switch (result.classification.toLowerCase()) {
      case 'urgent': return 'Visit clinic immediately';
      case 'routine': return 'Consult a provider soon';
      default: return 'Monitor symptoms at home';
    }
  }

  String get _explanation {
    if (result.recommendedAction.isNotEmpty) {
      return result.recommendedAction;
    }
    // Fallback explanations if backend doesn't return recommended_action
    switch (result.classification.toLowerCase()) {
      case 'urgent':
        return 'Visit a clinic or hospital immediately.';
      case 'routine':
        return 'Book a consultation with a provider within the next few days.';
      case 'self-care':
        return 'Monitor your symptoms at home. Consult a provider if symptoms worsen.';
      default:
        return 'Book a consultation with a provider within the next few days.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(radius: 40, backgroundColor: _color.withValues(alpha: 0.1), child: Icon(Icons.monitor_heart, color: _color, size: 40)),
          const SizedBox(height: 20),
          Text(result.classification.toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _color)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(_urgencyMessage, style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          Text(_explanation, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 8),
          Text('Confidence: ${(result.confidenceScore * 100).toStringAsFixed(0)}%', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 54,
            child: FilledButton.icon(
              onPressed: () async {
                final consultation = await ref
                    .read(patientControllerProvider.notifier)
                    .startConsultation(reportId: result.reportId);
                if (!context.mounted) return;
                if (consultation != null) {
                  onNavigate?.call(2, consultationId: consultation.id);
                } else {
                  final err = ref.read(patientControllerProvider).error;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  }
                }
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Start Consultation'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 54,
            child: FilledButton.icon(
              onPressed: () => onNavigate?.call(0),
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text('Return to Dashboard'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 54,
            child: OutlinedButton.icon(
              onPressed: () => onNavigate?.call(4),
              icon: const Icon(Icons.local_hospital_outlined, size: 18),
              label: const Text('Find Clinic'),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Submit New Report'),
          ),
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
    final firstName = user?.fullName.split(' ').first ?? 'Patient';
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'P';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 20, isMobile ? 16 : 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero card ─────────────────────────────────────
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/patient_banner.jpg', fit: BoxFit.cover, alignment: Alignment.centerRight),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.82), Colors.black.withValues(alpha: 0.10)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.75],
                      ),
                    ),
                  ),
                  const NoiseOverlay(opacity: 0.07, borderRadius: BorderRadius.all(Radius.circular(28))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withValues(alpha: 0.22),
                              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                              Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, height: 1.1)),
                            ]),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                const Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ],
                        ),
                        // Bottom stats row
                        Row(
                          children: [
                            _HeroStatPill(label: '${activeConsults.length}', sublabel: 'Consults', icon: Icons.chat_bubble_outline),
                            const SizedBox(width: 10),
                            _HeroStatPill(label: '${newReferrals.length}', sublabel: 'Referrals', icon: Icons.assignment_outlined),
                            const SizedBox(width: 10),
                            _HeroStatPill(label: ps.triage != null ? ps.triage!.classification.toUpperCase() : 'N/A', sublabel: 'Triage', icon: Icons.health_and_safety_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Triage alert banner ────────────────────────────
          if (ps.triage != null) ...[
            _TriageCard(triage: ps.triage!, onNavigate: onNavigate),
            const SizedBox(height: 24),
          ],

          // ── Quick Actions ──────────────────────────────────
          _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: isMobile ? 1.1 : 1.15,
            children: [
              _QuickActionCard(
                title: 'Report Symptoms',
                subtitle: 'AI-powered triage',
                icon: Icons.monitor_heart_outlined,
                color: const Color(0xFFE53935),
                onTap: () => onNavigate?.call(1),
              ),
              _QuickActionCard(
                title: 'Consult Doctor',
                subtitle: 'Chat with a provider',
                icon: Icons.medical_services_outlined,
                color: const Color(0xFF2E7D32),
                onTap: () => _showConsultModal(context, ref, ps.triage, onNavigate),
              ),
              _QuickActionCard(
                title: 'Find a Clinic',
                subtitle: 'Nearby facilities',
                icon: Icons.local_hospital_outlined,
                color: const Color(0xFF1565C0),
                onTap: () => onNavigate?.call(4),
              ),
              _QuickActionCard(
                title: 'My Referrals',
                subtitle: '${newReferrals.length} new',
                icon: Icons.assignment_outlined,
                color: const Color(0xFF6A1B9A),
                onTap: () => onNavigate?.call(3),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Health Tips ────────────────────────────────────
          _SectionHeader(title: 'Health Tips'),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: const [
                _HealthTipCard(icon: Icons.water_drop_outlined, color: Color(0xFF0288D1), title: 'Stay Hydrated', tip: 'Drink 8 glasses of water daily to maintain good health.'),
                _HealthTipCard(icon: Icons.directions_run, color: Color(0xFF2E7D32), title: 'Stay Active', tip: '30 minutes of exercise daily reduces disease risk by 35%.'),
                _HealthTipCard(icon: Icons.bedtime_outlined, color: Color(0xFF6A1B9A), title: 'Sleep Well', tip: 'Adults need 7–9 hours of sleep for optimal recovery.'),
                _HealthTipCard(icon: Icons.restaurant_menu, color: Color(0xFFE65100), title: 'Eat Balanced', tip: 'Include vegetables, proteins and whole grains every day.'),
              ],
            ),
          ),

          // ── Active Consultations ───────────────────────────
          if (activeConsults.isNotEmpty) ...[
            const SizedBox(height: 28),
            _SectionHeader(title: 'Active Consultations', actionLabel: 'See All', onAction: () => onNavigate?.call(2)),
            const SizedBox(height: 14),
            ...activeConsults.take(3).map((c) => _ConsultTile(consultation: c, onNavigate: onNavigate)),
          ],

          // ── Recent Referrals ───────────────────────────────
          if (ps.referrals.isNotEmpty) ...[
            const SizedBox(height: 28),
            _SectionHeader(title: 'Recent Referrals', actionLabel: 'See All', onAction: () => onNavigate?.call(3)),
            const SizedBox(height: 14),
            _RecentReferralsSection(referrals: ps.referrals, onNavigate: onNavigate),
          ],

          // ── Empty state ────────────────────────────────────
          if (activeConsults.isEmpty && ps.referrals.isEmpty && ps.triage == null) ...[
            const SizedBox(height: 28),
            _EmptyHomeState(onNavigate: onNavigate),
          ],
        ],
      ),
    );
  }

  Future<void> _startConsultation(
    BuildContext context,
    WidgetRef ref,
    void Function(int, {String? consultationId})? onNavigate, {
    String? reportId,
  }) async {
    final consultation = await ref
        .read(patientControllerProvider.notifier)
        .startConsultation(reportId: reportId);
    if (!context.mounted) return;
    if (consultation != null) {
      onNavigate?.call(2, consultationId: consultation.id);
    } else {
      final err = ref.read(patientControllerProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  void _showConsultModal(BuildContext context, WidgetRef ref, TriageResult? triage, void Function(int, {String? consultationId})? onNavigate) {
    final openConsult = ref.read(patientControllerProvider).consultations.any((c) => c.status == 'open');
    if (openConsult) {
      final open = ref.read(patientControllerProvider).consultations.firstWhere((c) => c.status == 'open');
      onNavigate?.call(2, consultationId: open.id);
      return;
    }
    if (triage != null) {
      _startConsultation(
        context,
        ref,
        onNavigate,
        reportId: ref.read(patientControllerProvider).lastReportId,
      );
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
            onPressed: () {
              Navigator.pop(ctx);
              _startConsultation(context, ref, onNavigate);
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }
}

class _HeroStatusLine extends StatelessWidget {
  final List<Consultation> activeConsults;
  final TriageResult? triage;
  const _HeroStatusLine({required this.activeConsults, required this.triage});

  @override
  Widget build(BuildContext context) {
    final hasUrgent = triage?.classification == 'urgent';
    final String text = hasUrgent
        ? '⚠️ Urgent — seek care now'
        : activeConsults.isEmpty
            ? 'No active consultations'
            : '${activeConsults.length} active consultation${activeConsults.length > 1 ? 's' : ''}';
    return Semantics(
      liveRegion: true,
      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.3)),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  const _HeroStatPill({required this.label, required this.sublabel, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.1)),
          Text(sublabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD6246F),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: const Color(0xFFD6246F).withValues(alpha: 0.06),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(actionLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_ios, size: 10),
            ]),
          ),
      ],
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

  String get _explanation {
    if (triage.recommendedAction.isNotEmpty) {
      return triage.recommendedAction;
    }
    // Fallback explanations if backend doesn't return recommended_action
    switch (triage.classification.toLowerCase()) {
      case 'urgent':
        return 'Visit a clinic or hospital immediately.';
      case 'routine':
        return 'Book a consultation with a provider within the next few days.';
      case 'self-care':
        return 'Monitor your symptoms at home. Consult a provider if symptoms worsen.';
      default:
        return 'Book a consultation with a provider within the next few days.';
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
              Text(_explanation, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, height: 1.4)),
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


class _ConsultTile extends StatelessWidget {
  final Consultation consultation;
  final void Function(int, {String? consultationId})? onNavigate;
  const _ConsultTile({required this.consultation, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final triageColor = c.triageClassification == 'urgent'
        ? const Color(0xFFE53935)
        : c.triageClassification == 'routine'
            ? const Color(0xFF1565C0)
            : const Color(0xFF2E7D32);
    final timeStr = timeAgo(c.lastMessageAt ?? c.createdAt);
    return Semantics(
      label: 'Consultation from $timeStr, status ${c.status}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onNavigate?.call(2, consultationId: c.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(width: 4, height: 52, decoration: BoxDecoration(color: triageColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: triageColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(c.triageClassification.toUpperCase(), style: TextStyle(color: triageColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.status == 'open' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.status == 'open' ? Colors.green[700] : Colors.grey[600])),
                        ),
                        const Spacer(),
                        Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        c.lastMessagePreview.isNotEmpty ? c.lastMessagePreview : 'Tap to open chat',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, height: 1.35, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (c.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(12)),
                    child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                else
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
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
      children: referrals.take(3).map((r) {
        final isNew = r.status == ReferralStatus.newReferral;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onNavigate?.call(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(width: 4, height: 44, decoration: BoxDecoration(color: isNew ? Colors.orange : Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.local_hospital_outlined, color: Color(0xFFD6246F), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.facilityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(DateFormat('dd MMM y').format(r.issuedDate), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isNew ? Colors.orange.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(isNew ? 'NEW' : 'VIEWED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNew ? Colors.orange.shade700 : Colors.grey[600])),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
        onAction: () async {
          final consultation = await ref.read(patientControllerProvider.notifier).startConsultation();
          if (!mounted) return;
          if (consultation != null) {
            setState(() => _activeChat = consultation.id);
          } else {
            final err = ref.read(patientControllerProvider).error;
            if (err != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
            }
          }
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: state.consultations.length,
      itemBuilder: (_, i) {
        final c = state.consultations[i];
        return _ConsultTile(
          consultation: c,
          onNavigate: (tab, {consultationId}) => setState(() => _activeChat = consultationId ?? c.id),
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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollMessages());
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ref.read(patientControllerProvider.notifier).loadMessages(widget.consultation.id);
      if (mounted) setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pollMessages() async {
    if (!mounted) return;
    try {
      final msgs = await ref.read(patientControllerProvider.notifier).loadMessages(widget.consultation.id);
      if (!mounted) return;
      if (msgs.length != _messages.length) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    final optimistic = ChatMessage(id: 'local-${DateTime.now().millisecondsSinceEpoch}', senderRole: 'patient', body: text, createdAt: DateTime.now());
    setState(() => _messages.add(optimistic));
    _scrollToBottom();
    try {
      await ref.read(patientControllerProvider.notifier).sendMessage(widget.consultation.id, text);
    } catch (_) {}
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
    final c = widget.consultation;
    final triageColor = c.triageClassification == 'urgent'
        ? const Color(0xFFE53935)
        : c.triageClassification == 'routine'
            ? const Color(0xFF1565C0)
            : const Color(0xFF2E7D32);
    return Column(
      children: [
        // ── Chat header ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: widget.onBack),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: triageColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.medical_services_outlined, color: triageColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Consult #${c.id.length >= 8 ? c.id.substring(0, 8).toUpperCase() : c.id.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: triageColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(c.triageClassification.toUpperCase(), style: TextStyle(color: triageColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: c.status == 'open' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(c.status.toUpperCase(), style: TextStyle(color: c.status == 'open' ? Colors.green[700] : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ]),
            ])),
          ]),
        ),
        // ── Messages ─────────────────────────────────────────
        if (_loading)
          const Expanded(child: LoadingView(message: 'Loading messages...'))
        else if (_messages.isEmpty)
          Expanded(child: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No messages yet', style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text('Send a message to start the conversation.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          )))
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m.senderRole == 'patient';
                final showDate = i == 0 || !_isSameDay(_messages[i - 1].createdAt, m.createdAt);
                return Column(
                  children: [
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                            child: Text(_formatChatDate(m.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[_ProviderAvatar(), const SizedBox(width: 8)],
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFFD6246F) : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 18),
                                      ),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                                    ),
                                    child: Text(m.body, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14.5, height: 1.4)),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(DateFormat('HH:mm').format(m.createdAt), style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        // ── Input bar ─────────────────────────────────────────
        if (c.status == 'open')
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.grey[200]!)),
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (_) => _send(),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Send message',
                child: InkWell(
                  onTap: _send, borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: const BoxDecoration(color: Color(0xFFD6246F), shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: Colors.grey[50],
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text('This consultation is closed', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ])),
          ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatChatDate(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Today';
    if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('EEEE, dd MMM').format(dt);
  }
}

class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar();
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
      child: const Icon(Icons.medical_services_outlined, size: 14, color: Color(0xFF1565C0)),
    );
  }
}

class PatientReferralsScreen extends ConsumerStatefulWidget {
  const PatientReferralsScreen({super.key});

  @override
  ConsumerState<PatientReferralsScreen> createState() => _PatientReferralsScreenState();
}

class _PatientReferralsScreenState extends ConsumerState<PatientReferralsScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    final filtered = _query.isEmpty
        ? state.referrals
        : state.referrals.where((r) {
            final q = _query.toLowerCase();
            return r.facilityName.toLowerCase().contains(q)
                || r.notes.toLowerCase().contains(q)
                || r.status.name.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'Search referrals',
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search for referrals...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
          ),
        ),
        Expanded(
          child: state.loading
              ? const LoadingView(message: 'Loading referrals...')
              : filtered.isEmpty
                  ? EmptyView(
                      message: _query.isNotEmpty
                          ? 'No referrals match "$_query".'
                          : 'No referrals yet.\nYour doctor will issue one after a consultation.',
                      icon: Icons.assignment_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final r = filtered[i];
                        final isNew = r.status == ReferralStatus.newReferral;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isNew ? Colors.orange.shade100 : Colors.grey[100]!),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (isNew) ref.read(patientControllerProvider.notifier).markReferralViewed(r.id);
                              _showReferralDetails(context, r);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // left accent bar
                                  Container(
                                    width: 4, height: 64,
                                    decoration: BoxDecoration(
                                      color: isNew ? Colors.orange : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD6246F).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.assignment_outlined, color: Color(0xFFD6246F), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                            child: Text(r.facilityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isNew ? Colors.orange.shade50 : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isNew ? 'NEW' : 'VIEWED',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNew ? Colors.orange.shade700 : Colors.grey[600]),
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 5),
                                        Row(children: [
                                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[400]),
                                          const SizedBox(width: 3),
                                          Expanded(child: Text(r.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                                        ]),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[400]),
                                          const SizedBox(width: 3),
                                          Text('Issued ${DateFormat('dd MMM y').format(r.issuedDate)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
    final isNew = r.status == ReferralStatus.newReferral;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.assignment_outlined, color: Color(0xFFD6246F), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.facilityName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: isNew ? Colors.orange.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isNew ? 'New Referral' : 'Viewed',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isNew ? Colors.orange.shade700 : Colors.grey[600]),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 20),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Address', value: r.address),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: r.phone),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date Issued', value: DateFormat('dd MMMM y').format(r.issuedDate)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse('tel:${r.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open dialer')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => BookAppointmentDialog(facilityId: r.id, facilityName: r.facilityName),
                    );
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Book Appointment'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[100]!),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showClinicDetails(context, f),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD6246F).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.local_hospital_outlined, color: Color(0xFFD6246F), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[400]),
                                          const SizedBox(width: 3),
                                          Expanded(child: Text(f.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                                        ]),
                                        const SizedBox(height: 6),
                                        if (f.phone.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.phone_outlined, size: 11, color: Colors.blue[700]),
                                              const SizedBox(width: 4),
                                              Text(f.phone, style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                            ]),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
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

  void _showClinicDetails(BuildContext context, Facility f) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.local_hospital_outlined, color: Color(0xFFD6246F), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Healthcare Facility', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 20),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Address', value: f.address),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: f.phone),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse('tel:${f.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open dialer')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => BookAppointmentDialog(facilityId: f.id, facilityName: f.name),
                    );
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Book Appointment'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        )),
      ],
    );
  }
}

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'P';
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
                colors: [Color(0xFFD6246F), Color(0xFF8C3B95)],
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
                      child: const Icon(Icons.edit, size: 14, color: Color(0xFFD6246F)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(user?.fullName ?? 'Patient', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user?.phoneNumber ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.fingerprint, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(user?.anonymousId ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ]),
              ),
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
                _ProfileGroup(
                  label: 'Account',
                  items: [
                    _ProfileTile(icon: Icons.person_outline, title: 'Full Name', value: user?.fullName ?? 'N/A', onTap: () => _showEditProfile(context, ref, user)),
                    _ProfileTile(icon: Icons.phone_outlined, title: 'Phone Number', value: user?.phoneNumber ?? 'N/A', onTap: () => _showChangePhone(context, ref)),
                    _ProfileTile(icon: Icons.security_outlined, title: 'Account Security', value: 'Change Password', onTap: () => _showChangePassword(context, ref)),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileGroup(
                  label: 'Preferences',
                  items: [
                    _ProfileTile(icon: Icons.language_outlined, title: 'Language', value: 'English', onTap: () {}),
                    _ProfileTile(icon: Icons.notifications_outlined, title: 'Notifications', value: 'Enabled', onTap: () {}),
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
        title: const Text('Edit Profile'),
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
                  SnackBar(content: Text(ok ? 'Profile updated successfully.' : ref.read(authControllerProvider).error ?? 'Update failed')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePhone(BuildContext context, WidgetRef ref) {
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.phone_outlined, color: Color(0xFFD6246F)),
          SizedBox(width: 10),
          Text('Update Phone Number'),
        ]),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'New Phone Number', prefixIcon: Icon(Icons.phone)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone number required';
              final c = v.replaceAll(' ', '');
              if (c.length < 8 || c.length > 15) return 'Enter a valid phone number';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await ref.read(authControllerProvider.notifier).updateProfile(phoneNumber: phoneCtrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Phone number updated successfully.' : ref.read(authControllerProvider).error ?? 'Update failed')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.lock_outline, color: Color(0xFFD6246F)),
            SizedBox(width: 10),
            Text('Change Password'),
          ]),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setDlg(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setDlg(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Min 8 characters required';
                    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Must contain a letter';
                    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await ref.read(authControllerProvider.notifier).updateProfile(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Password changed successfully.' : ref.read(authControllerProvider).error ?? 'Update failed')),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileGroup extends StatelessWidget {
  final String label;
  final List<Widget> items;
  const _ProfileGroup({required this.label, required this.items});

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
              return Column(
                children: [
                  item,
                  if (idx < items.length - 1) Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _ProfileTile({required this.icon, required this.title, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFFD6246F), size: 18),
      ),
      title: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 18, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}

class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  final void Function(int, {String? consultationId})? onNavigate;
  const PatientAppointmentsScreen({super.key, this.onNavigate});

  @override
  ConsumerState<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends ConsumerState<PatientAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientControllerProvider.notifier).loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    final upcoming = state.appointments.where((a) => a.isUpcoming).toList();
    final past = state.appointments.where((a) => !a.isUpcoming).toList();

    if (state.loading && state.appointments.isEmpty) {
      return const LoadingView(message: 'Loading appointments...');
    }

    if (state.appointments.isEmpty) {
      return EmptyView(
        message: 'No appointments yet.\nBook an appointment with a healthcare provider.',
        icon: Icons.calendar_today_outlined,
        actionLabel: 'Book Appointment',
        onAction: () => _showBookAppointmentDialog(context),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: () => _showBookAppointmentDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Book New'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD6246F),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(title: 'Upcoming (${upcoming.length})'),
            const SizedBox(height: 12),
            ...upcoming.map((a) => _AppointmentCard(
              appointment: a,
              onCancel: () => _confirmCancel(context, a),
              onNavigate: widget.onNavigate,
            )),
            const SizedBox(height: 32),
          ],
          if (past.isNotEmpty) ...[
            _SectionHeader(title: 'Past Appointments'),
            const SizedBox(height: 12),
            ...past.map((a) => _AppointmentCard(
              appointment: a,
              isPast: true,
              onNavigate: widget.onNavigate,
            )),
          ],
        ],
      ),
    );
  }

  void _showBookAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const BookAppointmentDialog(),
    );
  }

  void _confirmCancel(BuildContext context, Appointment appointment) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: Colors.orange),
          SizedBox(width: 10),
          Text('Cancel Appointment'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel your appointment with ${appointment.providerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Feeling better, rescheduling',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(patientControllerProvider.notifier).cancelAppointment(
                appointment.id,
                reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isPast;
  final VoidCallback? onCancel;
  final void Function(int, {String? consultationId})? onNavigate;

  const _AppointmentCard({
    required this.appointment,
    this.isPast = false,
    this.onCancel,
    this.onNavigate,
  });

  Color get _statusColor {
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPast ? Colors.grey[200]! : const Color(0xFFD6246F).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.statusLabel.toUpperCase(),
                    style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (!isPast && appointment.canCancel && onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.orange),
                    label: const Text('Cancel', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.medical_services_outlined, color: Color(0xFFD6246F), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (appointment.facilityName != null) ...[
                        const SizedBox(height: 2),
                        Text(appointment.facilityName!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEEE, MMM d, y').format(appointment.scheduledAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('h:mm a').format(appointment.scheduledAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                Text('• ${appointment.duration} min', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${appointment.notes}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class BookAppointmentDialog extends ConsumerStatefulWidget {
  final String? facilityId;
  final String? facilityName;
  const BookAppointmentDialog({super.key, this.facilityId, this.facilityName});

  @override
  ConsumerState<BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends ConsumerState<BookAppointmentDialog> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  AvailableProvider? _selectedProvider;
  String? _selectedTimeSlot;
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientControllerProvider.notifier).loadAvailableProviders(date: _selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientControllerProvider);
    final providers = state.availableProviders;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFD6246F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_today, color: Color(0xFFD6246F)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Book Appointment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.facilityName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6246F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD6246F).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital, color: Color(0xFFD6246F), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Booking at:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(widget.facilityName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final date = DateTime.now().add(Duration(days: i));
                final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                return ChoiceChip(
                  label: Text(DateFormat('E d').format(date)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedDate = date);
                    ref.read(patientControllerProvider.notifier).loadAvailableProviders(date: date);
                  },
                  selectedColor: const Color(0xFFD6246F).withValues(alpha: 0.2),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text('Select Provider', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (state.loading && providers.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (providers.isEmpty)
              Text('No providers available for this date.', style: TextStyle(color: Colors.grey[600]))
            else
              Wrap(
                spacing: 8,
                children: providers.map((p) {
                  final isSelected = _selectedProvider?.providerId == p.providerId;
                  return ChoiceChip(
                    label: Text(p.fullName),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedProvider = p),
                    selectedColor: const Color(0xFFD6246F).withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            const Text('Select Time', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTimeSlot == time;
                final isBooked = _selectedProvider?.bookedSlots.any(
                  (b) => DateFormat('HH:mm').format(b.scheduledAt) == time,
                ) ?? false;
                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: isBooked ? null : (_) => setState(() => _selectedTimeSlot = time),
                  selectedColor: const Color(0xFFD6246F).withValues(alpha: 0.2),
                  disabledColor: Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes for provider (optional)',
                hintText: 'e.g., Follow-up for previous consultation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _canBook ? _book : null,
                child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canBook => _selectedProvider != null && _selectedTimeSlot != null && !_loading;

  Future<void> _book() async {
    if (_selectedProvider == null || _selectedTimeSlot == null) return;

    setState(() => _loading = true);

    final parts = _selectedTimeSlot!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    final appointment = await ref.read(patientControllerProvider.notifier).bookAppointment(
      providerId: _selectedProvider!.providerId,
      facilityId: widget.facilityId,
      scheduledAt: scheduledAt,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
    );

    setState(() => _loading = false);

    if (appointment != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked with ${appointment.providerName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }
}
