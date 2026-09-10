const checkEnvVariables = require("./check-env-variables")

checkEnvVariables()

/**
 * Medusa Cloud-related environment variables
 */
const S3_HOSTNAME = process.env.MEDUSA_CLOUD_S3_HOSTNAME
const S3_PATHNAME = process.env.MEDUSA_CLOUD_S3_PATHNAME
const MEDUSA_BACKEND_URL = process.env.NEXT_PUBLIC_MEDUSA_BACKEND_URL
const S3_FILE_URL = process.env.S3_FILE_URL

let medusaBackendPattern = []
let s3FilePattern = []

if (MEDUSA_BACKEND_URL) {
  const backendUrl = new URL(MEDUSA_BACKEND_URL)
  medusaBackendPattern = [
    {
      protocol: backendUrl.protocol.slice(0, -1),
      hostname: backendUrl.hostname,
      port: backendUrl.port,
      pathname: "/static/**",
    },
  ]
}

if (S3_FILE_URL) {
  const fileUrl = new URL(S3_FILE_URL)
  const pathname = fileUrl.pathname.replace(/\/$/, "")

  s3FilePattern = [
    {
      protocol: fileUrl.protocol.slice(0, -1),
      hostname: fileUrl.hostname,
      port: fileUrl.port,
      pathname: `${pathname}/**`,
    },
  ]
}

/**
 * @type {import('next').NextConfig}
 */
const nextConfig = {
  output: "standalone",
  reactStrictMode: true,
  logging: {
    fetches: {
      fullUrl: true,
    },
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
    remotePatterns: [
      {
        protocol: "http",
        hostname: "localhost",
      },
      ...medusaBackendPattern,
      ...s3FilePattern,
      {
        protocol: "https",
        hostname: "*.s3.*.amazonaws.com",
      },
      {
        protocol: "https",
        hostname: "*.s3.amazonaws.com",
      },
      ...(S3_HOSTNAME && S3_PATHNAME
        ? [
            {
              protocol: "https",
              hostname: S3_HOSTNAME,
              pathname: S3_PATHNAME,
            },
          ]
        : []),
    ],
  },
}

module.exports = nextConfig
