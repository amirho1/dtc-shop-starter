import { loadEnv, defineConfig } from "@medusajs/framework/utils"

loadEnv(process.env.NODE_ENV || "development", process.cwd())

const isProduction = process.env.NODE_ENV === "production"
const redisUrl = process.env.REDIS_URL
const cacheRedisUrl = process.env.CACHE_REDIS_URL || redisUrl
const lockingRedisUrl = process.env.LOCKING_REDIS_URL || redisUrl
const useS3 = process.env.FILE_PROVIDER === "s3"

const fileProvider = useS3
  ? {
      resolve: "@medusajs/medusa/file-s3",
      id: "s3",
      options: {
        file_url: process.env.S3_FILE_URL,
        access_key_id: process.env.S3_ACCESS_KEY_ID,
        secret_access_key: process.env.S3_SECRET_ACCESS_KEY,
        region: process.env.S3_REGION,
        bucket: process.env.S3_BUCKET,
        endpoint: process.env.S3_ENDPOINT,
        prefix: process.env.S3_PREFIX,
        additional_client_config: {
          forcePathStyle: process.env.S3_FORCE_PATH_STYLE === "true",
        },
      },
    }
  : {
      resolve: "@medusajs/medusa/file-local",
      id: "local",
      options: {
        backend_url: `${process.env.MEDUSA_BACKEND_URL}/static`,
        upload_dir: "/server/static",
        private_upload_dir: "/server/static",
      },
    }

const redisModules = redisUrl
  ? [
      {
        resolve: "@medusajs/medusa/event-bus-redis",
        options: { redisUrl },
      },
      {
        resolve: "@medusajs/medusa/workflow-engine-redis",
        options: { redis: { redisUrl } },
      },
      {
        resolve: "@medusajs/medusa/locking",
        options: {
          providers: [
            {
              resolve: "@medusajs/medusa/locking-redis",
              id: "locking-redis",
              is_default: true,
              options: { redisUrl: lockingRedisUrl },
            },
          ],
        },
      },
      ...(cacheRedisUrl
        ? [
            {
              resolve: "@medusajs/medusa/caching",
              options: {
                providers: [
                  {
                    resolve: "@medusajs/caching-redis",
                    id: "caching-redis",
                    is_default: true,
                    options: { redisUrl: cacheRedisUrl },
                  },
                ],
              },
            },
          ]
        : []),
    ]
  : []

module.exports = defineConfig({
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    redisUrl,
    workerMode: process.env.MEDUSA_WORKER_MODE as
      | "shared"
      | "worker"
      | "server",
    databaseDriverOptions:
      process.env.DATABASE_SSL === "true"
        ? {
            ssl: {
              rejectUnauthorized:
                process.env.DATABASE_SSL_REJECT_UNAUTHORIZED !== "false",
            },
          }
        : { ssl: false },
    http: {
      storeCors: process.env.STORE_CORS!,
      adminCors: process.env.ADMIN_CORS!,
      authCors: process.env.AUTH_CORS!,
      jwtSecret: process.env.JWT_SECRET,
      cookieSecret: process.env.COOKIE_SECRET,
    },
    cookieOptions: {
      httpOnly: true,
      secure: isProduction,
      sameSite: "lax",
    },
  },
  modules: [
    ...redisModules,
    {
      resolve: "@medusajs/medusa/file",
      options: { providers: [fileProvider] },
    },
  ],
  admin: {
    backendUrl: process.env.MEDUSA_BACKEND_URL,
    storefrontUrl: process.env.MEDUSA_STOREFRONT_URL,
    disable: process.env.DISABLE_MEDUSA_ADMIN === "true",
    vite: (config) => {
      const serverConfig = {
        host: "0.0.0.0",
        allowedHosts: ["localhost", ".localhost", "127.0.0.1"],
        hmr: {
          ...(typeof config.server?.hmr === "object"
            ? config.server.hmr
            : {}),
          port: 5173,
          clientPort: 5173,
        },
      }

      if (process.env.NODE_ENV === "development") {
        return { server: serverConfig }
      }

      return {
        ...config,
        server: {
          ...config.server,
          ...serverConfig,
        },
      }
    },
  },
})
