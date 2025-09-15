import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'profile_page.dart';
import 'terms_conditions_page.dart';
import 'privacy_policy_page.dart';
import 'newsletter_subscription_page.dart';
import 'contact_us_page.dart';
import 'about_us_page.dart';
import 'update_notice_page.dart';

class HamburgerSidebar extends StatefulWidget {
  const HamburgerSidebar({super.key});

  @override
  _HamburgerSidebarState createState() => _HamburgerSidebarState();
}

class _HamburgerSidebarState extends State<HamburgerSidebar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(
            children: [
              SizedBox(height: 20), // Added reasonable space before the page cards
              GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  MenuCard(icon: Icons.contact_mail, label: 'Contact Us', page: ContactUsPage()),
                  MenuCard(icon: Icons.privacy_tip, label: 'Privacy Policy', page: PrivacyPolicyPage()),
                  MenuCard(icon: Icons.description, label: 'Terms & Condition', page: TermsConditionsPage()),
                  MenuCard(icon: Icons.newspaper, label: 'Newsletter & Subscription', page: NewsletterSubscriptionPage()),
                  MenuCard(icon: Icons.info, label: 'About Us', page: AboutUsPage()),
                  MenuCard(icon: Icons.notifications, label: 'Update Notice', page: UpdateNoticePage()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? page;

  const MenuCard({super.key, required this.icon, required this.label, this.page});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: page != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page!),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10214B),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white))),
          ],
        ),
      ),
    );
  }
}