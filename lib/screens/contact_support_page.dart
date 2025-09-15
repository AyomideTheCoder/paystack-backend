import 'package:flutter/material.dart';

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  _ContactSupportPageState createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> supportItems = const [
    {'title': 'Contact Us', 'icon': Icons.contact_mail, 'route': '/contact_us'},
    {'title': 'Privacy Policy', 'icon': Icons.privacy_tip, 'route': '/privacy_policy'},
    {'title': 'Terms & Conditions', 'icon': Icons.description, 'route': '/terms_conditions'},
    {'title': 'Newsletter Subscription', 'icon': Icons.mail_outline, 'route': '/newsletter_subscription'},
    {'title': 'Settings Page', 'icon': Icons.settings, 'route': '/settings_page'},
  ];

  final List<Map<String, String>> faqs = const [
    {
      'question': 'How do I list an item for sale?',
      'answer': 'Go to the Marketplace tab, tap "Add Item," and fill in the details.',
    },
    {
      'question': 'How can I receive payments securely?',
      'answer': 'NaijaMarket uses secure payment gateways like Stripe for safe transactions.',
    },
    {
      'question': 'What if I have an issue with a seller?',
      'answer': 'Use the "Contact Us" option or start a live chat for support.',
    },
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF004d40),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Support",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF004d40),
                      const Color(0xFF00796b),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  // Fallback to a default route or home screen if no previous route
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
              },
              tooltip: 'Back',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting live chat...')),
                  );
                },
                tooltip: 'Live Chat',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search support topics...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF004d40)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Searching for: $value')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // FAQ Section
                    Text(
                      'Frequently Asked Questions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...faqs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final faq = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFAQItem(
                          context,
                          index: index,
                          question: faq['question']!,
                          answer: faq['answer']!,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Support Options
                    Text(
                      'Get Help',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: supportItems.length,
                      itemBuilder: (context, index) {
                        final item = supportItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(0.1 * index, 0.6 + 0.1 * index, curve: Curves.easeOut),
                              ),
                            ),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.2, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(0.1 * index, 0.6 + 0.1 * index, curve: Curves.easeOutCubic),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  _animationController.reverse().then((_) {
                                    _animationController.forward();
                                    Navigator.pushNamed(context, item['route']);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black,
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item['icon'],
                                        color: const Color(0xFF004d40),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item['title'],
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, {required int index, required String question, required String answer}) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.1 * index, 0.6 + 0.1 * index, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.1 * index, 0.6 + 0.1 * index, curve: Curves.easeOutCubic),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: theme.colorScheme.surface,
          collapsedBackgroundColor: theme.colorScheme.surface,
          childrenPadding: const EdgeInsets.all(10),
          leading: const Icon(
            Icons.help_outline,
            color: Color(0xFF004d40),
            size: 16,
          ),
          title: Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          children: [
            Text(
              answer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}