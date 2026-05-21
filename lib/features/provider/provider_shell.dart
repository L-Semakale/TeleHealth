import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/auth_controller.dart';
import 'provider_controller.dart';

class ProviderShell extends ConsumerStatefulWidget {
  const ProviderShell({super.key});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
  int _index = 0;
  String? _activeChatId;

  static const _titles = ['Dashboard', 'Consultations', 'Messages', 'Referrals', 'Clinics', 'Profile'];

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
      case 0: return _ProviderDashboard(onOpenChat: _openChat);
      case 1: return _ProviderInboxScreen(onOpenChat: _openChat);
      case 2: return _ProviderMessagesScreen(activeChatId: _activeChatId, onBack: () => setState(() { _activeChatId = null; _index = 1; }));
      case 3: return const _ProviderReferralsScreen();
      case 4: return const _ProviderClinicsScreen();
      case 5: return const _ProviderProfileScreen();
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
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          if (!isDesktop) ...[const BrandLogo(size: 32), const SizedBox(width: 16)],
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(
                label: 'Notifications',
                child: IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => _showNotifications(context, ref)),
              ),
              if (totalUnread > 0)
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFD6246F), shape: BoxShape.circle),
                    child: Text('$totalUnread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: Colors.blue.withAlpha(25),
            child: Text(
              user?.fullName.isNotEmpty == true ? user!.fullName.substring(0, 1).toUpperCase() : 'D',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final consultations = ref.read(providerControllerProvider).consultations;
    final unread = consultations.where((c) => c.unreadCount > 0).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (unread.isEmpty)
              const Center(child: Text('No new notifications.', style: TextStyle(color: Colors.grey)))
            else
              ...unread.map((c) => ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD6246F)),
                title: Text('New message from ${c.patientAnonymousId}'),
                subtitle: Text(c.lastMessagePreview.isNotEmpty ? c.lastMessagePreview : 'Tap to view'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFD6246F), borderRadius: BorderRadius.circular(12)),
                  child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _ProviderSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  const _ProviderSidebar({required this.selectedIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 260,
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(24), child: BrandLogo(size: 40, lightMode: true)),
          const SizedBox(height: 20),
          _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', selected: selectedIndex == 0, onTap: () => onIndexChanged(0)),
          _SidebarItem(icon: Icons.medical_services_rounded, label: 'Consultations', selected: selectedIndex == 1, onTap: () => onIndexChanged(1)),
          _SidebarItem(icon: Icons.chat_rounded, label: 'Messages', selected: selectedIndex == 2, onTap: () => onIndexChanged(2)),
          _SidebarItem(icon: Icons.assignment_rounded, label: 'Referrals', selected: selectedIndex == 3, onTap: () => onIndexChanged(3)),
          _SidebarItem(icon: Icons.local_hospital_rounded, label: 'Clinics', selected: selectedIndex == 4, onTap: () => onIndexChanged(4)),
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
    final filtered = _filter == 'all' ? list : list.where((c) => c.triageClassification == _filter || (_filter == 'open' && c.status == 'open') || (_filter == 'closed' && c.status == 'closed')).toList();
    return filtered..sort((a, b) {
      final ua = _urgencyOrder[a.triageClassification] ?? 1;
      final ub = _urgencyOrder[b.triageClassification] ?? 1;
      if (ua != ub) return ua.compareTo(ub);
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerControllerProvider);
    if (state.loading && state.consultations.isEmpty) return const LoadingView(message: 'Loading consultations...');
    final sorted = _sorted(state.consultations);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                    selectedColor: const Color(0xFFD6246F).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFFD6246F),
                  ),
                ),
            ]),
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

  @override
  void dispose() {
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
    final facility = TextEditingController();
    final notes = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Issue Referral'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: facility, decoration: const InputDecoration(labelText: 'Facility Name')),
          const SizedBox(height: 12),
          TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes for Patient')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(providerControllerProvider.notifier).issueReferral(consultationId, facility.text, notes.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral issued successfully.')));
            },
            child: const Text('Issue Referral'),
          ),
        ],
      ),
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
  final void Function(String) onOpenChat;
  const _ProviderDashboard({required this.onOpenChat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerControllerProvider);
    final open = state.consultations.where((e) => e.status == 'open').length;
    final urgent = state.consultations.where((e) => e.triageClassification == 'urgent' && e.status == 'open').length;
    final total = state.consultations.length;
    final recent = (state.consultations.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              SizedBox(width: 180, child: _StatCard(title: 'Active Consults', value: '$open', icon: Icons.pending_actions, color: Colors.blue)),
              SizedBox(width: 180, child: _StatCard(title: 'Urgent Cases', value: '$urgent', icon: Icons.warning_amber_rounded, color: Colors.red)),
              SizedBox(width: 180, child: _StatCard(title: 'Completed', value: '${total - open}', icon: Icons.check_circle_outline, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Recent Consultations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...recent.map((c) => _ConsultationCard(consultation: c, onOpenChat: onOpenChat)),
        ],
      ),
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
