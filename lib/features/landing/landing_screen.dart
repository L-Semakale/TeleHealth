import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_config.dart';
import '../../core/widgets/brand_logo.dart';

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
            if (AppConfig.useMockApi) ...[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick test accounts',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    const _CredentialsGrid(),
                  ],
                ),
              ),
            ],
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
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F1FC), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : size.width * 0.1,
        vertical: isMobile ? 40 : 80,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandLogo(size: 40),
              Row(
                children: [
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Sign In')),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: () => context.go('/register'), child: const Text('Get Started')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 60),
          if (isMobile)
            Column(
              children: [
                _buildHeroContent(context, isMobile, textTheme),
                const SizedBox(height: 60),
                _buildHeroImage(context, isMobile),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildHeroContent(context, isMobile, textTheme),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: _buildHeroImage(context, isMobile),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, bool isMobile, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD6246F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'AFRICAN HEALTHCARE INNOVATION',
            style: TextStyle(
              color: Color(0xFFD6246F),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Healthcare at your fingertips.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: (isMobile ? textTheme.headlineMedium : textTheme.displayMedium)?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Track symptoms, connect with providers, and manage healthcare teams from one responsive platform built for the future of Africa.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: textTheme.bodyLarge?.copyWith(color: Colors.black54, fontSize: 18),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.rocket_launch),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text('Register as Patient'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_circle_outline),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text('Watch Demo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context, bool isMobile) {
    return Container(
      child: Image.network(
        'https://cdn.prod.website-files.com/611ed5a217b32b056e5477ec/6952597fbbd9ed78a40778e3_66e9af5ba9335580eb6202ae_644988ded773ee3739f6691a_Online%2520Medical%2520Checkup%2520(1)%2520(1).gif',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: isMobile ? 300 : 400,
          color: Colors.transparent,
          child: const Icon(Icons.image, size: 100, color: Colors.grey),
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : MediaQuery.of(context).size.width * 0.1,
        vertical: 100,
      ),
      color: const Color(0xFFFBFBFB),
      child: Column(
        children: [
          Text(
            'Why Choose Our Platform',
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Designed specifically for the unique healthcare challenges and opportunities across the African continent.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 60),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 3,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: isMobile ? 1.5 : 1.0,
            children: const [
              _FeatureCard(
                icon: Icons.bolt,
                title: 'Fast Triage',
                description: 'AI-driven urgency classification to ensure critical cases get immediate attention.',
              ),
              _FeatureCard(
                icon: Icons.security,
                title: 'Secure Consultations',
                description: 'End-to-end encrypted video and chat sessions between patients and specialists.',
              ),
              _FeatureCard(
                icon: Icons.language,
                title: 'Local Innovation',
                description: 'Optimized for low-bandwidth connections and integrated with local payment systems.',
              ),
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

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD6246F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFD6246F)),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: Colors.black54, height: 1.5)),
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
      child: Column(
        children: [
          Text(
            'Ready to take control of your health?',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Download our mobile app to access healthcare anytime, anywhere.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _StoreButton(icon: Icons.apple, text: 'App Store'),
              _StoreButton(icon: Icons.android, text: 'Google Play'),
            ],
          ),
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
