import { getBaseURL } from "@lib/util/env"
import { Metadata } from "next"
import "styles/globals.css"

export const metadata: Metadata = {
  metadataBase: new URL(getBaseURL()),
}

export default function RootLayout(props: { children: React.ReactNode }) {
  return (
    <html lang="fa" data-mode="light" dir="rtl">
      <body>
        <main className="relative">{props.children}</main>
      </body>
    </html>
  )
}
