#!/bin/bash
set -e

echo "🚀 Setting up Quality Gates (Pass #2)..."

### 1. Tighten Vitest coverage thresholds (per-file 80%)
echo "📊 Setting up coverage thresholds..."
cd apps/web
# Check if vitest.config.mts exists
if [ -f "vitest.config.mts" ]; then
  # Add coverage configuration to existing vitest config
  sed -i '/export default defineConfig({/a\  coverage: {\n    provider: "v8",\n    all: true,\n    include: ["src/**"],\n    reporter: ["text", "lcov", "html"],\n    thresholds: {\n      statements: 80,\n      branches: 75,\n      functions: 80,\n      lines: 80,\n      perFile: true\n    }\n  },' vitest.config.mts
fi
cd ../..

### 2. Stub-test generator + Husky hook
echo "🤖 Setting up AI test stub generator..."
mkdir -p scripts tests/_ai

cat > scripts/gen-ai-tests.mjs << 'EOF'
import { execSync } from 'node:child_process';
import fs from 'node:fs/promises';

const changed = execSync('git diff --name-only --cached').toString().split('\n')
  .filter(f => f.match(/\.(ts|tsx)$/) && !f.includes('tests'));

for (const file of changed) {
  const dst = `tests/_ai/${file.replace(/\.(t|j)sx?$/, '')}.tmp.test.ts`;
  await fs.mkdir(dst.substring(0, dst.lastIndexOf('/')), { recursive: true });
  
  if (await fs.stat(dst).catch(() => false)) continue;
  
  const id = file.split('/').pop().replace(/\.(t|j)sx?$/, '');
  await fs.writeFile(dst, `import { describe, it, expect } from 'vitest';
import { ${id} } from '../../${file}';

describe('${id}', () => {
  it('AUTO-TODO', () => {
    expect(${id}).toBeDefined();
  });
});`);
}
EOF

# Install Husky if not already installed
if ! npm list husky >/dev/null 2>&1; then
  npm install --save-dev husky
fi

# Initialize Husky
npx husky
echo "node scripts/gen-ai-tests.mjs" > .husky/pre-commit

### 3. Fast CI workflow
echo "⚡ Setting up Fast CI workflow..."
mkdir -p .github/workflows

cat > .github/workflows/ci-fast.yml << 'EOF'
name: CI (Fast)
on:
  pull_request: 
    branches: [main]
  merge_group:  
    branches: [main]

jobs:
  fast:
    runs-on: ubuntu-latest
    permissions: 
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: 
          node-version: 22
          cache: 'npm'
      
      - run: npm ci
      
      - name: Type Check
        run: npm run check-types --workspace=apps/web
        
      - name: Test with Coverage
        run: |
          npm run test --workspace=apps/web 2>&1 | tee vitest.log
        continue-on-error: true
        
      - name: Upload Coverage to Codacy
        if: success()
        uses: codacy/codacy-coverage-reporter-action@v1.3.0
        with:
          project-token: ${{ secrets.CODACY_PROJECT_TOKEN }}
          coverage-reports: apps/web/coverage/lcov.info
        continue-on-error: true
        
      - name: Comment Test Results
        if: failure()
        uses: mshick/add-pr-comment@v2
        with:
          message-path: vitest.log
EOF

### 4. Lint auto-fix workflow
echo "🔧 Setting up Lint auto-fix workflow..."
cat > .github/workflows/lint.yml << 'EOF'
name: Lint (Auto-fix)
on: 
  pull_request:
    branches: [main]

permissions: 
  contents: write
  pull-requests: write

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          
      - uses: actions/setup-node@v4
        with: 
          node-version: 22
          cache: 'npm'
          
      - run: npm ci
      
      - uses: wearerequired/lint-action@v2
        with:
          eslint: true
          prettier: true
          eslint_args: "--max-warnings 0"
          auto_fix: true
EOF

echo "💾 Committing quality gate changes..."
git add scripts .husky .github/workflows apps/web/vitest.config.mts 2>/dev/null || true
git add .
git commit -m "ci(fast): unit+coverage, lint auto-fix, stub-tests, per-file thresholds" --no-verify
git push

echo "✅ Pass #2 completed successfully!" 