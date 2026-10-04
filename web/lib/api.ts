export type User = {
  id: string;
  name: string;
  email: string;
  role: "BORROWER" | "OFFICER";
};
export type Loan = {
  id: string;
  applicantName: string;
  email: string;
  city: string;
  employment: string;
  purpose: string;
  propertyAddress: string;
  coApplicant: string | null;
  income: number;
  coIncome: number;
  obligations: number;
  propertyValue: number;
  requestedAmount: number;
  sanctionedAmount: number;
  annualRate: number;
  tenureMonths: number;
  remainingMonths: number;
  stage: string;
  creditChecked: boolean;
  legalChecked: boolean;
  valuationChecked: boolean;
  sanctionAccepted: boolean;
  closureCertificate: boolean;
  originalsReturned: boolean;
  securityReleased: boolean;
  disbursed: number;
  outstanding: number;
  emi: number;
  paidInterest: number;
  paidPrincipal: number;
  dueDate: string | null;
  revision: number;
  createdAt: string;
};
export type Detail = {
  loan: Loan;
  documents: {
    id: string;
    kind: string;
    filename: string;
    verified: boolean;
  }[];
  queries: {
    id: string;
    question: string;
    response: string | null;
    resolved: boolean;
  }[];
  events: { id: string; message: string; createdAt: string }[];
  payments: {
    id: string;
    kind: string;
    mode: string;
    amount: number;
    status: string;
    reference: string | null;
    createdAt: string;
  }[];
};
export type Row = {
  month: number;
  date: string;
  opening: number;
  rate: number;
  emi: number;
  interest: number;
  principal: number;
  extra: number;
  closing: number;
};
export type Schedule = {
  emi: number;
  interest: number;
  principalPaid: number;
  totalPaid: number;
  months: number;
  payoffDate: string | null;
  rows: Row[];
  warnings: string[];
};
export type Comparison = {
  baseline: Schedule;
  planned: Schedule;
  interestSaved: number;
  monthsSaved: number;
  netSavings: number;
  fees: number;
  assumptions: string[];
};
export type Scenario = {
  principal: number;
  annualRate: number;
  months: number;
  extraMonthly: number;
  annualExtra: number;
  oneTime: number;
  oneTimeMonth: number;
  prepayMode: string;
  resetMonth: number;
  resetRate: number;
  resetMode: string;
  fees: number;
  startDate: string;
};
let csrf = "";
export function setCsrf(token: string) {
  csrf = token;
}
export class ApiError extends Error {
  fields: Record<string, string>;
  constructor(message: string, fields: Record<string, string> = {}) {
    super(message);
    this.fields = fields;
  }
}
export async function api<T>(path: string, body?: unknown): Promise<T> {
  const r = await fetch("/api/" + path, {
    method: body === undefined ? "GET" : "POST",
    headers:
      body === undefined
        ? {}
        : { "Content-Type": "application/json", "X-XSRF-TOKEN": csrf },
    body: body === undefined ? undefined : JSON.stringify(body),
    cache: "no-store",
  });
  const data = await r.json();
  if (!r.ok)
    throw new ApiError(
      data.error || "Unable to complete the request.",
      data.fields,
    );
  return data as T;
}
export async function upload(
  id: string,
  kind: string,
  revision: number,
  file: File,
): Promise<Detail> {
  const body = new FormData();
  body.set("kind", kind);
  body.set("revision", String(revision));
  body.set("file", file);
  const r = await fetch("/api/loans/" + id + "/documents", {
    method: "POST",
    headers: { "X-XSRF-TOKEN": csrf },
    body,
  });
  const data = await r.json();
  if (!r.ok) throw new ApiError(data.error || "Upload failed.");
  return data;
}
export const money = (n: number) =>
  new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(n);
export const date = (d: string | null) =>
  d
    ? new Date(d).toLocaleDateString("en-IN", {
        month: "short",
        day: "numeric",
        year: "numeric",
      })
    : "—";
export const stageLabel = (s: string) =>
  s
    .toLowerCase()
    .replaceAll("_", " ")
    .replace(/^./, (s) => s.toUpperCase());
export const stages = [
  "DRAFT",
  "SUBMITTED",
  "DOCUMENT_REVIEW",
  "CREDIT_REVIEW",
  "PROPERTY_REVIEW",
  "SANCTIONED",
  "DISBURSEMENT",
  "ACTIVE",
  "CLOSED",
];
export const scenarioDefault: Scenario = {
  principal: 4500000,
  annualRate: 8.5,
  months: 240,
  extraMonthly: 5000,
  annualExtra: 25000,
  oneTime: 100000,
  oneTimeMonth: 12,
  prepayMode: "TENURE",
  resetMonth: 0,
  resetRate: 9.5,
  resetMode: "EMI",
  fees: 0,
  startDate: "2026-11-05",
};
