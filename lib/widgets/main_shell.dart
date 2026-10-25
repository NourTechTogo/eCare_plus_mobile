import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'raised_navigation_bar.dart';
import '../views/measurement/follow_up_page.dart';
import '../views/dashbord/home_page.dart';
import '../views/dashbord/appointments_page.dart';
import '../views/dashbord/articles_page.dart';
import '../views/dashbord/settings_page.dart';
import 'incoming_call_banner.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.scaffoldBackground,
    body: Column(
      children: [
        const IncomingCallBanner(),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: const [
              HomePage(),
              AppointmentsPage(showBack: false),
              ArticlesPage(),
              SettingsPage(),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: RaisedNavigationBar(
      selectedIndex: _selected,
      onAddMeasurement: () {
        FocusManager.instance.primaryFocus?.unfocus();
        showMeasurementSheet(context);
      },
      onDestinationSelected: (index) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _selected = index);
      },
    ),
  );
}
