import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "InGrowwth Home Finance",
  description:
    "Understand your home loan, follow your application, and plan a clearer path to repayment.",
};
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <a className="skip-link" href="#main-content">
          Skip to main content
        </a>
        {children}
      </body>
    </html>
  );
}
