import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const git = (...args) =>
  execFileSync('git', args, {
    encoding: 'utf8',
    maxBuffer: 128 * 1024 * 1024,
  });

const ignoredTextFiles = new Set([
  'backend/content/package-lock.json',
  'backend/user_app/package-lock.json',
]);
const placeholderPasswords = new Set([
  'change-me',
  'replace-me',
  'password',
  'example',
  'validation',
]);

const rules = [
  ['private key', /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/g],
  ['Google API key', /AIza[0-9A-Za-z_-]{35}/g],
  ['AWS access key', /AKIA[0-9A-Z]{16}/g],
  ['GitHub token', /gh[pousr]_[0-9A-Za-z]{20,}/g],
  ['Stripe secret key', /sk_(?:live|test)_[0-9A-Za-z]{16,}/g],
];

const findings = [];
const record = (source, label, match) => {
  findings.push(`${source}: ${label} (${String(match).slice(0, 8)}...)`);
};

const scanText = (source, text) => {
  for (const [label, pattern] of rules) {
    pattern.lastIndex = 0;
    for (const match of text.matchAll(pattern)) record(source, label, match[0]);
  }
  const databasePattern = /postgres(?:ql)?:\/\/[^:\s/@]+:([^@\s/]+)@/gi;
  for (const match of text.matchAll(databasePattern)) {
    const password = decodeURIComponent(match[1]).toLowerCase();
    if (!placeholderPasswords.has(password) && !password.includes('replace')) {
      record(source, 'database password', match[0]);
    }
  }
};

const candidateFiles = git(
  'ls-files',
  '--cached',
  '--others',
  '--exclude-standard',
  '-z',
)
  .split('\0')
  .filter(Boolean);
for (const file of candidateFiles) {
  if (
    /(^|\/)\.env(?:\.|$)/i.test(file) &&
    !file.endsWith('.env.example') &&
    !file.endsWith('/.env.example')
  ) {
    findings.push(`${file}: tracked environment file`);
  }
  if (/(^|\/).+\.(?:pem|key|p12|pfx|jks|keystore)$/i.test(file)) {
    findings.push(`${file}: tracked private key or keystore`);
  }
  if (ignoredTextFiles.has(file)) continue;
  let contents;
  try {
    contents = readFileSync(file);
  } catch {
    continue;
  }
  if (contents.includes(0)) continue;
  scanText(file, contents.toString('utf8'));
}

const historicalObjects = git('rev-list', '--objects', '--all');
for (const line of historicalObjects.split(/\r?\n/)) {
  const file = line.slice(line.indexOf(' ') + 1);
  if (!file || file === line) continue;
  if (
    /(^|\/)\.env(?:\.|$)/i.test(file) &&
    !file.endsWith('.env.example') &&
    !file.endsWith('/.env.example')
  ) {
    findings.push(`git history ${file}: environment file`);
  }
  if (/(^|\/).+\.(?:pem|key|p12|pfx|jks|keystore)$/i.test(file)) {
    findings.push(`git history ${file}: private key or keystore`);
  }
}

scanText(
  'git history patch',
  git('log', '--all', '--full-history', '-p', '--no-ext-diff', '--format='),
);

if (findings.length > 0) {
  console.error('Potential repository secrets were found:');
  for (const finding of [...new Set(findings)]) console.error(`- ${finding}`);
  process.exit(1);
}

console.log(
  'No tracked, untracked candidate, or historical secrets matched the repository rules.',
);
