#!/usr/bin/env node
// 校验 skills/ 下每个 SKILL.md:frontmatter 必含 name(==目录名)+description,
// 且正文中引用的 references/*.md 文件真实存在。纯静态校验,无外部依赖。
import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

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
}

console.log(`\n校验完成:${count} 个 skill,${errors} 个问题。`);
process.exit(errors ? 1 : 0);
