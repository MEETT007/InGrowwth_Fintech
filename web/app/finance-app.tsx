"use client";
import { useState, useEffect, useRef, useCallback } from "react";
import {
  House,
  LayoutDashboard,
  Files,
  Calculator,
  BookOpen,
  LogOut,
  Plus,
  Check,
  Upload,
  Download,
  ChevronRight,
  Clock,
  ShieldCheck,
  RefreshCw,
  Menu,
  IndianRupee,
  TrendingDown,
  CalendarDays,
} from "lucide-react";
import {
  api,
  ApiError,
  setCsrf,
  upload,
  User,
  Loan,
  Detail,
  Comparison,
  Scenario,
  Row,
  money,
  date,
  stageLabel,
  stages,
  scenarioDefault,
} from "../lib/api";
const docs = [
  "Identity proof",
  "Income proof",
  "Bank statements",
  "Property documents",
];
function Field({
  label,
  value,
  onChange,
  type = "text",
  error,
  min,
  max,
  step,
  required = false,
}: {
  label: string;
  value: string | number;
  onChange: (v: string) => void;
  type?: string;
  error?: string;
  min?: number;
  max?: number;
  step?: number;
  required?: boolean;
}) {
  const id = "f-" + label.toLowerCase().replace(/[^a-z0-9]/g, "-");
  return (
    <label className="field" htmlFor={id}>
      <span>{label}</span>
      <input
        id={id}
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        required={required}
        min={min}
        max={max}
        step={step}
        aria-invalid={!!error}
        aria-describedby={error ? id + "-error" : undefined}
      />
      {error && (
        <small id={id + "-error"} className="field-error">
          {error}
        </small>
      )}
    </label>
  );
}
function Choice({
  label,
  value,
  onChange,
  options,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: [string, string][];
}) {
  return (
    <label className="field">
      <span>{label}</span>
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        {options.map(([v, l]) => (
          <option value={v} key={v}>
            {l}
          </option>
        ))}
      </select>
    </label>
  );
}
function Status({ value }: { value: string }) {
  return (
    <span
      className={
        "status " +
        (["ACTIVE", "CLOSED", "CONFIRMED", "SANCTIONED"].includes(value)
          ? "positive"
          : "")
      }
    >
      {stageLabel(value)}
    </span>
  );
}
function Chart({ baseline, planned }: { baseline: Row[]; planned: Row[] }) {
  const max = Math.max(1, ...baseline.map((r) => r.opening));
  const n = Math.max(1, baseline.length);
  const path = (rows: Row[]) =>
    `M 0 0 ` +
    rows
      .filter((_, i) => i % 3 === 0 || i === rows.length - 1)
      .map((r) => `L ${(r.month / n) * 640} ${190 - (r.closing / max) * 190}`)
      .join(" ");
  return (
    <figure className="balance-chart">
      <svg
        viewBox="0 0 650 215"
        role="img"
        aria-label="Projected outstanding principal over time, comparing the standard schedule and your plan"
      >
        <title>Outstanding principal comparison</title>
        {[0, 1, 2, 3].map((i) => (
          <line
            key={i}
            x1="0"
            x2="640"
            y1={i * 63}
            y2={i * 63}
            stroke="var(--border)"
            strokeDasharray="4 5"
          />
        ))}
        <path
          d={path(baseline)}
          fill="none"
          stroke="var(--muted)"
          strokeWidth="3"
        />
        <path
          d={path(planned)}
          fill="none"
          stroke="var(--teal)"
          strokeWidth="4"
        />
        <text x="0" y="213" fill="var(--muted)" fontSize="12">
          Today
        </text>
        <text x="540" y="213" fill="var(--muted)" fontSize="12">
          {Math.ceil(n / 12)} years
        </text>
      </svg>
      <figcaption>
        <span>
          <i className="legend standard" />
          Standard schedule
        </span>
        <span>
          <i className="legend planned" />
          Your repayment plan
        </span>
      </figcaption>
    </figure>
  );
}
function ErrorBox({ message }: { message: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    ref.current?.focus();
  }, [message]);
  return message ? (
    <div ref={ref} tabIndex={-1} className="alert error" role="alert">
      {message}
    </div>
  ) : null;
}
export default function FinanceApp() {
  const [user, setUser] = useState<User | null>(null),
    [ready, setReady] = useState(false),
    [view, setView] = useState("Overview"),
    [loans, setLoans] = useState<Loan[]>([]),
    [detail, setDetail] = useState<Detail | null>(null),
    [error, setError] = useState(""),
    [notice, setNotice] = useState(""),
    [busy, setBusy] = useState(false),
    [live, setLive] = useState(false),
    [mobileNav, setMobileNav] = useState(false),
    [showNew, setShowNew] = useState(false);
  const selectedRef = useRef<string | null>(null);
  const refresh = useCallback(async () => {
    const list = await api<Loan[]>("loans");
    setLoans(list);
    const chosen =
      (selectedRef.current && list.find((l) => l.id === selectedRef.current)) ||
      list.find((l) => l.stage === "ACTIVE") ||
      list[0];
    if (chosen) {
      selectedRef.current = chosen.id;
      setDetail(await api<Detail>("loans/" + chosen.id));
    } else setDetail(null);
  }, []);
  useEffect(() => {
    api<{ csrf: string; user: User | null }>("auth/session")
      .then((s) => {
        setCsrf(s.csrf);
        setUser(s.user);
        if (s.user?.role === "OFFICER") setView("Applications");
      })
      .catch((e) => setError(e.message))
      .finally(() => setReady(true));
  }, []);
  useEffect(() => {
    if (!user) return;
    refresh().catch((e) => setError(e.message));
    const stream = new EventSource("/api/events");
    stream.addEventListener("ready", () => setLive(true));
    stream.addEventListener("case-update", () => {
      void refresh().catch((e) => setError(e.message));
    });
    stream.onerror = () => setLive(false);
    return () => {
      stream.close();
      setLive(false);
    };
  }, [user, refresh]);
  async function run(fn: () => Promise<unknown>) {
    setBusy(true);
    setError("");
    setNotice("");
    try {
      await fn();
      await refresh();
      setNotice("Saved. Your workspace is up to date.");
      return true;
    } catch (e) {
      setError(
        e instanceof Error ? e.message : "Unable to complete the request.",
      );
      return false;
    } finally {
      setBusy(false);
    }
  }
  async function open(id: string) {
    setError("");
    selectedRef.current = id;
    try {
      setDetail(await api<Detail>("loans/" + id));
      setView("Applications");
    } catch (e) {
      setError((e as Error).message);
    }
  }
  if (!ready)
    return (
      <main className="loading">
        <House aria-hidden="true" />
        <p>Opening your home-finance workspace…</p>
      </main>
    );
  if (!user)
    return (
      <Login
        onSignIn={(u) => {
          setUser(u);
          setView(u.role === "OFFICER" ? "Applications" : "Overview");
        }}
        initialError={error}
      />
    );
  const officer = user.role === "OFFICER";
  const nav = officer
    ? [
        ["Applications", "Review queue", Files],
        ["Repayment lab", "Repayment lab", Calculator],
        ["Learn", "Loan essentials", BookOpen],
      ]
    : [
        ["Overview", "My home loan", LayoutDashboard],
        ["Applications", "Applications", Files],
        ["Repayment lab", "Repayment lab", Calculator],
        ["Learn", "Loan essentials", BookOpen],
      ];
  return (
    <div className="app">
      <aside className={"sidebar " + (mobileNav ? "nav-open" : "")}>
        <div className="brand">
          <span className="brand-mark">
            <House aria-hidden="true" />
          </span>
          <div>
            <b>InGrowwth</b>
            <span>HOME FINANCE</span>
          </div>
        </div>
        <p className="nav-caption">
          {officer ? "LENDING OPERATIONS" : "YOUR HOME JOURNEY"}
        </p>
        <nav aria-label="Main navigation">
          {nav.map(([id, label, Icon]) => (
            <button
              key={String(id)}
              className={view === id ? "nav-item selected" : "nav-item"}
              aria-current={view === id ? "page" : undefined}
              onClick={() => {
                setView(String(id));
                setMobileNav(false);
              }}
            >
              {typeof Icon !== "string" && <Icon aria-hidden="true" />}
              <span>{String(label)}</span>
            </button>
          ))}
        </nav>
        <div className="sidebar-card">
          <ShieldCheck aria-hidden="true" />
          <b>Clarity at every step.</b>
          <p>
            Know what you owe, what happens next, and how your payments work.
          </p>
        </div>
        <div className="account">
          <span className="avatar">
            {user.name
              .split(" ")
              .map((x) => x[0])
              .join("")
              .slice(0, 2)}
          </span>
          <div>
            <b>{user.name}</b>
            <small>{officer ? "Lending officer" : "Borrower"}</small>
          </div>
          <button
            aria-label="Sign out"
            className="icon-button"
            onClick={async () => {
              try {
                await api("auth/logout", {});
                const s = await api<{ csrf: string }>("auth/session");
                setCsrf(s.csrf);
                setUser(null);
              } catch (e) {
                setError((e as Error).message);
              }
            }}
          >
            <LogOut size={18} />
          </button>
        </div>
      </aside>
      <div className="main">
        <header className="topbar">
          <div>
            <button
              className="icon-button mobile-menu"
              aria-label="Toggle navigation"
              aria-expanded={mobileNav}
              onClick={() => setMobileNav(!mobileNav)}
            >
              <Menu />
            </button>
            <span>
              Home finance{" "}
              <span className="breadcrumb">
                / {officer && view === "Applications" ? "Review queue" : view}
              </span>
            </span>
          </div>
          <div className="topbar-right">
            <span className="sandbox">Sandbox · no money movement</span>
            <span className="connection">
              <i className={live ? "connected" : ""} />
              {live ? "Live updates" : "Reconnecting"}
            </span>
          </div>
        </header>
        <main id="main-content" className="content">
          <div className="page-heading">
            <div>
              <p className="eyebrow">
                {officer ? "LENDING OPERATIONS" : "INGROWWTH HOME FINANCE"}
              </p>
              <h1>
                {view === "Repayment lab"
                  ? "A clearer path to a debt-free home."
                  : view === "Learn"
                    ? "Understand the loan. Own the decisions."
                    : view === "Applications"
                      ? officer
                        ? "Every case, with the context to review."
                        : "Your application, step by step."
                      : `Welcome back, ${user.name.split(" ")[0]}.`}
              </h1>
              <p>
                {view === "Repayment lab"
                  ? "Compare repayment choices using your numbers and explicit assumptions."
                  : view === "Overview"
                    ? "Your loan, your next payment, and your progress in one place."
                    : view === "Applications"
                      ? "Documents, decisions, and milestones—from application to closure."
                      : "Practical explanations for the decisions that matter."}
              </p>
            </div>
            {!officer && view !== "Learn" && view !== "Repayment lab" && (
              <button className="button" onClick={() => setShowNew(true)}>
                <Plus size={18} aria-hidden="true" />
                New application
              </button>
            )}
          </div>
          <ErrorBox message={error} />
          {notice && (
            <div className="alert success" role="status">
              {notice}
            </div>
          )}
          {view === "Overview" &&
            !officer &&
            (detail ? (
              <Overview
                detail={detail}
                onOpen={() => setView("Applications")}
                onPlan={() => setView("Repayment lab")}
                busy={busy}
                request={(kind, amount, mode) =>
                  run(() =>
                    api("loans/" + detail.loan.id + "/payments", {
                      kind,
                      amount,
                      mode,
                      idempotencyKey: crypto.randomUUID(),
                    }),
                  )
                }
              />
            ) : (
              <div className="panel empty">
                <House />
                <h2>Your home journey starts here.</h2>
                <p>
                  Create an application to keep your documents and loan
                  milestones in one place.
                </p>
                <button className="button" onClick={() => setShowNew(true)}>
                  Start an application
                </button>
              </div>
            ))}
          {view === "Applications" && (
            <>
              <ApplicationList
                loans={loans}
                selected={detail?.loan.id}
                onOpen={open}
                officer={officer}
              />
              {detail && (
                <CaseWorkspace
                  key={detail.loan.id}
                  detail={detail}
                  officer={officer}
                  busy={busy}
                  onAction={(action, note = "", targetId = "", amount = 0) =>
                    run(() =>
                      api("loans/" + detail.loan.id + "/actions", {
                        action,
                        note,
                        targetId,
                        amount,
                        revision: detail.loan.revision,
                      }),
                    )
                  }
                  onUpload={(kind, file) =>
                    run(() =>
                      upload(detail.loan.id, kind, detail.loan.revision, file),
                    )
                  }
                  onCancel={(id) =>
                    run(() =>
                      api(`loans/${detail.loan.id}/payments/${id}/cancel`, {}),
                    )
                  }
                  onConfirm={(id, reference) =>
                    run(() =>
                      api(`loans/${detail.loan.id}/payments/${id}/confirm`, {
                        reference,
                      }),
                    )
                  }
                />
              )}
            </>
          )}
          {view === "Repayment lab" && (
            <Planner loan={!officer ? detail?.loan : undefined} />
          )}
          {view === "Learn" && <Education />}
          <footer className="footer">
            <span>InGrowwth Innovations</span>
            <span>Transparent assumptions. Human-reviewed lending.</span>
          </footer>
        </main>
      </div>
      {showNew && (
        <NewApplication
          user={user}
          onClose={() => setShowNew(false)}
          onCreated={async (d) => {
            selectedRef.current = d.loan.id;
            setDetail(d);
            setShowNew(false);
            setView("Applications");
            await refresh();
          }}
        />
      )}
    </div>
  );
}
function Login({
  onSignIn,
  initialError,
}: {
  onSignIn: (u: User) => void;
  initialError: string;
}) {
  const [email, setEmail] = useState(""),
    [password, setPassword] = useState(""),
    [name, setName] = useState(""),
    [register, setRegister] = useState(false),
    [busy, setBusy] = useState(false),
    [error, setError] = useState(initialError),
    [notice, setNotice] = useState(""),
    [local, setLocal] = useState(false);
  useEffect(
    () => setLocal(["127.0.0.1", "localhost"].includes(location.hostname)),
    [],
  );
  return (
    <main className="login-layout">
      <section className="login-story">
        <div className="brand">
          <span className="brand-mark">
            <House />
          </span>
          <div>
            <b>InGrowwth</b>
            <span>HOME FINANCE</span>
          </div>
        </div>
        <div>
          <p className="eyebrow">YOUR HOME. A CLEARER JOURNEY.</p>
          <h1>A home loan you can understand.</h1>
          <p>
            Follow your application, see where every EMI goes, and explore a
            repayment plan that fits your life.
          </p>
          <div className="login-points">
            <span>
              <Files />
              Application to disbursement
            </span>
            <span>
              <Calculator />
              Interest made understandable
            </span>
            <span>
              <TrendingDown />
              Prepayment choices, side by side
            </span>
          </div>
        </div>
        <small>
          Working lending sandbox · live integrations are not connected
        </small>
      </section>
      <section className="login-form">
        <p className="eyebrow">WELCOME TO INGROWWTH</p>
        <h2>
          {register ? "Create your borrower account" : "Open your workspace"}
        </h2>
        <p>Borrowers and lending officers have separate access.</p>
        <ErrorBox message={error} />
        {notice && (
          <p className="alert success" role="status">
            {notice}
          </p>
        )}
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            setBusy(true);
            setError("");
            try {
              if (register) {
                await api("auth/register", { email, password, name });
                setNotice("Account created. Sign in to continue.");
                setRegister(false);
              } else
                onSignIn(await api<User>("auth/login", { email, password }));
            } catch (e) {
              setError((e as Error).message);
            } finally {
              setBusy(false);
            }
          }}
        >
          {register && (
            <Field label="Your name" value={name} onChange={setName} required />
          )}
          <Field
            label="Email address"
            value={email}
            onChange={setEmail}
            type="email"
            required
          />
          <label className="field">
            <span>Password</span>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={register ? 12 : undefined}
              maxLength={72}
              autoComplete={register ? "new-password" : "current-password"}
            />
            {register && <small>Use at least 12 characters.</small>}
          </label>
          <button disabled={busy} className="button full">
            {busy
              ? "Please wait…"
              : register
                ? "Create borrower account"
                : "Sign in"}
          </button>
        </form>
        <button
          className="text-button"
          onClick={() => {
            setRegister(!register);
            setError("");
          }}
        >
          {register
            ? "Already have an account? Sign in"
            : "New here? Create a borrower account"}
        </button>
        {local && (
          <div className="demo-access">
            <b>Explore the local sandbox</b>
            <p>Synthetic accounts for reviewing the two workspaces.</p>
            <div>
              <button
                onClick={() => {
                  setEmail("borrower@demo.ingrowwth");
                  setPassword("DemoHome!2026");
                  setRegister(false);
                }}
              >
                Use borrower account
              </button>
              <button
                onClick={() => {
                  setEmail("officer@demo.ingrowwth");
                  setPassword("DemoHome!2026");
                  setRegister(false);
                }}
              >
                Use officer account
              </button>
            </div>
          </div>
        )}
      </section>
    </main>
  );
}
function Overview({
  detail,
  onOpen,
  onPlan,
  busy,
  request,
}: {
  detail: Detail;
  onOpen: () => void;
  onPlan: () => void;
  busy: boolean;
  request: (kind: string, amount: number, mode: string) => Promise<boolean>;
}) {
  const l = detail.loan,
    [extra, setExtra] = useState(50000),
    [mode, setMode] = useState("TENURE");
  const active = l.stage === "ACTIVE";
  const share = l.disbursed
    ? Math.round((l.paidPrincipal / l.disbursed) * 100)
    : 0;
  return (
    <>
      <div className="overview-grid">
        <section className="loan-hero">
          <div className="hero-top">
            <span>YOUR HOME LOAN</span>
            <Status value={l.stage} />
          </div>
          <h2>{money(active ? l.outstanding : l.requestedAmount)}</h2>
          <p>{active ? "Outstanding principal" : "Requested loan amount"}</p>
          <div className="hero-stats">
            <div>
              <span>Interest rate</span>
              <b>{l.annualRate}% p.a.</b>
            </div>
            <div>
              <span>{active ? "Remaining tenure" : "Requested tenure"}</span>
              <b>{active ? l.remainingMonths : l.tenureMonths} months</b>
            </div>
            <div>
              <span>Property</span>
              <b>{l.city}</b>
            </div>
          </div>
          <div className="loan-progress">
            <div>
              <span>Principal repaid</span>
              <b>{share}%</b>
            </div>
            <progress value={l.paidPrincipal} max={l.disbursed || 1} />
          </div>
          <button className="hero-link" onClick={onOpen}>
            View loan details <ChevronRight size={17} />
          </button>
        </section>
        <section className="panel next-payment">
          <div className="panel-heading">
            <h2>{active ? "Your next EMI" : "Your next milestone"}</h2>
            <CalendarDays aria-hidden="true" />
          </div>
          {active ? (
            <>
              <strong className="big-number">{money(l.emi)}</strong>
              <p className="muted">Due {date(l.dueDate)}</p>
              <div className="payment-parts">
                <div>
                  <span>Estimated interest</span>
                  <b>{money((l.outstanding * l.annualRate) / 1200)}</b>
                </div>
                <div>
                  <span>Estimated principal</span>
                  <b>
                    {money(
                      Math.max(
                        0,
                        l.emi - (l.outstanding * l.annualRate) / 1200,
                      ),
                    )}
                  </b>
                </div>
              </div>
              <button
                disabled={busy}
                className="button full"
                onClick={() => request("EMI", l.emi, "TENURE")}
              >
                Submit sandbox EMI request
              </button>
              <small className="muted">
                No debit occurs. An officer must confirm the request.
              </small>
            </>
          ) : (
            <>
              <p className="milestone-title">{stageLabel(l.stage)}</p>
              <p className="muted">
                {l.stage === "DISBURSEMENT"
                  ? `₹${l.disbursed.toLocaleString("en-IN")} disbursed so far. Estimated monthly pre-EMI interest: ${money((l.disbursed * l.annualRate) / 1200)}.`
                  : "Follow the checklist and respond to any clarification requests."}
              </p>
              <button className="button full" onClick={onOpen}>
                Open application
              </button>
              {l.stage === "DISBURSEMENT" && l.disbursed > 0 && (
                <button
                  className="button secondary full"
                  disabled={busy}
                  onClick={() =>
                    request(
                      "PRE_EMI",
                      Math.round(
                        ((l.outstanding * l.annualRate) / 1200) * 100,
                      ) / 100,
                      "TENURE",
                    )
                  }
                >
                  Request sandbox pre-EMI
                </button>
              )}
            </>
          )}
        </section>
      </div>
      <div className="metrics">
        {[
          [
            "Principal repaid",
            money(l.paidPrincipal),
            "Reduces your outstanding balance",
          ],
          ["Interest paid", money(l.paidInterest), "Cost of borrowing to date"],
          ["Disbursed amount", money(l.disbursed), "Recorded sandbox tranches"],
          [
            "Pending requests",
            String(
              detail.payments.filter((p) => p.status === "PENDING").length,
            ),
            "Awaiting officer confirmation",
          ],
        ].map(([title, value, caption]) => (
          <div className="metric" key={title}>
            <span>{title}</span>
            <strong>{value}</strong>
            <small>{caption}</small>
          </div>
        ))}
      </div>
      <div className="two-columns">
        <section className="panel">
          <div className="panel-heading">
            <h2>Make an informed prepayment choice</h2>
            <TrendingDown />
          </div>
          <p className="muted">
            See the impact first. Shorten the loan to reduce future interest, or
            reduce the EMI to ease monthly commitments.
          </p>
          <div className="choice-cards">
            <div>
              <b>Reduce tenure</b>
              <p>Keep your EMI and finish sooner.</p>
            </div>
            <div>
              <b>Reduce EMI</b>
              <p>Keep the target end date and lower the monthly payment.</p>
            </div>
          </div>
          <button className="button secondary" onClick={onPlan}>
            <Calculator size={18} />
            Explore repayment scenarios
          </button>
        </section>
        <section className="panel">
          <h2>Request a principal prepayment</h2>
          <p className="muted">
            This records a sandbox request; it does not transfer funds.
          </p>
          <div className="form-grid">
            <Field
              label="Prepayment amount (₹)"
              type="number"
              min={1}
              max={l.outstanding}
              value={extra}
              onChange={(v) => setExtra(Number(v))}
            />
            <Choice
              label="What should change?"
              value={mode}
              onChange={setMode}
              options={[
                ["TENURE", "Shorten the tenure"],
                ["EMI", "Reduce the EMI"],
              ]}
            />
          </div>
          <button
            className="button"
            disabled={busy || !active || extra <= 0 || extra > l.outstanding}
            onClick={() => request("PREPAYMENT", extra, mode)}
          >
            Submit sandbox prepayment request
          </button>
        </section>
      </div>
    </>
  );
}
function ApplicationList({
  loans,
  selected,
  onOpen,
  officer,
}: {
  loans: Loan[];
  selected?: string;
  onOpen: (id: string) => void;
  officer: boolean;
}) {
  const [search, setSearch] = useState(""),
    [filter, setFilter] = useState("ALL");
  const list = loans.filter(
    (l) =>
      (filter === "ALL" || l.stage === filter) &&
      `${l.applicantName} ${l.city} ${l.id}`
        .toLowerCase()
        .includes(search.toLowerCase()),
  );
  return (
    <section className="panel register">
      <div className="panel-heading">
        <div>
          <h2>{officer ? "Review queue" : "Your applications"}</h2>
          <p className="muted">
            {loans.length} application{loans.length === 1 ? "" : "s"}
          </p>
        </div>
        <div className="filters">
          <label className="sr-only" htmlFor="case-search">
            Search applications
          </label>
          <input
            id="case-search"
            placeholder="Search applicant or city"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <select
            aria-label="Filter applications by stage"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="ALL">All stages</option>
            {stages.map((s) => (
              <option key={s} value={s}>
                {stageLabel(s)}
              </option>
            ))}
          </select>
        </div>
      </div>
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Applicant</th>
              <th>Purpose</th>
              <th>Requested credit</th>
              <th>Stage</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {list.map((l) => (
              <tr
                className={selected === l.id ? "selected-row" : ""}
                key={l.id}
              >
                <td>
                  <b>{l.applicantName}</b>
                  <small>
                    {l.city} · {l.id.slice(0, 8).toUpperCase()}
                  </small>
                </td>
                <td>{stageLabel(l.purpose)}</td>
                <td>{money(l.requestedAmount)}</td>
                <td>
                  <Status value={l.stage} />
                </td>
                <td>
                  <button className="text-button" onClick={() => onOpen(l.id)}>
                    {selected === l.id ? "Viewing" : "Open case"}
                  </button>
                </td>
              </tr>
            ))}
            {!list.length && (
              <tr>
                <td colSpan={5}>
                  No applications match. Borrowers can create their first
                  application above.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
function CaseWorkspace({
  detail,
  officer,
  busy,
  onAction,
  onUpload,
  onConfirm,
  onCancel,
}: {
  detail: Detail;
  officer: boolean;
  busy: boolean;
  onAction: (
    action: string,
    note?: string,
    targetId?: string,
    amount?: number,
  ) => Promise<boolean>;
  onUpload: (kind: string, file: File) => Promise<boolean>;
  onConfirm: (id: string, reference: string) => Promise<boolean>;
  onCancel: (id: string) => Promise<boolean>;
}) {
  const l = detail.loan,
    [tab, setTab] = useState("Summary"),
    [note, setNote] = useState(""),
    [amount, setAmount] = useState(0),
    [reference, setReference] = useState("");
  return (
    <section className="panel case-workspace">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">CASE {l.id.slice(0, 8).toUpperCase()}</p>
          <h2>{l.applicantName}</h2>
          <p className="muted">{l.propertyAddress}</p>
        </div>
        <Status value={l.stage} />
      </div>
      <ol className="journey">
        {stages.map((s, i) => (
          <li key={s} className={i <= stages.indexOf(l.stage) ? "done" : ""}>
            <span>
              {i < stages.indexOf(l.stage) ? <Check size={14} /> : i + 1}
            </span>
            {stageLabel(s)}
          </li>
        ))}
      </ol>
      <div className="tabs" role="tablist" aria-label="Case sections">
        {["Summary", "Documents", "Clarifications", "Payments", "History"].map(
          (t) => (
            <button
              role="tab"
              aria-selected={tab === t}
              aria-controls={"case-" + t}
              id={"tab-" + t}
              key={t}
              onClick={() => setTab(t)}
              className={tab === t ? "active" : ""}
            >
              {t}
              {t === "Clarifications" &&
                detail.queries.some((q) => !q.resolved) && (
                  <span className="count">
                    {detail.queries.filter((q) => !q.resolved).length}
                  </span>
                )}
            </button>
          ),
        )}
      </div>
      <div role="tabpanel" id={"case-" + tab} aria-labelledby={"tab-" + tab}>
        {tab === "Summary" && (
          <>
            <dl className="detail-grid">
              {[
                ["Requested amount", money(l.requestedAmount)],
                ["Property value", money(l.propertyValue)],
                [
                  "Own contribution",
                  money(l.propertyValue - l.requestedAmount),
                ],
                ["Household monthly income", money(l.income + l.coIncome)],
                ["Existing monthly commitments", money(l.obligations)],
                ["Indicative rate", `${l.annualRate}% p.a.`],
                ["Requested tenure", `${l.tenureMonths} months`],
                ["Co-applicant", l.coApplicant || "None recorded"],
                ["Sanctioned credit", money(l.sanctionedAmount)],
                ["Disbursed credit", money(l.disbursed)],
                ["Outstanding principal", money(l.outstanding)],
                [
                  "Estimated pre-EMI",
                  money((l.disbursed * l.annualRate) / 1200),
                ],
              ].map(([k, v]) => (
                <div key={k}>
                  <dt>{k}</dt>
                  <dd>{v}</dd>
                </div>
              ))}
            </dl>
            <p className="info-note">
              Sanction is a reviewed lending decision. Legal, valuation and
              credit-bureau integrations are represented by manual sandbox
              reviews.
            </p>
            {!officer && l.stage === "DRAFT" && (
              <button
                className="button"
                disabled={busy}
                onClick={() => onAction("SUBMIT")}
              >
                Submit application for review
              </button>
            )}
            {!officer && l.stage === "SANCTIONED" && (
              <div className="sanction">
                <h3>Review your sanction terms</h3>
                <p>
                  {money(l.sanctionedAmount)} at {l.annualRate}% p.a. over{" "}
                  {l.tenureMonths} months. Indicative figures; a production
                  offer requires the lender’s Key Facts Statement and signed
                  agreement.
                </p>
                <button
                  className="button"
                  disabled={busy}
                  onClick={() => onAction("ACCEPT_SANCTION")}
                >
                  Accept sandbox sanction terms
                </button>
              </div>
            )}
            {l.stage === "CLOSED" && (
              <div className="sanction">
                <h3>Complete the closure journey</h3>
                {(
                  [
                    [
                      "CERTIFICATE",
                      "closureCertificate",
                      "Closure / no-dues certificate",
                    ],
                    [
                      "ORIGINALS",
                      "originalsReturned",
                      "Original property documents returned",
                    ],
                    [
                      "SECURITY",
                      "securityReleased",
                      "Lender security interest released",
                    ],
                  ] as const
                ).map(([key, field, text]) => (
                  <div className="document" key={key}>
                    <span>{text}</span>
                    <Status value={l[field] ? "CONFIRMED" : "PENDING"} />
                    {officer && !l[field] && (
                      <button
                        className="button secondary"
                        disabled={busy}
                        onClick={() => onAction("CLOSURE_CHECK", "", key)}
                      >
                        Record completion
                      </button>
                    )}
                  </div>
                ))}
              </div>
            )}
            {officer && l.stage !== "CLOSED" && (
              <div className="officer-actions">
                <h3>Officer actions</h3>
                <label className="field">
                  <span>Review rationale or reference</span>
                  <textarea
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    placeholder="Record the evidence and reason for this action"
                    maxLength={1000}
                  />
                </label>
                <div className="action-buttons">
                  {["SUBMITTED", "DOCUMENT_REVIEW", "CREDIT_REVIEW"].includes(
                    l.stage,
                  ) && (
                    <button
                      className="button"
                      disabled={busy}
                      onClick={() => onAction("ADVANCE")}
                    >
                      Advance review stage
                    </button>
                  )}
                  {l.stage === "CREDIT_REVIEW" && (
                    <button
                      className="button secondary"
                      disabled={
                        busy || l.creditChecked || note.trim().length < 5
                      }
                      onClick={() => onAction("REVIEW", note, "CREDIT")}
                    >
                      {l.creditChecked
                        ? "Credit review recorded"
                        : "Record credit review"}
                    </button>
                  )}
                  {l.stage === "PROPERTY_REVIEW" && (
                    <>
                      <button
                        className="button secondary"
                        disabled={
                          busy || l.legalChecked || note.trim().length < 5
                        }
                        onClick={() => onAction("REVIEW", note, "LEGAL")}
                      >
                        {l.legalChecked
                          ? "Legal review recorded"
                          : "Record legal review"}
                      </button>
                      <button
                        className="button secondary"
                        disabled={
                          busy || l.valuationChecked || note.trim().length < 5
                        }
                        onClick={() => onAction("REVIEW", note, "VALUATION")}
                      >
                        {l.valuationChecked
                          ? "Valuation recorded"
                          : "Record valuation review"}
                      </button>
                      <button
                        className="button"
                        disabled={
                          busy ||
                          !l.creditChecked ||
                          !l.legalChecked ||
                          !l.valuationChecked ||
                          note.trim().length < 5
                        }
                        onClick={() => onAction("SANCTION", note)}
                      >
                        Record sandbox sanction
                      </button>
                    </>
                  )}
                  {l.stage === "DISBURSEMENT" && (
                    <>
                      <Field
                        label="Tranche amount (₹)"
                        type="number"
                        min={1}
                        max={l.sanctionedAmount - l.disbursed}
                        value={amount}
                        onChange={(v) => setAmount(Number(v))}
                      />
                      <button
                        className="button"
                        disabled={busy || amount <= 0 || note.trim().length < 4}
                        onClick={() => onAction("DISBURSE", note, "", amount)}
                      >
                        Record sandbox disbursement
                      </button>
                    </>
                  )}
                </div>
              </div>
            )}
          </>
        )}
        {tab === "Documents" && (
          <>
            <p className="muted">
              PDF, PNG or JPEG · maximum 5 MB. Verification requires a lending
              officer.
            </p>
            {docs.map((kind) => (
              <div key={kind} className="document-category">
                <div>
                  <h3>{kind}</h3>
                  {!officer &&
                    ![
                      "SANCTIONED",
                      "DISBURSEMENT",
                      "ACTIVE",
                      "CLOSED",
                    ].includes(l.stage) && (
                      <label className="upload-button">
                        <Upload size={17} />
                        Upload
                        <input
                          type="file"
                          disabled={busy}
                          accept=".pdf,.png,.jpg,.jpeg"
                          aria-label={`Upload ${kind}`}
                          onChange={async (e) => {
                            if (e.target.files?.[0])
                              await onUpload(kind, e.target.files[0]);
                            e.target.value = "";
                          }}
                        />
                      </label>
                    )}
                </div>
                {detail.documents
                  .filter((d) => d.kind === kind)
                  .map((d) => (
                    <div className="document" key={d.id}>
                      <span>{d.filename}</span>
                      <Status value={d.verified ? "CONFIRMED" : "PENDING"} />
                      <a
                        className="text-button"
                        href={`/api/loans/${l.id}/documents/${d.id}`}
                      >
                        <Download size={16} />
                        Download
                      </a>
                      {officer &&
                        !d.verified &&
                        ![
                          "SANCTIONED",
                          "DISBURSEMENT",
                          "ACTIVE",
                          "CLOSED",
                        ].includes(l.stage) && (
                          <button
                            className="button secondary"
                            disabled={busy}
                            onClick={() =>
                              onAction("VERIFY_DOCUMENT", "", d.id)
                            }
                          >
                            Verify document
                          </button>
                        )}
                    </div>
                  ))}
                {!detail.documents.some((d) => d.kind === kind) && (
                  <p className="muted">Not uploaded yet.</p>
                )}
              </div>
            ))}
          </>
        )}
        {tab === "Clarifications" && (
          <>
            {detail.queries.map((q) => (
              <div className="query" key={q.id}>
                <h3>{q.question}</h3>
                {q.response && (
                  <p>
                    <b>Applicant response:</b> {q.response}
                  </p>
                )}
                {q.resolved ? (
                  <Status value="CONFIRMED" />
                ) : officer ? (
                  <button
                    className="button secondary"
                    disabled={busy || !q.response}
                    onClick={() => onAction("RESOLVE_QUERY", "", q.id)}
                  >
                    Accept response and resolve
                  </button>
                ) : (
                  <div>
                    <label className="field">
                      <span>Your response</span>
                      <textarea
                        value={note}
                        maxLength={1000}
                        onChange={(e) => setNote(e.target.value)}
                      />
                    </label>
                    <button
                      className="button"
                      disabled={busy || note.trim().length < 5}
                      onClick={() => onAction("RESPOND", note, q.id)}
                    >
                      Send response
                    </button>
                  </div>
                )}
              </div>
            ))}
            {!detail.queries.length && (
              <p className="muted">No clarifications have been requested.</p>
            )}
            {officer && l.stage !== "CLOSED" && (
              <div className="query">
                <label className="field">
                  <span>Request information from the applicant</span>
                  <textarea
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    maxLength={1000}
                  />
                </label>
                <button
                  className="button"
                  disabled={busy || note.trim().length < 5}
                  onClick={() => onAction("QUERY", note)}
                >
                  Request clarification
                </button>
              </div>
            )}
          </>
        )}
        {tab === "Payments" && (
          <>
            <p className="info-note">
              Requests remain pending until an officer records confirmation.
              These entries do not connect to a payment network or move money.
            </p>
            {officer && (
              <Field
                label="Sandbox payment reference"
                value={reference}
                onChange={setReference}
              />
            )}
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>Request</th>
                    <th>Amount</th>
                    <th>Status</th>
                    <th>Reference / action</th>
                  </tr>
                </thead>
                <tbody>
                  {detail.payments.map((p) => (
                    <tr key={p.id}>
                      <td>
                        {stageLabel(p.kind)}
                        <small>
                          {date(p.createdAt)} ·{" "}
                          {p.mode === "TENURE" ? "Keep EMI" : "Reduce EMI"}
                        </small>
                      </td>
                      <td>{money(p.amount)}</td>
                      <td>
                        <Status value={p.status} />
                      </td>
                      <td>
                        {officer && p.status === "PENDING" ? (
                          <button
                            className="button secondary"
                            disabled={busy || reference.trim().length < 4}
                            onClick={() => onConfirm(p.id, reference)}
                          >
                            Confirm sandbox payment
                          </button>
                        ) : (
                          p.reference ||
                          (p.status === "CANCELLED"
                            ? "Cancelled"
                            : "Awaiting confirmation")
                        )}
                        {p.status === "PENDING" && (
                          <button
                            className="text-button"
                            disabled={busy}
                            onClick={() => onCancel(p.id)}
                          >
                            Cancel request
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                  {!detail.payments.length && (
                    <tr>
                      <td colSpan={4}>No payment requests recorded.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </>
        )}
        {tab === "History" && (
          <ol className="history">
            {detail.events.map((e) => (
              <li key={e.id}>
                <span />
                <div>
                  <p>{e.message}</p>
                  <small>
                    {new Date(e.createdAt).toLocaleString("en-IN", {
                      timeZone: "Asia/Kolkata",
                    })}{" "}
                    IST
                  </small>
                </div>
              </li>
            ))}
            {!detail.events.length && (
              <p className="muted">
                This synthetic loan was loaded as a sandbox example.
              </p>
            )}
          </ol>
        )}
      </div>
    </section>
  );
}
function Planner({ loan }: { loan?: Loan }) {
  const [input, setInput] = useState<Scenario>(scenarioDefault),
    [result, setResult] = useState<Comparison | null>(null),
    [error, setError] = useState(""),
    [busy, setBusy] = useState(false),
    [dirty, setDirty] = useState(false),
    [page, setPage] = useState(0),
    [schedule, setSchedule] = useState("planned"),
    [income, setIncome] = useState(125000),
    [expenses, setExpenses] = useState(55000),
    [savings, setSavings] = useState(300000),
    [reserveMonths, setReserveMonths] = useState(6),
    [newRate, setNewRate] = useState(7.75),
    [transferFees, setTransferFees] = useState(25000),
    [transfer, setTransfer] = useState<{
      currentEmi: number;
      newEmi: number;
      monthlySaving: number;
      netSaving: number;
      breakEvenMonths: number | null;
      assumption: string;
    } | null>(null);
  async function compare(value: Scenario) {
    setBusy(true);
    setError("");
    try {
      setResult(await api<Comparison>("planner", value));
      setDirty(false);
      setPage(0);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  useEffect(() => {
    const value = loan
      ? {
          ...scenarioDefault,
          principal:
            loan.outstanding > 0 ? loan.outstanding : loan.requestedAmount,
          annualRate: loan.annualRate,
          months: loan.remainingMonths || loan.tenureMonths,
          startDate: loan.dueDate || scenarioDefault.startDate,
        }
      : scenarioDefault;
    setInput(value);
    setIncome(loan ? loan.income + loan.coIncome : 125000);
    void compare(value);
  }, [loan?.id]);
  function change(key: keyof Scenario, value: string) {
    setInput((old) => ({
      ...old,
      [key]: ["prepayMode", "resetMode", "startDate"].includes(key)
        ? value
        : Number(value),
    }));
    setDirty(true);
    setTransfer(null);
  }
  const rows =
    result?.[schedule === "planned" ? "planned" : "baseline"].rows || [];
  const reserve = expenses * reserveMonths;
  const monthlyHeadroom =
    result && !dirty
      ? income - expenses - result.baseline.emi - input.extraMonthly
      : null;
  function exportSchedule() {
    if (!result) return;
    const csv = [
      "Month,Date,Opening balance,Rate,EMI,Interest,Principal,Extra principal,Closing balance",
      ...rows.map((r) =>
        [
          r.month,
          r.date,
          r.opening,
          r.rate,
          r.emi,
          r.interest,
          r.principal,
          r.extra,
          r.closing,
        ].join(","),
      ),
    ].join("\n");
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = "repayment-scenario.csv";
    a.click();
    URL.revokeObjectURL(url);
  }
  return (
    <div className="planner">
      <ErrorBox message={error} />
      <div className="planner-grid">
        <section className="panel scenario-controls">
          <div className="panel-heading">
            <h2>Your loan and repayment choices</h2>
            <Calculator />
          </div>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              void compare(input);
            }}
          >
            <div className="form-grid">
              {[
                ["principal", "Outstanding principal (₹)", 1000, 1e9],
                ["annualRate", "Annual interest rate (%)", 0, 30],
                ["months", "Remaining tenure (months)", 1, 360],
              ].map(([k, l, min, max]) => (
                <Field
                  key={String(k)}
                  label={String(l)}
                  type="number"
                  min={Number(min)}
                  max={Number(max)}
                  step={k === "annualRate" ? 0.01 : 1}
                  required
                  value={input[k as keyof Scenario]}
                  onChange={(v) => change(k as keyof Scenario, v)}
                />
              ))}
              <Field
                label="First payment date"
                type="date"
                required
                value={input.startDate}
                onChange={(v) => change("startDate", v)}
              />
            </div>
            <fieldset>
              <legend>Pay additional principal</legend>
              <div className="form-grid">
                {[
                  ["extraMonthly", "Extra each month (₹)"],
                  ["annualExtra", "Extra every year (₹)"],
                  ["oneTime", "One-time payment (₹)"],
                  ["oneTimeMonth", "One-time payment month"],
                ].map(([k, l]) => (
                  <Field
                    key={k}
                    label={l}
                    type="number"
                    min={k === "oneTimeMonth" ? 1 : 0}
                    max={k === "oneTimeMonth" ? input.months : 1e9}
                    value={input[k as keyof Scenario]}
                    onChange={(v) => change(k as keyof Scenario, v)}
                  />
                ))}
                <Choice
                  label="After prepayment"
                  value={input.prepayMode}
                  onChange={(v) => change("prepayMode", v)}
                  options={[
                    ["TENURE", "Keep EMI · shorten tenure"],
                    ["EMI", "Keep maturity · reduce EMI"],
                  ]}
                />
                <Field
                  label="Total scenario fees (₹)"
                  type="number"
                  min={0}
                  value={input.fees}
                  onChange={(v) => change("fees", v)}
                />
              </div>
            </fieldset>
            <details>
              <summary>Stress-test a future rate change</summary>
              <p className="muted">
                Choose a rate and month; this is a scenario, not a rate
                forecast. Month 0 disables the reset.
              </p>
              <div className="form-grid">
                <Field
                  label="Rate reset month"
                  type="number"
                  min={0}
                  max={input.months}
                  value={input.resetMonth}
                  onChange={(v) => change("resetMonth", v)}
                />
                <Field
                  label="New annual rate (%)"
                  type="number"
                  min={0}
                  max={30}
                  step={0.01}
                  value={input.resetRate}
                  onChange={(v) => change("resetRate", v)}
                />
                <Choice
                  label="When the rate resets"
                  value={input.resetMode}
                  onChange={(v) => change("resetMode", v)}
                  options={[
                    ["EMI", "Recalculate EMI · keep tenure"],
                    ["TENURE", "Keep EMI · change tenure"],
                  ]}
                />
              </div>
            </details>
            <button className="button full" disabled={busy}>
              {busy
                ? "Calculating…"
                : dirty
                  ? "Update comparison"
                  : "Compare repayment plan"}
            </button>
          </form>
          <p className="muted small-note">
            Extra principal is applied after the month’s scheduled payment.
            Annual extras occur every 12 months.
          </p>
        </section>
        <div>
          {result && (
            <>
              <section className="payoff-card">
                <p className="eyebrow">YOUR PROJECTED PATH</p>
                <h2>
                  {result.monthsSaved > 0
                    ? `${Math.floor(result.monthsSaved / 12)} years ${result.monthsSaved % 12} months sooner`
                    : "See the effect on your monthly commitment"}
                </h2>
                <p>
                  Projected payoff: <b>{date(result.planned.payoffDate)}</b>
                </p>
                <div className="payoff-stats">
                  <div>
                    <span>Interest saved</span>
                    <strong>{money(result.interestSaved)}</strong>
                  </div>
                  <div>
                    <span>After scenario fees</span>
                    <strong>{money(result.netSavings)}</strong>
                  </div>
                </div>
                {dirty && (
                  <div className="dirty-note">
                    Inputs changed. Update the comparison to refresh these
                    results.
                  </div>
                )}
              </section>
              <section className="panel chart-panel">
                <div className="panel-heading">
                  <h2>Watch the outstanding balance decline</h2>
                  <TrendingDown />
                </div>
                <Chart
                  baseline={result.baseline.rows}
                  planned={result.planned.rows}
                />
                <div className="comparison-table">
                  <div>
                    <span>Standard schedule</span>
                    <b>{money(result.baseline.interest)}</b>
                    <small>
                      Total remaining interest · {result.baseline.months} months
                    </small>
                  </div>
                  <div>
                    <span>Your plan</span>
                    <b>{money(result.planned.interest)}</b>
                    <small>
                      Total remaining interest · {result.planned.months} months
                    </small>
                  </div>
                </div>
              </section>
              <div className="info-note">
                Savings are projected under the inputs shown. Lender rules,
                actual posting dates, rate changes, and fees can change the
                outcome. Keep liquidity needs in view before choosing extra
                payments.
              </div>
            </>
          )}
        </div>
      </div>
      <div className="two-columns">
        <section className="panel">
          <div className="panel-heading">
            <h2>Check the room in your budget</h2>
            <IndianRupee />
          </div>
          <div className="form-grid">
            <Field
              label="Household monthly income (₹)"
              type="number"
              min={0}
              value={income}
              onChange={(v) => setIncome(Number(v))}
            />
            <Field
              label="Living costs and other commitments (₹)"
              type="number"
              min={0}
              value={expenses}
              onChange={(v) => setExpenses(Number(v))}
            />
            <Field
              label="Accessible savings (₹)"
              type="number"
              min={0}
              value={savings}
              onChange={(v) => setSavings(Number(v))}
            />
            <Field
              label="Reserve target (months of costs)"
              type="number"
              min={0}
              max={24}
              value={reserveMonths}
              onChange={(v) => setReserveMonths(Number(v))}
            />
          </div>
          <div className="budget-results">
            <div>
              <span>
                Monthly amount left after costs, EMI and extra payment
              </span>
              <b
                className={
                  monthlyHeadroom !== null && monthlyHeadroom < 0
                    ? "negative"
                    : ""
                }
              >
                {monthlyHeadroom === null
                  ? "Update comparison first"
                  : money(monthlyHeadroom)}
              </b>
            </div>
            <div>
              <span>Reserve target you chose</span>
              <b>{money(reserve)}</b>
            </div>
            <div>
              <span>Gap to that reserve</span>
              <b>{money(Math.max(0, reserve - savings))}</b>
            </div>
          </div>
          <p className="muted">
            This check uses the initial EMI and your declared costs. A reserve
            target is your input, not a personalised recommendation.
          </p>
        </section>
        <section className="panel">
          <div className="panel-heading">
            <h2>Would a balance transfer help?</h2>
            <RefreshCw />
          </div>
          <p className="muted">
            Compare the same balance and remaining tenure with a new rate.
            Include all transfer costs.
          </p>
          <div className="form-grid">
            <Field
              label="New lender’s annual rate (%)"
              type="number"
              min={0}
              max={30}
              step={0.01}
              value={newRate}
              onChange={(v) => {
                setNewRate(Number(v));
                setTransfer(null);
              }}
            />
            <Field
              label="Processing, legal and other costs (₹)"
              type="number"
              min={0}
              value={transferFees}
              onChange={(v) => {
                setTransferFees(Number(v));
                setTransfer(null);
              }}
            />
          </div>
          <button
            className="button secondary"
            disabled={busy}
            onClick={async () => {
              setError("");
              try {
                setTransfer(
                  await api("refinance", {
                    principal: input.principal,
                    currentRate: input.annualRate,
                    newRate,
                    months: input.months,
                    fees: transferFees,
                  }),
                );
              } catch (e) {
                setError((e as Error).message);
              }
            }}
          >
            Compare transfer costs
          </button>
          {transfer && (
            <div className="budget-results">
              <div>
                <span>Indicative new EMI</span>
                <b>{money(transfer.newEmi)}</b>
              </div>
              <div>
                <span>Monthly difference</span>
                <b>{money(transfer.monthlySaving)}</b>
              </div>
              <div>
                <span>Fee recovery period</span>
                <b>
                  {transfer.breakEvenMonths === null
                    ? "No monthly saving"
                    : `${transfer.breakEvenMonths} months`}
                </b>
              </div>
              <div>
                <span>Projected net saving</span>
                <b>{money(transfer.netSaving)}</b>
              </div>
              <p className="muted">{transfer.assumption}</p>
            </div>
          )}
        </section>
      </div>
      {result && (
        <section className="panel schedule-panel">
          <div className="panel-heading">
            <div>
              <h2>Where each payment goes</h2>
              <p className="muted">
                Monthly principal, interest, and extra payments—rounded to
                paise.
              </p>
            </div>
            <div className="filters">
              <select
                aria-label="Select repayment schedule"
                value={schedule}
                onChange={(e) => {
                  setSchedule(e.target.value);
                  setPage(0);
                }}
              >
                <option value="planned">Your plan</option>
                <option value="baseline">Standard schedule</option>
              </select>
              <button className="button secondary" onClick={exportSchedule}>
                <Download size={16} />
                Download schedule
              </button>
            </div>
          </div>
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  {[
                    "Month",
                    "Date",
                    "EMI",
                    "Interest",
                    "Principal",
                    "Extra payment",
                    "Balance",
                  ].map((h) => (
                    <th key={h}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.slice(page * 12, page * 12 + 12).map((r) => (
                  <tr key={r.month}>
                    <td>{r.month}</td>
                    <td>{date(r.date)}</td>
                    <td>{money(r.emi)}</td>
                    <td>{money(r.interest)}</td>
                    <td>{money(r.principal)}</td>
                    <td>{money(r.extra)}</td>
                    <td>{money(r.closing)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="pagination">
            <button
              className="button secondary"
              disabled={page === 0}
              onClick={() => setPage(page - 1)}
            >
              Previous 12 months
            </button>
            <span>
              Months {page * 12 + 1}–{Math.min(rows.length, page * 12 + 12)} of{" "}
              {rows.length}
            </span>
            <button
              className="button secondary"
              disabled={(page + 1) * 12 >= rows.length}
              onClick={() => setPage(page + 1)}
            >
              Next 12 months
            </button>
          </div>
          <details className="assumptions">
            <summary>Calculation assumptions</summary>
            <ul>
              {result.assumptions.map((x) => (
                <li key={x}>{x}</li>
              ))}
            </ul>
          </details>
        </section>
      )}
    </div>
  );
}
function NewApplication({
  user,
  onClose,
  onCreated,
}: {
  user: User;
  onClose: () => void;
  onCreated: (d: Detail) => Promise<void>;
}) {
  const modal = useRef<HTMLDialogElement>(null);
  const [step, setStep] = useState(0),
    [busy, setBusy] = useState(false),
    [error, setError] = useState(""),
    [fields, setFields] = useState<Record<string, string>>({}),
    [form, setForm] = useState({
      applicantName: user.name,
      email: user.email,
      city: "Ahmedabad",
      employment: "SALARIED",
      purpose: "PURCHASE",
      propertyAddress: "",
      coApplicant: "",
      income: 125000,
      coIncome: 0,
      obligations: 10000,
      propertyValue: 6500000,
      requestedAmount: 4500000,
      annualRate: 8.5,
      tenureMonths: 240,
    });
  useEffect(() => {
    modal.current?.showModal();
  }, []);
  function change(k: keyof typeof form, v: string) {
    setForm((old) => ({
      ...old,
      [k]: typeof old[k] === "number" ? Number(v) : v,
    }));
    setFields((old) => ({ ...old, [k]: "" }));
  }
  return (
    <dialog
      ref={modal}
      className="application-modal"
      aria-labelledby="application-title"
      onCancel={(e) => {
        e.preventDefault();
        if (!busy) onClose();
      }}
    >
      <div className="modal-heading">
        <div>
          <p className="eyebrow">NEW HOME-LOAN APPLICATION</p>
          <h2 id="application-title">
            {
              [
                "Your household",
                "Property and loan",
                "Review your application",
              ][step]
            }
          </h2>
        </div>
        <button
          className="icon-button"
          aria-label="Close application form"
          disabled={busy}
          onClick={onClose}
        >
          ×
        </button>
      </div>
      <div className="form-steps" aria-label="Application steps">
        {["Household", "Property & finance", "Review"].map((x, i) => (
          <span key={x} className={step === i ? "current" : ""}>
            {i + 1}. {x}
          </span>
        ))}
      </div>
      <ErrorBox message={error} />
      <form
        onSubmit={async (e) => {
          e.preventDefault();
          if (step < 2) {
            setStep(step + 1);
            return;
          }
          setBusy(true);
          setError("");
          try {
            await onCreated(await api<Detail>("loans", form));
          } catch (e) {
            setError((e as Error).message);
            setFields(e instanceof ApiError ? e.fields : {});
          } finally {
            setBusy(false);
          }
        }}
      >
        {step === 0 && (
          <div className="form-grid">
            {[
              ["applicantName", "Applicant name"],
              ["email", "Applicant email"],
              ["coApplicant", "Co-applicant name (optional)"],
              ["city", "Property city"],
            ].map(([k, l]) => (
              <Field
                key={k}
                label={l}
                type={k === "email" ? "email" : "text"}
                required={k !== "coApplicant"}
                value={form[k as keyof typeof form]}
                onChange={(v) => change(k as keyof typeof form, v)}
                error={fields[k]}
              />
            ))}
            <Choice
              label="Employment"
              value={form.employment}
              onChange={(v) => change("employment", v)}
              options={[
                ["SALARIED", "Salaried"],
                ["SELF_EMPLOYED", "Self-employed"],
              ]}
            />
            {[
              ["income", "Net monthly income (₹)"],
              ["coIncome", "Co-applicant net monthly income (₹)"],
              ["obligations", "Existing monthly EMIs (₹)"],
            ].map(([k, l]) => (
              <Field
                key={k}
                label={l}
                required
                type="number"
                min={k === "income" ? 1 : 0}
                value={form[k as keyof typeof form]}
                onChange={(v) => change(k as keyof typeof form, v)}
                error={fields[k]}
              />
            ))}
          </div>
        )}
        {step === 1 && (
          <>
            <Choice
              label="Loan purpose"
              value={form.purpose}
              onChange={(v) => change("purpose", v)}
              options={[
                ["PURCHASE", "Purchase a completed property"],
                ["CONSTRUCTION", "Under-construction property"],
              ]}
            />
            <Field
              label="Property address"
              required
              value={form.propertyAddress}
              onChange={(v) => change("propertyAddress", v)}
              error={fields.propertyAddress}
            />
            <div className="form-grid">
              {[
                ["propertyValue", "Property value (₹)", 10000, 1e9],
                ["requestedAmount", "Requested loan (₹)", 10000, 1e9],
                ["annualRate", "Indicative annual rate (%)", 0, 30],
                ["tenureMonths", "Requested tenure (months)", 12, 360],
              ].map(([k, l, min, max]) => (
                <Field
                  key={String(k)}
                  label={String(l)}
                  required
                  type="number"
                  min={Number(min)}
                  max={Number(max)}
                  step={k === "annualRate" ? 0.01 : 1}
                  value={form[k as keyof typeof form]}
                  onChange={(v) => change(k as keyof typeof form, v)}
                  error={fields[String(k)]}
                />
              ))}
            </div>
            <p className="info-note">
              You need an own contribution of{" "}
              {money(Math.max(0, form.propertyValue - form.requestedAmount))},
              plus applicable purchase and loan costs.
            </p>
          </>
        )}
        {step === 2 && (
          <>
            <dl className="detail-grid">
              {Object.entries(form).map(([k, v]) => (
                <div key={k}>
                  <dt>{k.replace(/([A-Z])/g, " $1")}</dt>
                  <dd>{String(v) || "Not provided"}</dd>
                </div>
              ))}
            </dl>
            {Object.keys(fields).length > 0 && (
              <p className="field-error">
                Return to the household or property step to correct the fields
                above.
              </p>
            )}
            <p className="info-note">
              This creates a draft. You can upload documents and submit it for
              officer review from the application workspace.
            </p>
          </>
        )}
        <div className="modal-footer">
          <button
            type="button"
            className="button secondary"
            disabled={busy}
            onClick={() => (step === 0 ? onClose() : setStep(step - 1))}
          >
            {step === 0 ? "Cancel" : "Back"}
          </button>
          <span>Step {step + 1} of 3</span>
          <button className="button" disabled={busy}>
            {busy
              ? "Saving…"
              : step === 2
                ? "Create draft application"
                : "Continue"}
          </button>
        </div>
      </form>
    </dialog>
  );
}
function Education() {
  const items = [
    [
      "Why does interest take a large share of early EMIs?",
      "Interest is charged on the outstanding principal. Early in the loan, that balance is high. As principal is repaid, the interest portion falls. The repayment schedule shows that change month by month.",
    ],
    [
      "What does a principal prepayment change?",
      "An additional principal payment reduces the balance on which future interest is calculated. Keeping the EMI can shorten tenure; keeping the target maturity can reduce the EMI. Actual options, fees, and posting dates depend on the lender and your contract.",
    ],
    [
      "What happens when a floating rate changes?",
      "A rate increase can change the EMI, tenure, or both. RBI guidance describes borrower communication and available options for covered EMI-based personal loans. Ask your lender for the revised schedule and the cost of any switch to a fixed rate.",
    ],
    [
      "What is pre-EMI on an under-construction home?",
      "A lender may disburse the loan in stages. Before regular amortising EMIs begin, you may pay interest on the amount already disbursed. That payment generally does not repay the principal. The construction and disbursement terms determine the actual arrangement.",
    ],
    [
      "How should I compare a balance transfer?",
      "Compare the new rate, remaining tenure, processing and legal costs, valuation fees, and any applicable closure charges. A lower EMI alone can hide a longer loan. Compare total remaining costs and the fee-recovery period.",
    ],
    [
      "What should I receive when the loan is closed?",
      "Ask for a closure or no-dues certificate, release of the lender’s security interest, and return of original property documents. Track these as separate closure tasks with the lender.",
    ],
  ];
  return (
    <div className="education-grid">
      {items.map(([title, text], i) => (
        <article className="panel education" key={title}>
          <span className="lesson-number">0{i + 1}</span>
          <h2>{title}</h2>
          <p>{text}</p>
        </article>
      ))}
      <section className="panel sources">
        <h2>Read the original guidance</h2>
        <p>
          These explanations are educational. Your lender’s current agreement
          and Key Facts Statement govern the actual loan.
        </p>
        <a
          href="https://www.rbi.org.in/commonman/Upload/English/FAQs/PDFs/FAQRFIR10012025.pdf"
          target="_blank"
          rel="noreferrer"
        >
          RBI: floating-rate EMI reset FAQ
        </a>
        <a
          href="https://rbi.org.in/CommonPerson/english/scripts/FAQs.aspx?Id=701"
          target="_blank"
          rel="noreferrer"
        >
          RBI: home-loan consumer guidance
        </a>
        <a
          href="https://homeloans.hdfc.bank.in/housing-loans/home-loans/home-loan-process"
          target="_blank"
          rel="noreferrer"
        >
          HDFC Bank: home-loan process
        </a>
        <a
          href="https://homeloans.hdfc.bank.in/blog/home-finance/disbursement-home-loan"
          target="_blank"
          rel="noreferrer"
        >
          HDFC Bank: staged disbursement
        </a>
      </section>
    </div>
  );
}
