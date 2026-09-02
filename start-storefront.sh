#!/bin/sh
cd /server/apps/storefront

echo "Starting Next.js Starter Storefront development server..."
pnpm exec next dev --turbopack -p 8000 -H 0.0.0.0
