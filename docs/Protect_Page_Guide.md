# Protect Page User Guide

HomeEase AI | Guide to the current app | 2 November 2026

This guide explains every input, result and action on the Protect page. Use it to understand the client demonstration and explain how the calculations relate to one another. The page compares possible future loan repayments; it does not change a bank loan or collect payments.

## What the page helps you understand

Protect answers this question: If my interest rate changes later, what difference would paying extra principal now make, compared with saving that money separately?

You enter your current loan details, choose a possible future rate and when it starts, and select whether the model should adjust the EMI or the repayment duration. The page compares three scenarios and can also calculate the extra monthly principal needed for a target future EMI.

## Your starting point

| Field | Meaning | Example |
|---|---|---|
| Outstanding principal | Principal still unpaid at the start of this calculation, excluding future interest | Rs 30,00,000 |
| Current annual rate | Annual interest rate used before the reset month | 7% |
| Remaining tenure | Number of monthly payments remaining from the starting point | 240 months or 20 years |
| Current EMI | Regular monthly payment used initially | Rs 23,258.97 |
| Hypothetical future rate | Annual rate to test from the reset month onward | 10% |
| Interest rate reset date | Selected month when the model begins using the future rate | 5 November 2027 |
| Lender adjustment assumption | Whether EMI or the planned finish date stays steady | Keep tenure and adjust EMI |
| Extra monthly principal | Extra money allocated each month before reset | Rs 2,000 |

The current app initially fills loan details from a fictional loan record. These are demonstration values, not information fetched from a bank. The initial EMI is calculated from that record. If you edit principal, rate or tenure, review the EMI input too; the form does not automatically replace it whenever another field changes.

The 8%, 9% and 10% rate buttons are shortcuts. The amount buttons and slider are shortcuts for choosing extra monthly principal. They change assumptions, not bank instructions.

## Meaning of the hypothetical future rate

Entering 10% means: assume that the annual loan rate becomes 10% in the selected reset month. It is not a prediction, an additional 10% charge, or a confirmed lender rate. With 7% as the current rate, the model uses 7% before reset and 10% from reset onward.

The selected future rate then remains in effect for the rest of the modeled schedule. The page does not simulate a series of later rate changes.

## How the reset date connects the inputs

The reset month divides the repayment schedule into two periods. Before reset, the current rate applies and extra contributions can accumulate. From reset, the future rate applies and the chosen adjustment policy determines the repayment behavior.

| Connected input or result | Effect of the date |
|---|---|
| Current rate | Determines how long the current rate applies |
| Future rate | Determines when the future rate starts |
| Current EMI | Affects how much principal is repaid before reset |
| Remaining tenure | Elapsed payments are deducted from the original remaining term |
| Extra principal | Determines how many extra payments occur before reset |
| Cash reserve | Determines how many monthly savings contributions accumulate |
| Adjustment policy | Determines how repayment responds when the rate changes |

In the current demonstration, the first modeled EMI is 5 November 2026. A reset on 5 November 2027 occurs after 12 payments, at the start of payment month 13. Therefore 240 minus 12 equals 228 months remaining at reset when the original finish date is preserved.

The date calculation uses monthly cycles, not daily interest. Selecting a different day within the same month does not change the reset month. The date must be after the first modeled payment month and within the entered remaining term.

## What the extra Rs 2,000 does

The extra amount is allocated every month before reset. It stops at reset in this model.

For 12 payments before reset, Rs 2,000 multiplied by 12 gives Rs 24,000. In the extra-payment scenario this goes toward principal after each regular EMI. In the reserve scenario it is kept separately as cash. The baseline scenario uses neither extra payments nor reserve contributions.

An extra payment cannot exceed the principal left after that month's EMI. If a loan is cleared early, actual extra principal paid can be less than the planned contribution multiplied by the number of months.

## The two dropdown options

### Keep tenure and adjust EMI

This option aims to preserve the original loan finish date. The EMI changes to repay the remaining balance within the remaining months.

At reset, a higher rate normally requires a larger EMI. Paying extra principal beforehand reduces the balance used to calculate that EMI.

In the current implementation, the regular EMI is also recalculated after each extra principal payment before reset. Therefore the extra-payment scenario does not keep the original EMI unchanged throughout the pre-reset period. This matters when explaining the results: Rs 2,000 is extra principal each month, but the regular EMI component may gradually reduce.

Seeing 228 months at reset is consistent with preserving a 240-month term that started 12 payments earlier. It does not mean the selected policy unexpectedly shortened the loan by 12 months.

### Keep EMI and adjust tenure

This option keeps the regular EMI amount steady and allows the repayment duration to change. If interest rises, repayment can take longer. Extra principal paid before reset can reduce the duration compared with making no extra payments.

The remaining-tenure result can therefore differ from 228 months. If the EMI cannot cover monthly interest, or repayment exceeds the calculation limit, the page reports an error instead of a valid schedule.

The dropdown is a modeling assumption. It does not establish which repayment options a lender actually permits.

## Update comparison

After changing inputs, press Update comparison to calculate all three scenarios. Until you do, earlier results may still describe the previous inputs; the page marks them as needing a refresh.

The calculation does not submit anything to a bank, schedule payments or move money.

## Understanding the three comparison cards

### Keep your current plan

This is the baseline. You make regular modeled EMI payments with no extra principal. The hypothetical rate still starts at reset, and the selected adjustment policy still applies. The card does not mean that today's interest rate will remain unchanged.

### Pay a little extra

You pay the selected extra principal each month before reset. This lowers the balance on which later interest is calculated. The card compares that schedule with the baseline to show the effect on EMI, repayment duration and total interest.

### Build a cash reserve

You save the selected monthly amount separately instead of paying it into the loan. With Rs 2,000 saved for 12 months, the reserve is Rs 24,000.

The loan follows the baseline schedule because the savings have not reduced principal. That is why its EMI, principal, tenure and loan interest match the baseline. Its purpose is to show the alternative of retaining accessible money for emergencies or future payments.

The model assumes no interest earned on savings and does not automatically spend the reserve on EMIs. It does not create a real savings account.

## Meaning of each result

| Result | What it shows |
|---|---|
| EMI after rate reset | Modeled regular EMI for the first payment at the future rate |
| Principal at reset | Balance immediately before the payment in the reset month |
| Remaining tenure at rate reset | Number of payments left from the reset month, including that month's payment |
| Projected total interest | Interest across the entire modeled remaining schedule, including the period before reset |
| Extra principal paid | Total extra principal actually applied in the extra-payment scenario |
| Cash held at reset | Planned separate savings accumulated before reset |
| Interest savings | Baseline projected interest minus the selected scenario's projected interest |

Projected total interest is not the loan balance or the amount due immediately. Interest savings are measured over the modeled schedule, not just the first year.

## Worked example from the client screen

Assumptions: Rs 30,00,000 principal, 7% current rate, 240 months remaining, Rs 23,258.97 starting EMI, 10% future rate, reset after 12 payments, Rs 2,000 extra monthly principal, and keep tenure with EMI adjustment.

| Result | Current plan | Pay extra | Cash reserve |
|---|---:|---:|---:|
| EMI after reset | Rs 28,737 | Rs 28,504 | Rs 28,737 |
| Principal at reset | Rs 29,28,631 | Rs 29,04,898 | Rs 29,28,631 |
| Months remaining at reset | 228 | 228 | 228 |
| Projected total interest | Rs 38,31,246 | Rs 38,01,118 | Rs 38,31,246 |
| Extra principal paid or cash held | Rs 0 | Rs 24,000 paid | Rs 24,000 held |
| Loan interest savings | Rs 0 | Rs 30,128 | Rs 0 |

These are the rounded figures displayed in the supplied screenshot, not a new independently recalculated quotation. Changing any input can change them.

The extra-payment card reduces future EMI by about Rs 233 compared with the baseline. The reserve card keeps Rs 24,000 accessible but does not reduce the loan EMI or interest.

## Choose your comfort limit

This section works backward from a future EMI target. Enter the EMI you want after reset and press Find an extra contribution. The app searches for the monthly extra principal needed before reset to make the modeled future EMI no greater than that target.

| Earlier calculator | Comfort limit calculator |
|---|---|
| You choose extra principal, such as Rs 2,000 | You choose a future EMI, such as Rs 25,000 |
| It calculates the future EMI | It calculates the extra principal needed |

The target initially matches the starting EMI. It can be edited. For example, the supplied screen showed approximately Rs 32,097.76 extra per month for a Rs 25,000 target under its selected assumptions.

Read the result as: Approximately Rs 32,097.76 extra per month until reset date 5 November 2027. This is a monthly contribution before reset, alongside the modeled regular EMI. It is not one payment, not the EMI itself, and not an amount to add on top of the earlier Rs 2,000 contribution. It is an alternative extra-payment scenario.

The target search does not automatically replace the Extra monthly principal field. To inspect the target result in the comparison cards, enter the calculated contribution in that field and press Update comparison. Use the displayed amount as approximate because the search and display use currency rounding.

This feature is most useful with keep tenure and adjust EMI. Under keep EMI and adjust tenure, a valid schedule already holds the EMI steady, so searching for a target EMI adds limited value.

A result of current plan already meets the target means no extra contribution is needed under the selected assumptions. An unachievable message means the model could not meet the target within its search bounds or selected policy. It does not assess income or affordability. The search is capped at the outstanding principal as a monthly contribution.

## How the calculation works

The model uses monthly reducing-balance interest. Each month it calculates interest on the opening balance, applies the EMI, then applies extra principal where applicable. Amounts are rounded to the nearest paise during calculation. Comparison cards may show rounded whole rupees.

At reset, the future rate is applied before that month's payment. Under keep tenure, the EMI is recalculated using the balance, future rate and remaining term. Under keep EMI, the schedule continues with the same regular payment and a changing duration.

No fees, taxes, prepayment charges, savings returns or later rate changes are included in Protect. The Repay page's overdue charges are separate and are not added to these scenarios.

## Errors and practical limits

Inputs must be valid numbers. Rates are limited to 0 through 30 percent and the entered tenure to 1 through 360 months. The current EMI must be positive. Contributions cannot be negative. The reset must fall in a valid later payment month within the entered term.

If the EMI does not cover monthly interest, or the repayment schedule extends beyond the 100-year model limit, the page cannot produce a valid comparison. Review the EMI, interest rate or adjustment selection.

If the loan is cleared before reset, future EMI and principal at reset can be zero. The display then shows no remaining repayment term at that point.

## Suggested demonstration steps

1. Review the starting balance, rate, tenure and EMI together.
2. Select a hypothetical future rate such as 10 percent.
3. Select the reset month and explain when that rate begins.
4. Choose whether to preserve the finish date or the EMI.
5. Enter an extra monthly principal amount and press Update comparison.
6. Compare the baseline, extra-payment and cash-reserve cards.
7. Enter a target future EMI and find the extra contribution needed.
8. If desired, enter that contribution in the main form and update the comparison again.

## Questions users commonly ask

**Why does 240 become 228 with keep tenure selected?** Twelve payments occur before the selected reset. The original finish date is preserved, leaving 228 payments from reset.

**Does the future rate start today?** It starts in the selected reset month. The current rate applies beforehand.

**Do extra contributions continue after reset?** No. In the current Protect model, extra payments and reserve contributions stop at reset.

**Why does the reserve card show zero interest savings?** Its cash has not been used to reduce loan principal, and savings interest is not modeled.

**Is the target contribution in addition to the extra amount above?** No. It is a separately calculated alternative monthly extra contribution.

**Does pressing a button change my bank EMI?** No. Protect only calculates scenarios from entered assumptions.

**Does the model promise the displayed future EMI?** No. The result depends on its inputs and monthly calculation rules. Actual lender reset policies, charges and rounding can differ.
