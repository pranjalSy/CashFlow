import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../shared/widgets/tab_page.dart';

/// Placeholder until its task builds the real screen.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) => TabPage(title: context.l10n.contactsTitle, children: const []);
}
