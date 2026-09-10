#16 [medusa-server base 2/3] RUN npm install --global pnpm@10.11.1
#16 3113.4 npm error code ETIMEDOUT
#16 3113.4 npm error syscall read
#16 3113.4 npm error errno ETIMEDOUT
#16 3113.4 npm error network request to https://registry.npmjs.org/pnpm failed, reason: read ETIMEDOUT
#16 3113.4 npm error network This is a problem related to network connectivity.
#16 3113.4 npm error network In most cases you are behind a proxy or have bad network settings.
#16 3113.4 npm error network
#16 3113.4 npm error network If you are behind a proxy, please make sure that the 'proxy' config is set properly. See: 'npm help config'
#16 3113.4 npm error A complete log of this run can be found in: /root/.npm/_logs/2026-09-10T08_04_20_255Z-debug-0.log
#16 ERROR: process "/bin/sh -c npm install --global pnpm@10.11.1" did not complete successfully: exit code: 1
------

> [medusa-server base 2/3] RUN npm install --global pnpm@10.11.1:
> 3113.4 npm error code ETIMEDOUT
> 3113.4 npm error syscall read
> 3113.4 npm error errno ETIMEDOUT
> 3113.4 npm error network request to https://registry.npmjs.org/pnpm failed, reason: read ETIMEDOUT
> 3113.4 npm error network This is a problem related to network connectivity.
> 3113.4 npm error network In most cases you are behind a proxy or have bad network settings.
> 3113.4 npm error network
> 3113.4 npm error network If you are behind a proxy, please make sure that the 'proxy' config is set properly. See: 'npm help config'
> 3113.4 npm error A complete log of this run can be found in: /root/.npm/_logs/2026-09-10T08_04_20_255Z-debug-0.log

---

target medusa-migrations: failed to solve: process "/bin/sh -c npm install --global pnpm@10.11.1" did not complete successfully: exit code: 1
Error: ❌ Docker command failed
Error occurred ❌, check the logs for details.
