abstract final class S {
  static const brand = 'HomeEase AI',
      tagline = 'A little clarity. A home of your own.',
      demo = 'LOCAL DEMO',
      offline = 'Fictional data · no bank connection';
  static const nav = [
    'Home',
    'My Loan',
    'EMI Protection',
    'Repay',
  ];
  static const shortNav = ['Home', 'My Loan', 'Protect', 'Repay'];
  static const loginTitle = 'Your home loan,\nmade simple.',
      loginBody =
          'Understand today. Plan for tomorrow. Take the next step with confidence.';
  static const mobile = 'Mobile number',
      country = 'Code',
      getOtp = 'Get OTP',
      verifyTitle = 'Verify your mobile number',
      otpLabel = 'Six-digit OTP',
      verify = 'Verify & continue',
      resend = 'Resend OTP',
      demoOtp = 'Demo only · use OTP 123456. No SMS is sent.',
      invalidMobile =
          'Enter a valid 10-digit Indian mobile number starting with 6–9.',
      invalidOtp = 'That code does not match. Use the demo OTP 123456.',
      resent = 'Demo code reset. Use 123456.',
      close = 'Close',
      logout = 'Sign out',
      reset = 'Reset demo',
      resetTitle = 'Reset your demo?',
      resetBody =
          'Your calculator inputs will return to their starting values.',
      cancel = 'Cancel',
      confirm = 'Reset',
      specialTitle = 'Your space is being prepared',
      specialBody =
          'This mobile number has a separate destination. Its journey is pending future requirements.',
      specialTag = 'Reserved route';
  static const welcome = 'Welcome home,',
      homeTitle = 'A clearer picture of your loan.',
      homeBody = 'One home. One plan. A little more peace of mind.',
      balance = 'Outstanding principal',
      rate = 'Current interest rate',
      emi = 'Monthly EMI',
      nextDue = 'Next payment',
      remaining = 'Remaining tenure',
      progress = 'Your home, more yours every month',
      principalRepaid = 'Principal repaid',
      totalPaid = 'Total paid so far',
      protectTitle = 'A rate rise doesn’t have to be a surprise.',
      protectBody =
          'Explore how a small extra payment today could soften tomorrow’s EMI.',
      explore = 'Explore EMI Protection',
      repayTitle = 'Find your path to loan freedom',
      repayBody = 'Compare extra payments with your household budget in mind.',
      missed = 'Missed an EMI?',
      missedBody = 'Understand possible charges and prepare a waiver request.',
      open = 'Take a look',
      paidOff = 'of original principal repaid';
  static const loanTitle = 'Every detail, in one place.',
      loanBody = 'A simple view of your home loan and where your EMI goes.',
      lender = 'Lender',
      nickname = 'Loan nickname',
      sanctioned = 'Sanctioned amount',
      disbursed = 'Disbursed amount',
      rateType = 'Rate type',
      floating = 'Floating',
      started = 'Loan start date',
      overview = 'Loan overview',
      breakdown = 'Your next EMI, explained',
      principal = 'Principal',
      interest = 'Interest',
      breakdownBody =
          'Interest is the cost of borrowing. The rest of your EMI reduces what you owe.',
      schedule = 'Monthly repayment schedule',
      scheduleBody =
          'Current-rate estimate · select a month to inspect its breakdown.',
      history = 'Payment history',
      rateHistory = 'Interest rate history',
      sample = 'Fictional sample records',
      paid = 'Paid',
      delayed = 'Paid late',
      month = 'Month',
      opening = 'Opening principal',
      closing = 'Closing principal',
      previous = 'Previous',
      next = 'Next',
      selectedMonth = 'Selected month';
  static const protectionTitle = 'Make room for tomorrow.', protectionBody = 'See how small principal payments could cushion a hypothetical rate rise.', inputs = 'Your starting point', principalInput = 'Outstanding principal (₹)', rateInput = 'Current annual rate (%)', monthsInput = 'Remaining tenure (months)', emiInput = 'Current EMI (₹)', futureRate = 'Hypothetical future rate (%)', resetDate = 'Interest-rate reset date', extra = 'Extra monthly principal (₹)', policy = 'Lender adjustment assumption', policyEmi = 'Keep tenure · adjust EMI', policyTenure = 'Keep EMI · adjust tenure', custom = 'Custom', calculate = 'Update comparison', stale = 'Inputs changed. Update the comparison to refresh these estimates.', invalid = 'Check your values. Amounts must be non-negative, tenure 1–360 months, and rates 0–30%.', resetInvalid = 'Choose a future reset month before the end of your remaining tenure.', scenarioBase = 'Keep your current plan', scenarioExtra = 'Pay a little extra', scenarioReserve = 'Build a cash reserve', futureEmi = 'EMI after rate reset', atReset = 'Principal at reset', totalInterest = 'Projected total interest', additional = 'Extra principal paid', savings = 'Interest savings', reserve = 'Cash held at reset', target = 'Choose your comfort limit', targetEmi = 'Target future EMI (₹)', targetButton = 'Find an extra contribution', targetBody = 'Estimate the monthly extra principal needed before reset to keep the modelled future EMI within your target.', targetImpossible = 'This target is not achievable within the modelled budget or the selected lender policy. Try a higher target or a later reset.', targetAlready = 'Your current plan already meets this target under these assumptions.', required = 'Approximate extra per month until reset', targetLimit = 'Search is capped at outstanding principal per month. This is a modelled amount, not an affordability recommendation.', noAmortization = 'This EMI does not cover interest, or repayment exceeds the 100-year modelling limit. Increase the EMI or change the policy.', assumptions = 'How this estimate works', assumptionsBody = 'Monthly reducing balance. Money is rounded to the nearest paise each month. Extras are applied after EMI. The reset occurs before the payment in the selected month; dates use monthly cycles, not daily accrual. Future rates are hypothetical. Your lender may apply different rounding and reset rules. No fees, taxes or reserve returns are assumed. A cash reserve does not reduce your loan principal. An unchanged EMI is never guaranteed.', education = 'A few things worth knowing', educationItems = [
    'Why can EMI increase?',
    'How do extra payments help?',
    'What changes at a rate reset?',
    'Why keep an emergency fund?',
  ], educationAnswers = [
    'A higher rate increases the interest charged on what you still owe. Your lender may raise EMI, extend tenure, or use a combination.',
    'Extra principal reduces the balance on which future interest is calculated. The effect depends on timing and lender rules.',
    'This tool lets you choose which stays steady: EMI or tenure. Ask your lender which options your contract permits.',
    'Prepaid principal may be hard to access again. Keep accessible cash for essentials and unexpected expenses.',
  ];
  static const repayHeading = 'A small step. A shorter journey.',
      repaySubtitle =
          'Explore both repayment strategies before choosing what fits.',
      monthlyExtra = 'Additional monthly principal (₹)',
      lump = 'One-time prepayment (₹)',
      lumpMonth = 'One-time payment month',
      increase = 'Voluntary monthly EMI increase (₹)',
      income = 'Monthly household income (₹)',
      expenses = 'Essential monthly expenses (₹)',
      emergency = 'Emergency cash reserve (₹)',
      strategyTenure = 'Keep EMI · finish earlier',
      strategyEmi = 'Keep tenure · lower EMI',
      debtFree = 'Estimated debt-free date',
      commitment = 'Initial monthly commitment',
      monthsSaved = 'Months saved',
      affordability = 'A plan that leaves breathing room',
      affordable =
          'This initial payment fits within the income and expenses you entered.',
      notAffordable =
          'This initial payment exceeds the headroom you entered. Try a smaller contribution.',
      reserveNote = 'Emergency reserve covers',
      reserveSuffix = 'months of entered essential expenses. Keep a reserve that suits your household; this tool does not set a universal minimum.',
      laterEmi = 'EMI after first extra payment',
      repaymentAssumptions = 'Monthly reducing balance, constant current rate, paise rounding. Extras follow the EMI; a lump sum posts in the selected month. Ongoing extras continue even if the scheduled EMI decreases. No fees or taxes included.';
  static const helpTitle = 'Repay',
      helpBody = 'Simple answers for real-life home-loan questions.',
      scoreTitle = 'Loan Freedom Score',
      scoreNote =
          'Internal guidance metric · not a credit score or official banking score.',
      scoreMethod =
          'Based only on the share of original principal repaid. It does not assess creditworthiness or predict repayment ability.',
      terms = [
        'What is principal?',
        'What is a floating rate?',
        'Should I prepay or keep cash?',
        'Can my lender change my EMI?',
      ],
      answers = [
        'The amount borrowed that you have not yet repaid. Interest is charged on the remaining balance.',
        'A rate that can change with a benchmark and your loan contract. Future changes are uncertain.',
        'Compare savings with household needs, upcoming costs and an accessible emergency fund.',
        'Your agreement governs rate resets and available EMI or tenure adjustments. Ask your lender for a revised schedule.',
      ];
  static const charges = 'Missed EMI charge analyzer',
      chargesBody =
          'Demo presets: Rs 500 payment-return fee, Rs 0 flat penalty and 18% tax on fees. Illustrative values; confirm actual charges with your lender. Totals update automatically.',
      overdue = 'Overdue amount (₹)',
      days = 'Days past due',
      product = 'Loan product',
      returnFee = 'Payment-return charge (₹)',
      penal = 'Flat penal charge (₹)',
      tax = 'Tax rate on entered fees (%)',
      overdueRate = 'Contractual overdue interest (% per year)',
      source = 'Source of entered terms',
      illustrative = 'Illustrative assumptions',
      contractual = 'Contract terms entered by you',
      unknown = 'Unknown · verify with lender',
      chargeBreakdown = 'Itemized charge estimate',
      feeTax = 'Tax on entered return / penal fees',
      overdueInterest = 'Simple overdue interest',
      chargesTotal = 'Subtotal of entered charges',
      amountToClear = 'Overdue principal/EMI + entered charges',
      chargeDisclaimer =
          'This estimate applies the preset tax rate to the payment-return and flat penal charges. Actual charges depend on your lender agreement and policy. Unknown items are excluded from the subtotal.',
      waiver = 'Draft a waiver request',
      reason = 'Why was the payment missed?',
      draft = 'Prepare draft',
      request = 'Your editable request',
      copy = 'Copy request',
      copied = 'Request copied. You can send it yourself.',
      reasonError = 'Add a short reason before preparing your draft.',
      waiverNote = 'Review before sharing. Nothing is submitted, and approval is not guaranteed.',
      waiverSubject = 'Request for consideration of EMI charge waiver';
  static String phone(String value) => 'Code for +91 $value';
  static String years(int months) => '${months ~/ 12} yr ${months % 12} mo';
  static String monthNumber(int value) => 'Month $value';
  static String monthsCount(int value) => '$value months';
  static String waiverText(String reason) =>
      'Dear Loan Servicing Team,\n\nI request your consideration of a waiver of eligible charges relating to my missed home-loan EMI.\n\nReason: $reason\n\nPlease confirm the outstanding amount, applicable contractual charges, and whether any waiver is available. I understand this request is subject to your review.\n\nThank you,\nDemo borrower';
}
