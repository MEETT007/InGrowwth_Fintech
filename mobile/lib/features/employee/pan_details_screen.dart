import 'pan_details_controller.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_backdrop.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/app_widgets.dart';
import '../../services/pan_lookup_service.dart';
import '../auth/controllers/auth_controller.dart';

class PanDetailsScreen extends StatefulWidget {
  const PanDetailsScreen({super.key, required this.auth});
  final AuthController auth;
  @override
  State<PanDetailsScreen> createState() => _PanDetailsScreenState();
}

class _PanDetailsScreenState extends State<PanDetailsScreen> {
  final pan = TextEditingController();
  late final PanDetailsController controller;
  bool get loading => controller.loading;
  String? get error => controller.error;
  CustomerDetails? get customer => controller.customer;
  @override
  void initState() {
    super.initState();
    controller = PanDetailsController(widget.auth.employeeApi)
      ..addListener(update);
  }

  void update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(update);
    controller.dispose();
    pan.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    pan.text = PanLookupService.normalize(pan.text);
    await controller.fetch(pan.text);
  }

  String displayValue(String key, String value) {
    if (key == 'panNumber' || key == 'mobileNumber') {
      return '******${value.substring(value.length > 4 ? value.length - 4 : 0)}';
    }
    if ([
      'monthlyIncome',
      'annualIncome',
      'monthlyObligations',
      'outstandingLiabilities',
      'sanctionedAmount',
      'disbursedAmount',
      'outstandingPrincipal',
      'monthlyEmi',
    ].contains(key)) {
      final amount = num.tryParse(value);
      if (amount != null) return currency((amount * 100).round());
    }
    if ([
      'creditUtilization',
      'paymentHistoryPercentage',
      'interestRate',
    ].contains(key)) {
      return '$value%';
    }
    if (key == 'remainingTenureMonths') return '$value months';
    if (key == 'experienceYears') return '$value years';
    return value;
  }

  Widget card(String title, Map<String, String> fields) {
    final entries = fields.entries
        .where((e) => customer!.value(e.key) != null)
        .toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: entries.map((e) {
                var value = customer!.value(e.key)!;
                value = displayValue(e.key, value);
                return SizedBox(
                  width: constraints.maxWidth >= 550
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.value,
                        style: AppTextStyles.responsive(
                          context,
                          AppTextStyles.caption,
                        ),
                      ),
                      Text(
                        value,
                        style: AppTextStyles.responsive(
                          context,
                          AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppBackdrop(
    child: Scaffold(
      backgroundColor: AppColors.transparent,
      appBar: AppBar(
        title: const Text('HomeEase AI'),
        actions: [
          IconButton(
            onPressed: widget.auth.logout,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          title: 'Customer PAN Details',
          subtitle: 'Retrieve customer information using their PAN number.',
          children: [
            const InfoNote(
              'Synthetic demo records only. This is not government PAN verification.',
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_search_outlined,
                    color: AppColors.deepBlue,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Find a customer'),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the customer’s PAN to view their demo profile.',
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    style: AppTextStyles.responsive(
                      context,
                      AppTextStyles.body,
                    ),
                    controller: pan,
                    enabled: !loading,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => controller.clear(),
                    onSubmitted: (_) => fetch(),
                    decoration: const InputDecoration(
                      labelText: 'PAN number',
                      hintText: 'QWERT1234L',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      side: const BorderSide(color: AppColors.black),
                    ),
                    onPressed: loading ? null : fetch,
                    child: const Text('Fetch PAN Details'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.deepBlue,
                      side: const BorderSide(color: AppColors.black),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: loading
                        ? null
                        : () {
                            pan.clear();
                            controller.clear();
                          },
                    child: const Text('New Search / Clear'),
                  ),
                ],
              ),
            ),
            if (loading)
              const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Fetching customer information',
                ),
              ),
            if (error != null)
              AppCard(
                child: Text(
                  error!,
                  semanticsLabel: error,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (!loading && error == null && customer == null)
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: AppColors.deepBlue,
                      size: 32,
                    ),
                    SizedBox(height: 16),
                    SectionTitle('Customer information'),
                    Text(
                      'Search for a customer using PAN. Their details will appear here.',
                    ),
                  ],
                ),
              ),
            if (customer != null) ...[
              card('Basic Information', {
                'customerId': 'Customer ID',
                'firstName': 'First name',
                'middleName': 'Middle name',
                'lastName': 'Last name',
                'fullName': 'Full name',
                'dateOfBirth': 'Date of birth',
                'gender': 'Gender',
                'maritalStatus': 'Marital status',
                'nationality': 'Nationality',
              }),
              card('PAN and KYC Information', {
                'panNumber': 'PAN',
                'recordStatus': 'PAN record status',
                'kycStatus': 'KYC status',
                'verificationDate': 'Demo verification date',
                'recordSource': 'Record source',
                'customerType': 'Customer type',
              }),
              card('Address and Contact Information', {
                'mobileNumber': 'Mobile',
                'email': 'Email',
                'addressLine': 'Address',
                'city': 'City',
                'state': 'State',
                'pincode': 'PIN code',
                'country': 'Country',
              }),
              card('Employment and Financial Information', {
                'occupation': 'Occupation',
                'employmentType': 'Employment type',
                'employerName': 'Employer',
                'monthlyIncome': 'Monthly income',
                'annualIncome': 'Annual income',
                'experienceYears': 'Experience',
                'monthlyObligations': 'Other monthly obligations',
              }),
              AppCard(
                highlight: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Simulated Credit Score'),
                    Text(
                      customer!.value('simulatedCreditScore') ?? 'Unavailable',
                      style: AppTextStyles.responsive(
                        context,
                        AppTextStyles.amount,
                      ),
                    ),
                    Text(customer!.value('creditRating') ?? ''),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value:
                          (((num.tryParse(
                                            customer!.value(
                                                  'simulatedCreditScore',
                                                ) ??
                                                '',
                                          ) ??
                                          300) -
                                      300) /
                                  600)
                              .clamp(0, 1)
                              .toDouble(),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 12),
                    const InfoNote(
                      'Demo Credit Profile • Synthetic Financial Data. Not a credit bureau score.',
                    ),
                  ],
                ),
              ),
              card('Credit Profile and Financial Assessment', {
                'profileStatus': 'Profile status',
                'activeLoans': 'Active loans',
                'closedLoans': 'Closed loans',
                'outstandingLiabilities': 'Outstanding liabilities',
                'paymentHistoryPercentage': 'Payment history',
                'creditUtilization': 'Credit utilization',
                'recentEnquiries': 'Recent credit enquiries',
              }),
              if (customer!.homeLoans.isEmpty)
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle('Home Loan Information'),
                      Text(
                        'No demo home-loan record available for this customer.',
                      ),
                    ],
                  ),
                )
              else
                ...customer!.homeLoans.map(
                  (loan) => AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Home Loan Information'),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) => Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children:
                                {
                                      'lenderName': 'Lender',
                                      'sanctionedAmount': 'Sanctioned amount',
                                      'disbursedAmount': 'Disbursed amount',
                                      'outstandingPrincipal':
                                          'Outstanding principal',
                                      'interestRate': 'Interest rate',
                                      'monthlyEmi': 'Monthly EMI',
                                      'remainingTenureMonths':
                                          'Remaining tenure',
                                      'nextDueDate': 'Next due date',
                                      'loanStatus': 'Loan status',
                                    }.entries
                                    .where((e) => loan[e.key] != null)
                                    .map(
                                      (e) => SizedBox(
                                        width: constraints.maxWidth >= 550
                                            ? (constraints.maxWidth - 16) / 2
                                            : constraints.maxWidth,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.value,
                                              style: AppTextStyles.caption,
                                            ),
                                            Text(
                                              displayValue(
                                                e.key,
                                                loan[e.key].toString(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
