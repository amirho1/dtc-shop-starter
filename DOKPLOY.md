# Dokploy production deployment

This deployment runs PostgreSQL, Redis, a one-shot Medusa migration task,
separate Medusa server and worker processes, and the Next.js storefront. Dokploy
provides the public reverse proxy and TLS termination; the Compose stack does
not publish host ports or run another proxy.

## Required environment variables

Set these in the Dokploy Compose application's **Environment** section. Use
URL-safe hexadecimal values for the database and Redis passwords because they
are interpolated into connection URLs.

| Variable | Example | Used at |
| --- | --- | --- |
| `POSTGRES_PASSWORD` | output of `openssl rand -hex 32` | Runtime |
| `REDIS_PASSWORD` | output of `openssl rand -hex 32` | Runtime |
| `JWT_SECRET` | output of `openssl rand -hex 32` | Runtime |
| `COOKIE_SECRET` | a different `openssl rand -hex 32` value | Runtime |
| `MEDUSA_ADMIN_EMAIL` | `admin@example.com` | First server bootstrap |
| `MEDUSA_ADMIN_PASSWORD` | a unique password from your secret manager | First server bootstrap |
| `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY` | `pk_01...` | Storefront build and runtime |
| `MEDUSA_BACKEND_URL` | `https://api.shop.web-father.ir` | Backend build and runtime |
| `MEDUSA_STOREFRONT_URL` | `https://shop.web-father.ir` | Backend build and runtime |
| `NEXT_PUBLIC_MEDUSA_BACKEND_URL` | `https://api.shop.web-father.ir` | Storefront build and runtime |
| `NEXT_PUBLIC_BASE_URL` | `https://shop.web-father.ir` | Storefront build and runtime |
| `STORE_CORS` | `https://shop.web-father.ir` | Runtime |
| `ADMIN_CORS` | `https://api.shop.web-father.ir` | Runtime |
| `AUTH_CORS` | `https://shop.web-father.ir,https://api.shop.web-father.ir` | Runtime |

Do not add trailing slashes to any URL or CORS origin. The public `NEXT_PUBLIC_*`
values are compiled into the Next.js bundle. Changing one requires a rebuild,
not only a container restart. `MEDUSA_BACKEND_URL` and
`MEDUSA_STOREFRONT_URL` are also provided while the Medusa Admin is built.

The Compose file supplies these defaults, which can be overridden in Dokploy:

| Variable | Default |
| --- | --- |
| `POSTGRES_DB` | `medusa` |
| `POSTGRES_USER` | `medusa` |
| `NEXT_PUBLIC_DEFAULT_REGION` | `dk` |
| `LOG_LEVEL` | `info` |
| `MEDUSA_DISABLE_TELEMETRY` | `true` |
| `DATABASE_SSL` | `false` for the internal PostgreSQL service |
| `DATABASE_SSL_REJECT_UNAUTHORIZED` | `true` |
| `FILE_PROVIDER` | `local` |
| `MEDUSA_ADMIN_EMAIL` | `admin@medusa-test.com` |
| `MEDUSA_ADMIN_PASSWORD` | development-only fallback in `docker-compose.yml` |

Always override both admin defaults in Dokploy. The fallback password makes a
local first boot convenient, but a value committed in Compose is not a
production secret. After bootstrap, changing these variables does not rotate an
existing administrator's credentials.

Payment variables are optional and build-time public values. Set those required
by the provider enabled in Medusa:

- `NEXT_PUBLIC_STRIPE_KEY`
- `NEXT_PUBLIC_MEDUSA_PAYMENTS_PUBLISHABLE_KEY`
- `NEXT_PUBLIC_MEDUSA_PAYMENTS_ACCOUNT_ID`

The default local file provider writes to the persistent `medusa_uploads`
volume and produces URLs under `https://api.shop.web-father.ir/static`. For
multi-node deployment or external object storage, set `FILE_PROVIDER=s3` and
configure all applicable values:

- `S3_FILE_URL`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`
- `S3_REGION`
- `S3_BUCKET`
- `S3_ENDPOINT`
- `S3_PREFIX` (optional)
- `S3_FORCE_PATH_STYLE=true` for providers such as MinIO

`S3_FILE_URL` is passed to the storefront build so Next.js permits product image
URLs from that host. The existing Medusa Cloud-specific image settings remain
available as `MEDUSA_CLOUD_S3_HOSTNAME` and `MEDUSA_CLOUD_S3_PATHNAME`.

A copy-and-fill list is available in `.env.production.example`.

## Domains and ports

Create two domains in the Dokploy Compose application's **Domains** tab:

| Public host | Compose service | Container port |
| --- | --- | --- |
| `shop.web-father.ir` | `storefront` | `8000` |
| `api.shop.web-father.ir` | `medusa-server` | `9000` |

Enable HTTPS/certificate management for both. Point both DNS records to the
Dokploy host. Do not configure ports under Dokploy's host-port/Advanced section.
The Compose `expose` entries are container-network metadata only. Dokploy adds
its own Traefik labels and network attachment to the selected services when its
Domains UI is used.

Medusa Admin is served at `https://api.shop.web-father.ir/app`, and backend
health is available at `https://api.shop.web-father.ir/health`.

## First deployment

The storefront requires a publishable API key at build time, but a fresh
database has no key yet. Bootstrap without seeding production data:

1. Set a temporary non-empty `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`, deploy the
   stack, and wait for `medusa-migrations` to complete successfully.
2. The `medusa-server` startup script creates the administrator configured by
   `MEDUSA_ADMIN_EMAIL` and `MEDUSA_ADMIN_PASSWORD`. On later boots, the
   duplicate-email result is detected and startup continues without changing
   the existing account.
3. Open Medusa Admin, create a publishable API key, and associate it with the
   storefront's sales channel.
4. Replace the temporary value in Dokploy and redeploy so the real key is
   compiled into the storefront.

The storefront build no longer requires a reachable Medusa server. If Medusa is
offline while static paths are collected, those catalog pages are rendered on
demand after deployment.

## Operational considerations

- `medusa-migrations` runs `medusa db:migrate` before server and worker startup.
  The server startup script repeats this idempotent check immediately before
  admin bootstrap. Both must succeed; the application services will not start
  after a failed migration.
- PostgreSQL, Redis (AOF), and local uploads use named volumes. Configure
  off-host backups in Dokploy; container restart policies are not backups.
- The project currently uses Medusa's local notification provider. Configure a
  production email notification provider before relying on customer emails,
  password reset, or order notifications.
- The local file provider is appropriate only for a single Dokploy node. Use an
  S3-compatible provider before horizontal scaling or moving containers between
  hosts.
- Run only one migration task per deployment. Server and worker are deliberately
  separate so HTTP traffic and background jobs do not compete in one process.
- Allocate at least 2 GB RAM to Medusa, plus capacity for PostgreSQL, Redis, the
  worker, and Next.js. Production builds can need more memory than steady-state
  runtime.
