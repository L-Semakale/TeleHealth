import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_config.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/brand_styles.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _HeroSection(),
            const _FeaturesSection(),
            const _DownloadAppSection(),
            const _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : size.width * 0.1,
            vertical: isMobile ? 32 : 64,
          ),
          child: Column(
            children: [
              // ── Nav bar ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogo(size: 40),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => context.go('/register'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        child: const Text('Get Started'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 48 : 72),
              // ── Hero content ────────────────────────────────
              if (isMobile)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        'https://cdn.prod.website-files.com/611ed5a217b32b056e5477ec/6952597fbbd9ed78a40778e3_66e9af5ba9335580eb6202ae_644988ded773ee3739f6691a_Online%2520Medical%2520Checkup%2520(1)%2520(1).gif',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        gaplessPlayback: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildHeroContent(context, isMobile),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: _buildHeroContent(context, isMobile)),
                    const SizedBox(width: 60),
                    Expanded(flex: 4, child: _buildHeroVisual()),
                  ],
                ),
              SizedBox(height: isMobile ? 48 : 72),
              // ── Stats strip ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: isMobile
                    ? Column(
                        children: [
                          _StatItem(value: '50K+', label: 'Patients Served'),
                          const Divider(height: 24),
                          _StatItem(value: '1,200+', label: 'Providers'),
                          const Divider(height: 24),
                          _StatItem(value: '98%', label: 'Uptime'),
                          const Divider(height: 24),
                          _StatItem(value: '< 2 min', label: 'Avg Triage Time'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(value: '50K+', label: 'Patients Served'),
                          _VerticalDivider(),
                          _StatItem(value: '1,200+', label: 'Providers'),
                          _VerticalDivider(),
                          _StatItem(value: '98%', label: 'Uptime'),
                          _VerticalDivider(),
                          _StatItem(value: '< 2 min', label: 'Avg Triage Time'),
                        ],
                      ),
              ),
            ],
          ),
        );
  }

  Widget _buildHeroContent(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Healthcare\nat your\nfingertips.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 40 : 56,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F0A1E),
            height: 1.05,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'AI-powered triage, secure consultations, and clinic referrals — all in one platform built for the future of Africa.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 17, height: 1.65),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Get Started Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Image.network(
        'https://cdn.prod.website-files.com/611ed5a217b32b056e5477ec/6952597fbbd9ed78a40778e3_66e9af5ba9335580eb6202ae_644988ded773ee3739f6691a_Online%2520Medical%2520Checkup%2520(1)%2520(1).gif',
        height: 420,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : MediaQuery.of(context).size.width * 0.1,
        vertical: 80,
      ),
      color: const Color(0xFFF9F9FC),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF5B4AA0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('WHY CHOOSE US', style: TextStyle(color: Color(0xFF5B4AA0), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Built for Africa,\ndesigned for everyone.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0F0A1E), height: 1.15),
          ),
          const SizedBox(height: 14),
          const Text(
            'Addressing the unique healthcare challenges across the continent with modern, accessible technology.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 56),
          isMobile
              ? Column(
                  children: [
                    const _FeatureCard(icon: Icons.bolt_rounded, title: 'AI-Powered Triage', description: 'Smart urgency classification ensures critical cases get immediate attention in under 2 minutes.', color: Color(0xFFD6246F)),
                    const SizedBox(height: 20),
                    const _FeatureCard(icon: Icons.lock_rounded, title: 'Private & Secure', description: 'Anonymous patient IDs and encrypted consultations protect every interaction.', color: Color(0xFF1565C0)),
                    const SizedBox(height: 20),
                    const _FeatureCard(icon: Icons.wifi_off_rounded, title: 'Works Offline', description: 'Symptom queue syncs automatically when connectivity is restored — no data lost.', color: Color(0xFF2E7D32)),
                    const SizedBox(height: 20),
                    const _FeatureCard(icon: Icons.local_hospital_rounded, title: 'Clinic Network', description: 'Find and get referred to verified clinics near you with a single tap.', color: Color(0xFF8C3B95)),
                    const SizedBox(height: 20),
                    const _FeatureCard(icon: Icons.people_rounded, title: 'Provider Tools', description: 'Prioritised inbox, triage badges, and referral workflows built for busy providers.', color: Color(0xFFE65100)),
                    const SizedBox(height: 20),
                    const _FeatureCard(icon: Icons.analytics_rounded, title: 'System Analytics', description: 'Real-time triage dashboards and health metrics for administrators.', color: Color(0xFF00695C)),
                  ],
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.95,
                  children: const [
                    _FeatureCard(icon: Icons.bolt_rounded, title: 'AI-Powered Triage', description: 'Smart urgency classification ensures critical cases get immediate attention in under 2 minutes.', color: Color(0xFFD6246F)),
                    _FeatureCard(icon: Icons.lock_rounded, title: 'Private & Secure', description: 'Anonymous patient IDs and encrypted consultations protect every interaction.', color: Color(0xFF1565C0)),
                    _FeatureCard(icon: Icons.wifi_off_rounded, title: 'Works Offline', description: 'Symptom queue syncs automatically when connectivity is restored — no data lost.', color: Color(0xFF2E7D32)),
                    _FeatureCard(icon: Icons.local_hospital_rounded, title: 'Clinic Network', description: 'Find and get referred to verified clinics near you with a single tap.', color: Color(0xFF8C3B95)),
                    _FeatureCard(icon: Icons.people_rounded, title: 'Provider Tools', description: 'Prioritised inbox, triage badges, and referral workflows built for busy providers.', color: Color(0xFFE65100)),
                    _FeatureCard(icon: Icons.analytics_rounded, title: 'System Analytics', description: 'Real-time triage dashboards and health metrics for administrators.', color: Color(0xFF00695C)),
                  ],
                ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F0A1E))),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: Color(0xFF6B6B8A), height: 1.6, fontSize: 14)),
        ],
      ),
    );
  }
}

class _DownloadAppSection extends StatelessWidget {
  const _DownloadAppSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : MediaQuery.of(context).size.width * 0.1,
        vertical: 60,
      ),
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD6246F), Color(0xFF9C1B52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const Icon(Icons.health_and_safety_rounded, color: Colors.white54, size: 48),
              const SizedBox(height: 20),
              Text(
                'Ready to take control of your health?',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Join 50,000+ patients and 1,200+ providers on the platform built for Africa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/register'),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Register as Patient', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD6246F),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const NoiseOverlay(opacity: 0.07, borderRadius: BorderRadius.all(Radius.circular(40))),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StoreButton({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Download on', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F0A1E))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B8A), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2));
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: const Color(0xFF6B6B8A)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B8A), fontWeight: FontWeight.w500)),
    ]);
  }
}

class _MockTriageCard extends StatelessWidget {
  final String label;
  final Color color;
  final String text;
  const _MockTriageCard({required this.label, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: TextStyle(color: color == Colors.red ? Colors.red.shade100 : color == Colors.blue ? Colors.blue.shade100 : Colors.green.shade100, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : MediaQuery.of(context).size.width * 0.1,
        vertical: 80,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandLogo(size: 32),
              if (!isMobile)
                Row(
                  children: const [
                    _FooterLink('Home'),
                    SizedBox(width: 32),
                    _FooterLink('Features'),
                    SizedBox(width: 32),
                    _FooterLink('Contact'),
                    SizedBox(width: 32),
                    _FooterLink('Privacy'),
                  ],
                ),
            ],
          ),
          const Divider(height: 80),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('© 2026 Telemedicine Platform. All rights reserved.', style: TextStyle(color: Colors.black54)),
              if (isMobile) const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.facebook, color: Colors.black54),
                  SizedBox(width: 24),
                  Icon(Icons.camera_alt, color: Colors.black54),
                  SizedBox(width: 24),
                  Icon(Icons.alternate_email, color: Colors.black54),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }
}

class _CredentialsGrid extends StatelessWidget {
  const _CredentialsGrid();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isMobile ? 2.5 : 1.35,
      ),
      children: const [
        _CredentialCard(
          title: 'Patient',
          phone: '+266500001',
          password: '123456',
          note: 'Any phone not ending with 88/99 works as patient.',
        ),
        _CredentialCard(
          title: 'Provider',
          phone: '+266500088',
          password: '123456',
          note: 'Phone ending with 88 signs in provider dashboard.',
        ),
        _CredentialCard(
          title: 'Admin',
          phone: '+266500099',
          password: '123456',
          note: 'Phone ending with 99 signs in admin dashboard.',
        ),
      ],
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.title,
    required this.phone,
    required this.password,
    required this.note,
  });

  final String title;
  final String phone;
  final String password;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title Login', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SelectableText('Phone: $phone'),
            SelectableText('Password: $password'),
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
