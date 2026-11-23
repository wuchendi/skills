#!/usr/bin/env node
// Write appshell registry files into a host app without touching its components/ui.
//
//   node sync-shell.mjs [--ref latest|next|vX.Y.Z] [--dir <app root>] [--dry-run] [item ...]
//
// Items default to the ones already installed (folders under <dir>/src/shell). `shadcn add`
// cannot do this: it asks per file, so "no" skips the shell files too and "yes" overwrites
// the host's own components.

import { existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

const BASE = "https://wuchendi.github.io/appshell";
const args = process.argv.slice(2);
let ref = "latest";
let dir = ".";
let dryRun = false;
const items = [];
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === "--ref") ref = args[++i];
  else if (a === "--dir") dir = args[++i];
  else if (a === "--dry-run") dryRun = true;
  else items.push(a.replace(/^@cdlab\//, ""));
}

const shellDir = join(dir, "src", "shell");
if (items.length === 0) {
  if (!existsSync(shellDir)) {
    console.error(`No ${shellDir}; name the items to install, e.g. shell-layout shell-collection.`);
    process.exit(1);
  }
  for (const d of readdirSync(shellDir, { withFileTypes: true }))
    if (d.isDirectory()) items.push(`shell-${d.name}`);
}

const root = ref === "latest" ? `${BASE}/r` : ref === "next" ? `${BASE}/next/r` : `${BASE}/${ref}/r`;
const seen = new Set();
const queue = [...items];
const shadcnDeps = new Set();
const npmDeps = new Set();

while (queue.length > 0) {
  const name = queue.shift();
  if (seen.has(name)) continue;
  seen.add(name);
  const res = await fetch(`${root}/${name}.json`);
  if (!res.ok) {
    console.error(`${root}/${name}.json: HTTP ${res.status}`);
    process.exit(1);
  }
  const item = await res.json();
  for (const dep of item.registryDependencies ?? []) {
    if (dep.startsWith("@cdlab/")) queue.push(dep.slice("@cdlab/".length));
    else shadcnDeps.add(dep);
  }
  for (const dep of item.dependencies ?? []) npmDeps.add(dep);
  for (const file of item.files ?? []) {
    const target = join(dir, (file.target ?? file.path).replace(/^~\//, ""));
    console.log(`${dryRun ? "would write" : "write"} ${target}`);
    if (!dryRun) {
      mkdirSync(dirname(target), { recursive: true });
      writeFileSync(target, file.content);
    }
  }
}

console.log(`\nitems (${ref}): ${[...seen].join(" ")}`);
console.log(`shadcn components they import: ${[...shadcnDeps].join(" ")}`);
console.log(`npm packages they import: ${[...npmDeps].join(" ")}`);
