#!/bin/zsh
# Builds the phase 7 reference environment in the folder $1 (a scratchpad
# folder, outside the repository): the x64 Node.js v24.12.0, Chart.js at the
# pin and the moment adapter packages. Usage: env-setup.sh <folder>
set -e
SP=${1:?give the target folder}
mkdir -p $SP
cd $SP
# 1. x64 Node.js v24.12.0
mkdir -p dl && cd dl
[ -f node-v24.12.0-darwin-x64.tar.gz ] || curl -fsSLO https://nodejs.org/dist/v24.12.0/node-v24.12.0-darwin-x64.tar.gz
curl -fsSLO https://nodejs.org/dist/v24.12.0/SHASUMS256.txt
grep ' node-v24.12.0-darwin-x64.tar.gz$' SHASUMS256.txt | shasum -a 256 -c -
cd $SP
[ -d node-v24.12.0-darwin-x64 ] || tar xzf dl/node-v24.12.0-darwin-x64.tar.gz
/usr/bin/arch -x86_64 $SP/node-v24.12.0-darwin-x64/bin/node -p 'process.arch + " " + process.version'
# 2. Chart.js at the pin
COMMIT=7169e65147a47f3720957a6f156a33c838ab9f57
[ -d chartjs-build ] || git clone -q --filter=blob:none https://github.com/chartjs/Chart.js chartjs-build
git -C chartjs-build checkout -q $COMMIT
cd chartjs-build
export PATH=$SP/node-v24.12.0-darwin-x64/bin:$PATH
/usr/bin/arch -x86_64 $SP/node-v24.12.0-darwin-x64/bin/corepack pnpm install --frozen-lockfile
/usr/bin/arch -x86_64 $SP/node-v24.12.0-darwin-x64/bin/corepack pnpm build
shasum -a 256 dist/chart.js
cd $SP
# 3. moment adapter packages
mkdir -p moment && cd moment
[ -f package.json ] || echo '{"name":"moment-ref","private":true}' > package.json
/usr/bin/arch -x86_64 $SP/node-v24.12.0-darwin-x64/bin/npm install --no-audit --no-fund moment@2.29.4 moment-timezone@0.5.42 chartjs-adapter-moment@1.0.1
echo DONE
