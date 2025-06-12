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
