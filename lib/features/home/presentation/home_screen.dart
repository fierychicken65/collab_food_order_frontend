import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../products/presentation/products_screen.dart';
import '../../group_order/presentation/dialogs/create_group_dialog.dart';
import '../../group_order/presentation/dialogs/join_group_dialog.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNormalOrder;
  final VoidCallback? onStartGroup;
  final VoidCallback? onJoinGroup;

  const HomeScreen({
    super.key,
    this.onNormalOrder,
    this.onStartGroup,
    this.onJoinGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Header (without redundant profile icon)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collab Food',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Collaborative Real-Time Food Ordering',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hero Banner with Clean Warm Accent
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFFD84315),
                            const Color(0xFFBF360C),
                          ]
                        : [
                            const Color(0xFFFF5722),
                            const Color(0xFFFF7043),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE SYNCED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Hungry together?\nOrder in seconds.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order solo or team up in a live shared cart session with friends.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section Heading
              Text(
                'Choose Order Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),

              // Featured Action Card: Start Group Order
              _HeroActionCard(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFFFF6F00),
                iconBg: isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF3E0),
                title: 'Start Group Order',
                subtitle: 'Host a session, get a unique 6-digit Join Code, and order with friends.',
                badge: 'HOST',
                badgeBg: isDark ? const Color(0xFF4E2600) : const Color(0xFFFFE0B2),
                badgeFg: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                buttonText: 'Create Session',
                onTap: onStartGroup ??
                    () {
                      showDialog(
                        context: context,
                        builder: (_) => const CreateGroupDialog(),
                      );
                    },
              ),
              const SizedBox(height: 14),

              // Option Row: Solo Order & Join Session
              Row(
                children: [
                  // Solo Order Card
                  Expanded(
                    child: _CompactOptionCard(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF1976D2),
                      iconBg: isDark ? const Color(0xFF0D47A1).withValues(alpha: 0.3) : const Color(0xFFE3F2FD),
                      title: 'Solo Order',
                      subtitle: 'Personal order',
                      onTap: onNormalOrder ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProductsScreen()),
                            );
                          },
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Join Group Card
                  Expanded(
                    child: _CompactOptionCard(
                      icon: Icons.login_rounded,
                      iconColor: const Color(0xFF388E3C),
                      iconBg: isDark ? const Color(0xFF1B5E20).withValues(alpha: 0.3) : const Color(0xFFE8F5E9),
                      title: 'Join Session',
                      subtitle: 'Enter 6-digit code',
                      onTap: onJoinGroup ??
                          () {
                            showDialog(
                              context: context,
                              builder: (_) => const JoinGroupDialog(),
                            );
                          },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final String buttonText;
  final VoidCallback onTap;

  const _HeroActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: badgeFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CompactOptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
