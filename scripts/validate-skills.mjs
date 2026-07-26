#!/usr/bin/env node
// 校验 skills/ 下每个 SKILL.md:frontmatter 必含 name(==目录名)+description,
// 且正文中引用的 references/*.md 文件真实存在。纯静态校验,无外部依赖。
import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SKILLS = join(ROOT, 'skills');

let errors = 0;
let count = 0;
const names = new Map();

function fail(skill, msg) { console.error(`  ✗ [${skill}] ${msg}`); errors++; }

function parseFrontmatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!m) return null;
  const fm = {};
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-zA-Z][\w-]*):\s*(.*)$/);
    if (kv) fm[kv[1]] = kv[2].replace(/^["']|["']$/g, '').trim();
  }
  return fm;
}

/**
 * 校验 scripts/ 目录下所有脚本：只读 + 幂等 + 语法通过。
 * - .sh: 不含 rm/dd/mkfs/mount/umount/sudo apt install 等修改命令（只读）
 *         不含 $$/$RANDOM 随机性（幂等）；bash -n 语法通过
 * - .py: python3 -m py_compile 语法通过
 */
const DESTRUCTIVE_PATTERNS = [
  { re: /\brm\s+-[rRfF]/, label: 'rm -r/-f' },
  { re: /\brm\s+\//, label: 'rm /' },
  { re: /\bdd\s+if=/, label: 'dd' },
  { re: /\bmkfs\b/, label: 'mkfs' },
  { re: /\bmount\s+(-[to]|\/dev)/, label: 'mount' },
  { re: /\bumount\b/, label: 'umount' },
  { re: /\bsudo\s+apt\s+(install|purge|remove|autoremove|upgrade|dist-upgrade|full-upgrade)\b/, label: 'sudo apt install/remove/upgrade' },
  { re: /\binsmod\b/, label: 'insmod' },
  { re: /\bmodprobe\b/, label: 'modprobe' },
  { re: /\breboot\b/, label: 'reboot' },
  { re: /\bshutdown\b/, label: 'shutdown' },
  { re: /\bfdisk\b/, label: 'fdisk' },
  { re: /\bparted\b/, label: 'parted' },
  { re: /\bblkdiscard\b/, label: 'blkdiscard' },
];

function validateScripts(skillDir, skillName) {
  const scriptsDir = join(skillDir, 'scripts');
  if (!existsSync(scriptsDir) || !statSync(scriptsDir).isDirectory()) return;

  for (const f of readdirSync(scriptsDir)) {
    const fp = join(scriptsDir, f);
    if (!statSync(fp).isFile()) continue;
    const content = readFileSync(fp, 'utf8');

    if (f.endsWith('.sh')) {
      // 1. Strip comment lines, then check for destructive commands (read-only)
      const code = content.split('\n').filter(l => !l.trim().startsWith('#')).join('\n');
      for (const { re, label } of DESTRUCTIVE_PATTERNS) {
        if (re.test(code)) fail(skillName, `scripts/${f} 含修改命令: ${label}（违反只读原则）`);
      }
      // 2. Check for non-deterministic randomness (idempotent)
      if (/\$\$/.test(code)) fail(skillName, `scripts/${f} 含 $$ 随机性（违反幂等原则）`);
      if (/\$RANDOM/.test(code)) fail(skillName, `scripts/${f} 含 $RANDOM 随机性（违反幂等原则）`);
      // 3. bash -n syntax check
      try { execFileSync('bash', ['-n', fp], { stdio: 'pipe', timeout: 5000 }); }
      catch (e) { if (e.code !== 'ENOENT') fail(skillName, `scripts/${f} bash -n 语法检查失败`); }
    } else if (f.endsWith('.py')) {
      // python3 -m py_compile syntax check
      try { execFileSync('python3', ['-m', 'py_compile', fp], { stdio: 'pipe', timeout: 10000 }); }
      catch (e) { if (e.code !== 'ENOENT') fail(skillName, `scripts/${f} python3 -m py_compile 语法检查失败`); }
    }
  }
}

if (!existsSync(SKILLS)) { console.error('skills/ 目录不存在'); process.exit(1); }

for (const dir of readdirSync(SKILLS)) {
  const skillDir = join(SKILLS, dir);
  if (!statSync(skillDir).isDirectory()) continue;
  const skillFile = join(skillDir, 'SKILL.md');
  count++;
  if (!existsSync(skillFile)) { fail(dir, '缺少 SKILL.md'); continue; }

  const text = readFileSync(skillFile, 'utf8');
  const fm = parseFrontmatter(text);
  if (!fm) { fail(dir, 'frontmatter 缺失或格式错误(需 --- 包裹)'); continue; }

  if (!fm.name) fail(dir, 'frontmatter 缺少 name');
  else if (fm.name !== dir) fail(dir, `name "${fm.name}" 与目录名 "${dir}" 不一致`);
  if (!fm.description) fail(dir, 'frontmatter 缺少 description');
  else if (fm.description.length < 20) fail(dir, `description 过短(${fm.description.length} 字符),触发可能不准`);
  else if (fm.description.length > 1024) fail(dir, `description 过长(${fm.description.length} 字符)`);

  if (fm.name) {
    if (names.has(fm.name)) fail(dir, `name "${fm.name}" 与 ${names.get(fm.name)} 重复`);
    names.set(fm.name, dir);
  }

  // 校验正文中 references/ 链接存在
  for (const lnk of text.matchAll(/\]\((references\/[^)]+)\)/g)) {
    const target = lnk[1].split('#')[0];          // strip #anchor fragment (TOC/section links)
    const refPath = join(skillDir, target);
    if (!existsSync(refPath)) fail(dir, `引用的文件不存在: ${lnk[1]}`);
  }

  // 校验 scripts/ 只读 + 幂等 + 语法
  validateScripts(skillDir, dir);
}

console.log(`\n校验完成:${count} 个 skill,${errors} 个问题。`);
process.exit(errors ? 1 : 0);
