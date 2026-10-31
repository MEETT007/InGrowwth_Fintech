import '../features/employee/pan_details_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_backdrop.dart';
import 'package:flutter/material.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_dimensions.dart';

import '../data/repositories/loan_repository.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/my_loan/screens/my_loan_screen.dart';
import '../features/emi_protection/screens/protection_screen.dart';
import '../features/repayment/screens/repayment_screen.dart';
import '../features/help_insights/screens/help_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key, required this.auth});
  final AuthController auth;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (_, _) {
      if (auth.user == null) return LoginScreen(auth: auth);
      if (auth.user!.isSpecial) {
        return PanDetailsScreen(auth: auth);
      }
      return BorrowerShell(key: ValueKey(auth.user!.mobile), auth: auth);
    },
  );
}

class BorrowerShell extends StatefulWidget {
  const BorrowerShell({super.key, required this.auth});
  final AuthController auth;
  @override
  State<BorrowerShell> createState() => _BorrowerShellState();
}

class _BorrowerShellState extends State<BorrowerShell> {
  int selected = 0, generation = 0;
  static const icons = [
    Icons.home_outlined,
    Icons.account_balance_outlined,
    Icons.shield_sharp,
    Icons.trending_down,
    Icons.lightbulb_outline,
  ];
  @override
  Widget build(BuildContext context) {
    final loan = LoanRepository().loan,
        wide = MediaQuery.sizeOf(context).width >= AppDimensions.railBreakpoint;
    return AppBackdrop(
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          title: const Text(S.brand),
          actions: [
            if (wide)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Text(S.demo),
                ),
              ),
            IconButton(
              tooltip: S.logout,
              onPressed: widget.auth.logout,
              icon: const Icon(Icons.logout),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                NavigationRail(
                  extended: MediaQuery.sizeOf(context).width > 1200,
                  selectedIndex: selected,
                  onDestinationSelected: (v) => setState(() => selected = v),
                  labelType: MediaQuery.sizeOf(context).width > 1200
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: List.generate(
                    5,
                    (i) => NavigationRailDestination(
                      icon: Icon(icons[i]),
                      label: Text(S.nav[i]),
                    ),
                  ),
                ),
              Expanded(
                child: AppBackdrop(
                  child: IndexedStack(
                    key: ValueKey(generation),
                    index: selected,
                    children:
                        [
                              HomeScreen(
                                loan: loan,
                                name: widget.auth.user!.name,
                                onNavigate: (v) => setState(() => selected = v),
                              ),
                              MyLoanScreen(loan: loan),
                              ProtectionScreen(loan: loan),
                              RepaymentScreen(loan: loan),
                              HelpScreen(loan: loan),
                            ]
                            .asMap()
                            .entries
                            .map(
                              (entry) => PageEntrance(
                                revision: entry.key == selected
                                    ? selected + generation * 5
                                    : -1,
                                child: entry.value,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (v) => setState(() => selected = v),
                destinations: List.generate(
                  5,
                  (i) => NavigationDestination(
                    icon: Icon(icons[i]),
                    label: S.shortNav[i],
                  ),
                ),
              ),
      ),
    );
  }
}

