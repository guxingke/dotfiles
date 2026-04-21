#!/usr/bin/env bun
import { resolve, dirname, relative, join, basename } from "path";
import {
  readdirSync,
  existsSync,
  readFileSync,
  mkdirSync,
  copyFileSync,
  chmodSync,
  rmSync,
  statSync,
} from "fs";
import { parse } from "yaml";

const ROOT = dirname(dirname(resolve(import.meta.filename)));
const MODS_DIR = join(ROOT, "mods");
const HOME = process.env.HOME!;
const BACKUP_DIR = join(HOME, "backups", "dotfiles");

// ── types ──

interface ModConfig {
  mode: "copy" | "custom";
  target?: string;
  pre?: string;
  post?: string;
  depends?: string[];
  ignore?: string[];
}

interface Module {
  name: string;
  path: string;
  config: ModConfig;
}

// ── module discovery ──

function loadModConfig(modDir: string): ModConfig {
  const modYaml = join(modDir, "mod.yaml");
  if (existsSync(modYaml)) {
    const raw = parse(readFileSync(modYaml, "utf-8")) as Partial<ModConfig>;
    return {
      mode: raw.mode ?? "copy",
      target: raw.target,
      pre: raw.pre,
      post: raw.post,
      depends: raw.depends,
      ignore: raw.ignore,
    };
  }
  return { mode: "copy" };
}

function discoverModules(): Module[] {
  const entries = readdirSync(MODS_DIR, { withFileTypes: true });
  const modules: Module[] = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith(".")) continue;

    const modDir = join(MODS_DIR, entry.name);
    modules.push({
      name: entry.name,
      path: modDir,
      config: loadModConfig(modDir),
    });
  }

  return modules.sort((a, b) => a.name.localeCompare(b.name));
}

function targetRoot(mod: Module): string {
  return mod.config.target?.replace(/^~/, HOME) ?? HOME;
}

// ── dependency resolution ──

function topoSort(modules: Module[]): Module[] {
  const byName = new Map(modules.map((m) => [m.name, m]));
  const visited = new Set<string>();
  const sorted: Module[] = [];

  function visit(name: string, stack: Set<string>) {
    if (visited.has(name)) return;
    if (stack.has(name)) {
      console.error(`circular dependency: ${[...stack, name].join(" → ")}`);
      process.exit(1);
    }
    const mod = byName.get(name);
    if (!mod) return;

    stack.add(name);
    for (const dep of mod.config.depends ?? []) {
      if (!byName.has(dep)) {
        console.error(`${name}: unknown dependency "${dep}"`);
        process.exit(1);
      }
      visit(dep, stack);
    }
    stack.delete(name);

    visited.add(name);
    sorted.push(mod);
  }

  for (const mod of modules) {
    visit(mod.name, new Set());
  }

  return sorted;
}

// ── file walking ──

function walkFiles(dir: string, ignore?: string[]): string[] {
  const files: string[] = [];

  function walk(current: string) {
    for (const entry of readdirSync(current, { withFileTypes: true })) {
      if (entry.name === "mod.yaml") continue;
      if (entry.name === "deploy.sh") continue;
      if (ignore?.some((p) => entry.name.match(new RegExp(p)))) continue;

      const full = join(current, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else {
        files.push(full);
      }
    }
  }

  walk(dir);
  return files;
}

// ── local files ──

const LOCAL_PATTERNS = [".local", ".custom"];

function isLocalFile(name: string): boolean {
  return LOCAL_PATTERNS.some((p) => name.endsWith(p) || name.includes(`${p}.`));
}

function collectLocalFiles(): string[] {
  const locals: string[] = [];

  function walk(dir: string) {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const full = join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (isLocalFile(entry.name)) {
        locals.push(full);
      }
    }
  }

  walk(MODS_DIR);
  return locals;
}

// ── copy with permissions ──

function copyFile(src: string, dst: string) {
  copyFileSync(src, dst);
  const { mode } = statSync(src);
  chmodSync(dst, mode);
}

// ── file comparison ──

function filesEqual(a: string, b: string): boolean {
  if (!existsSync(b)) return false;
  const bufA = readFileSync(a);
  const bufB = readFileSync(b);
  return bufA.equals(bufB);
}

// ── hooks ──

async function runHook(label: string, cmd: string): Promise<boolean> {
  console.log(`  [${label}] ${cmd}`);
  const proc = Bun.spawn(["bash", "-c", cmd], {
    stdout: "inherit",
    stderr: "inherit",
  });
  const code = await proc.exited;
  if (code !== 0) {
    console.log(`  [FAIL] ${label} exited with ${code}`);
    return false;
  }
  return true;
}

// ── deploy backup ──

async function backupOverwritten(root: string, files: { src: string; dst: string; rel: string }[]) {
  const toBackup = files.filter((f) => existsSync(f.dst) && !filesEqual(f.src, f.dst));
  if (toBackup.length === 0) return;

  mkdirSync(BACKUP_DIR, { recursive: true });
  const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  const tarFile = join(BACKUP_DIR, `pre-deploy-${ts}.tar.gz`);

  const relPaths = toBackup.map((f) => f.rel);
  const proc = Bun.spawn(["tar", "czf", tarFile, ...relPaths], {
    cwd: root,
    stdout: "ignore",
    stderr: "inherit",
  });
  if ((await proc.exited) === 0) {
    console.log(`  [BACKUP] ${toBackup.length} file(s) → ${basename(tarFile)}`);
  }
}

// ── commands ──

async function cmdStatus() {
  const modules = discoverModules();

  console.log("Module".padEnd(20) + "Mode".padEnd(10) + "Status");
  console.log("─".repeat(50));

  for (const mod of modules) {
    if (mod.config.mode === "custom") {
      const hasScript = existsSync(join(mod.path, "deploy.sh"));
      const status = hasScript ? "ready" : "missing deploy.sh";
      console.log(mod.name.padEnd(20) + "custom".padEnd(10) + status);
      continue;
    }

    const files = walkFiles(mod.path, mod.config.ignore);
    let synced = 0;
    let differs = 0;
    let missing = 0;

    for (const src of files) {
      const rel = relative(mod.path, src);
      const dst = join(targetRoot(mod), rel);
      if (!existsSync(dst)) missing++;
      else if (filesEqual(src, dst)) synced++;
      else differs++;
    }

    let status: string;
    if (files.length === 0) status = "empty";
    else if (differs === 0 && missing === 0) status = "ok";
    else {
      const parts: string[] = [];
      if (differs > 0) parts.push(`${differs} changed`);
      if (missing > 0) parts.push(`${missing} new`);
      status = parts.join(", ");
    }

    console.log(mod.name.padEnd(20) + "copy".padEnd(10) + status);
  }
}

async function cmdDiff(name?: string) {
  const modules = discoverModules();
  const targets = name ? modules.filter((m) => m.name === name) : modules;

  if (name && targets.length === 0) {
    console.error(`unknown module: ${name}`);
    process.exit(1);
  }

  for (const mod of targets) {
    if (mod.config.mode === "custom") {
      console.log(`[${mod.name}] custom mode, skipping diff`);
      continue;
    }

    const files = walkFiles(mod.path, mod.config.ignore);
    let hasDiff = false;

    for (const src of files) {
      const rel = relative(mod.path, src);
      const dst = join(targetRoot(mod), rel);

      if (!existsSync(dst)) {
        if (!hasDiff) { console.log(`\n── ${mod.name} ──`); hasDiff = true; }
        console.log(`  [NEW] ${rel} → ~/${rel}`);
      } else if (!filesEqual(src, dst)) {
        if (!hasDiff) { console.log(`\n── ${mod.name} ──`); hasDiff = true; }
        console.log(`  [DIFF] ~/${rel}`);
        const proc = Bun.spawn(["diff", "--unified=3", dst, src], { stdout: "pipe" });
        const output = await new Response(proc.stdout).text();
        console.log(output);
      }
    }

    if (!hasDiff && name) {
      console.log(`[${mod.name}] up to date`);
    }
  }
}

async function cmdDeploy(name?: string) {
  const modules = discoverModules();
  const filtered = name ? modules.filter((m) => m.name === name) : modules;

  if (name && filtered.length === 0) {
    console.error(`unknown module: ${name}`);
    process.exit(1);
  }

  const targets = topoSort(filtered);

  for (const mod of targets) {
    console.log(`\n── ${mod.name} ──`);

    // pre hook
    if (mod.config.pre) {
      if (!(await runHook("PRE", mod.config.pre))) continue;
    }

    // custom mode
    if (mod.config.mode === "custom") {
      const script = join(mod.path, "deploy.sh");
      if (!existsSync(script)) {
        console.log("  [FAIL] deploy.sh not found");
        continue;
      }
      const proc = Bun.spawn(["bash", script], {
        cwd: mod.path,
        stdout: "inherit",
        stderr: "inherit",
      });
      const code = await proc.exited;
      if (code !== 0) {
        console.log(`  [FAIL] deploy.sh exited with ${code}`);
        continue;
      }
      console.log("  [OK] custom deploy done");
      continue;
    }

    // copy mode
    const files = walkFiles(mod.path, mod.config.ignore);
    const pending = files.map((src) => {
      const rel = relative(mod.path, src);
      return { src, dst: join(targetRoot(mod), rel), rel };
    });

    // backup files that will be overwritten
    await backupOverwritten(targetRoot(mod), pending);

    let copied = 0;
    for (const { src, dst, rel } of pending) {
      if (filesEqual(src, dst)) continue;

      mkdirSync(dirname(dst), { recursive: true });
      copyFile(src, dst);
      console.log(`  [COPY] ~/${rel}`);
      copied++;
    }

    if (copied === 0) {
      console.log("  [SKIP] already up to date");
    } else {
      console.log(`  [OK] ${copied} file(s) deployed`);
    }

    // post hook
    if (copied > 0 && mod.config.post) {
      await runHook("POST", mod.config.post);
    }
  }
}

async function cmdPull(name?: string) {
  const modules = discoverModules();
  const targets = name ? modules.filter((m) => m.name === name) : modules;

  if (name && targets.length === 0) {
    console.error(`unknown module: ${name}`);
    process.exit(1);
  }

  for (const mod of targets) {
    if (mod.config.mode === "custom") {
      console.log(`[${mod.name}] custom mode, skipping pull`);
      continue;
    }

    const files = walkFiles(mod.path, mod.config.ignore);
    let pulled = 0;

    for (const src of files) {
      const rel = relative(mod.path, src);
      const dst = join(targetRoot(mod), rel);

      if (!existsSync(dst)) continue;
      if (filesEqual(dst, src)) continue;

      copyFile(dst, src);
      console.log(`  [PULL] ~/${rel} → mods/${mod.name}/${rel}`);
      pulled++;
    }

    if (pulled === 0) {
      if (name) console.log(`[${mod.name}] up to date`);
    } else {
      console.log(`  [OK] ${pulled} file(s) pulled into ${mod.name}`);
    }
  }
}

async function cmdImport(name: string, paths: string[], target?: string) {
  if (!name || paths.length === 0) {
    console.error("usage: dotfiles import <module> <file> [file...] [--target <path>]");
    console.error("  e.g. dotfiles import git ~/.gitconfig");
    console.error("       dotfiles import wireguard /opt/homebrew/etc/wg0.conf --target /opt/homebrew/etc");
    process.exit(1);
  }

  const modDir = join(MODS_DIR, name);
  const isNew = !existsSync(modDir);

  // resolve target root: --target flag > mod.yaml > $HOME
  let root: string;
  if (target) {
    root = target.replace(/^~/, HOME);
  } else {
    const modConfig = loadModConfig(modDir);
    root = modConfig.target?.replace(/^~/, HOME) ?? HOME;
  }

  // auto-detect: if all paths are outside $HOME and no target specified, error with hint
  if (!target && !loadModConfig(modDir).target) {
    const outsidePaths = paths
      .map((p) => p.startsWith("/") ? p : resolve(p))
      .filter((p) => !p.startsWith(HOME));
    if (outsidePaths.length > 0) {
      console.error(`files are not under $HOME, use --target to specify root:`);
      console.error(`  dotfiles import ${name} ${paths.join(" ")} --target <root>`);
      process.exit(1);
    }
  }

  for (const p of paths) {
    const absPath = p.startsWith("/") ? p : resolve(p);
    if (!existsSync(absPath)) {
      console.error(`not found: ${absPath}`);
      process.exit(1);
    }

    if (!absPath.startsWith(root)) {
      console.error(`${absPath} is not under ${root}, cannot import`);
      process.exit(1);
    }

    const rel = relative(root, absPath);
    const dst = join(modDir, rel);

    mkdirSync(dirname(dst), { recursive: true });
    copyFile(absPath, dst);
    console.log(`  [IMPORT] ${absPath} → mods/${name}/${rel}`);
  }

  // write mod.yaml with target if non-$HOME
  if (target && isNew) {
    const { stringify } = await import("yaml");
    const modYaml = join(modDir, "mod.yaml");
    if (!existsSync(modYaml)) {
      const content = stringify({ target: target.replace(/^~/, HOME) === HOME ? undefined : target });
      if (content.trim() !== "{}") {
        Bun.write(modYaml, content);
        console.log(`  [WRITE] mod.yaml (target: ${target})`);
      }
    }
  }

  console.log(`  [OK] ${isNew ? "created" : "updated"} module "${name}"`);
}

async function cmdUninstall(name: string) {
  if (!name) {
    console.error("usage: dotfiles uninstall <module>");
    process.exit(1);
  }

  const modules = discoverModules();
  const mod = modules.find((m) => m.name === name);
  if (!mod) {
    console.error(`unknown module: ${name}`);
    process.exit(1);
  }

  if (mod.config.mode === "custom") {
    console.error(`[${name}] custom mode, cannot auto-uninstall`);
    process.exit(1);
  }

  const files = walkFiles(mod.path, mod.config.ignore);
  const toRemove = files
    .map((src) => {
      const rel = relative(mod.path, src);
      return { rel, dst: join(targetRoot(mod), rel) };
    })
    .filter(({ dst }) => existsSync(dst));

  if (toRemove.length === 0) {
    console.log(`[${name}] nothing to remove`);
    return;
  }

  // backup before removing
  mkdirSync(BACKUP_DIR, { recursive: true });
  const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  const tarFile = join(BACKUP_DIR, `uninstall-${name}-${ts}.tar.gz`);

  const root = targetRoot(mod);
  const relPaths = toRemove.map((f) => f.rel);
  const proc = Bun.spawn(["tar", "czf", tarFile, ...relPaths], {
    cwd: root,
    stdout: "ignore",
    stderr: "inherit",
  });
  await proc.exited;
  console.log(`  [BACKUP] → ${basename(tarFile)}`);

  for (const { rel, dst } of toRemove) {
    rmSync(dst);
    console.log(`  [RM] ~/${rel}`);
  }

  console.log(`  [OK] ${toRemove.length} file(s) removed`);
}

async function cmdBackup() {
  const locals = collectLocalFiles();
  if (locals.length === 0) {
    console.log("no local files to backup");
    return;
  }

  mkdirSync(BACKUP_DIR, { recursive: true });

  const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  const tarFile = join(BACKUP_DIR, `local-${ts}.tar.gz`);

  const relPaths = locals.map((f) => relative(MODS_DIR, f));

  const proc = Bun.spawn(["tar", "czf", tarFile, ...relPaths], {
    cwd: MODS_DIR,
    stdout: "inherit",
    stderr: "inherit",
  });
  const code = await proc.exited;
  if (code !== 0) {
    console.error("[FAIL] tar exited with", code);
    process.exit(1);
  }

  console.log(`[OK] ${locals.length} local file(s) backed up`);
  console.log(`     ${tarFile}`);

  for (const rel of relPaths) {
    console.log(`     ${rel}`);
  }
}

async function cmdRestore(file?: string) {
  if (!file) {
    if (!existsSync(BACKUP_DIR)) {
      console.log("no backups found");
      return;
    }
    const files = readdirSync(BACKUP_DIR)
      .filter((f) => f.endsWith(".tar.gz"))
      .sort()
      .reverse();
    if (files.length === 0) {
      console.log("no backups found");
      return;
    }
    console.log("available backups:");
    for (const f of files) {
      const stat = statSync(join(BACKUP_DIR, f));
      const size = stat.size < 1024 ? `${stat.size}B` : `${(stat.size / 1024).toFixed(1)}K`;
      console.log(`  ${f}  (${size})`);
    }
    console.log(`\nusage: dotfiles restore <filename>`);
    return;
  }

  const tarFile = file.includes("/") ? file : join(BACKUP_DIR, file);
  if (!existsSync(tarFile)) {
    console.error(`not found: ${tarFile}`);
    process.exit(1);
  }

  // detect restore target based on filename prefix
  const name = basename(tarFile);
  const cwd = name.startsWith("local-") ? MODS_DIR : HOME;

  const proc = Bun.spawn(["tar", "xzf", tarFile], {
    cwd,
    stdout: "inherit",
    stderr: "inherit",
  });
  const code = await proc.exited;
  if (code !== 0) {
    console.error("[FAIL] tar exited with", code);
    process.exit(1);
  }

  console.log(`[OK] restored from ${name} → ${cwd === HOME ? "~/" : "mods/"}`);
}

// ── main ──

const args = process.argv.slice(2);
const cmd = args[0];
const arg = args[1];

const USAGE = `usage: dotfiles <command> [args]

commands:
  status              show status of all modules
  diff [name]         show diff for one or all modules
  deploy [name]       deploy one or all modules (auto-backups overwritten files)
  pull [name]         pull changes from $HOME back into mods
  import <mod> <file> [--target <path>]  import file(s) into a module
  uninstall <name>    remove deployed files (with backup)
  backup              backup all local files to ~/backups/dotfiles/
  restore [file]      list backups or restore from a backup`;

switch (cmd) {
  case "status":
    await cmdStatus();
    break;
  case "diff":
    await cmdDiff(arg);
    break;
  case "deploy":
    await cmdDeploy(arg);
    break;
  case "pull":
    await cmdPull(arg);
    break;
  case "import": {
    const importArgs = args.slice(1);
    const targetIdx = importArgs.indexOf("--target");
    let importTarget: string | undefined;
    let importFiles: string[];
    if (targetIdx !== -1) {
      importTarget = importArgs[targetIdx + 1];
      importFiles = [...importArgs.slice(1, targetIdx), ...importArgs.slice(targetIdx + 2)];
    } else {
      importFiles = importArgs.slice(1);
    }
    await cmdImport(importArgs[0]!, importFiles, importTarget);
    break;
  }
  case "uninstall":
    if (!arg) { console.error("usage: dotfiles uninstall <module>"); process.exit(1); }
    await cmdUninstall(arg);
    break;
  case "backup":
    await cmdBackup();
    break;
  case "restore":
    await cmdRestore(arg);
    break;
  case "_modules":
    discoverModules().forEach((m) => console.log(m.name));
    break;
  case "_completion":
    if (arg === "zsh") {
      const cli = `bun run ${resolve(ROOT, "src/cli.ts")}`;
      console.log(
`_dotfiles() {
  local -a commands
  commands=(
    'status:show status of all modules'
    'diff:show diff for one or all modules'
    'deploy:deploy one or all modules'
    'pull:pull changes from HOME back into mods'
    'import:import existing files into a module'
    'uninstall:remove deployed files'
    'backup:backup all local files'
    'restore:list or restore from backups'
  )

  if (( CURRENT == 2 )); then
    _describe -t commands 'dotfiles command' commands
    return
  fi

  case \${words[2]} in
    diff|deploy|pull|uninstall)
      local -a mods
      mods=(\${(f)"$(${cli} _modules 2>/dev/null)"})
      [[ -n "\${mods[*]}" ]] && _describe -t modules 'module' mods
      ;;
    restore)
      local -a backups
      backups=(\${(f)"$(ls ~/backups/dotfiles/*.tar.gz 2>/dev/null | xargs -n1 basename)"})
      [[ -n "\${backups[*]}" ]] && _describe -t backups 'backup' backups
      ;;
    import)
      if (( CURRENT == 3 )); then
        local -a mods
        mods=(\${(f)"$(${cli} _modules 2>/dev/null)"})
        [[ -n "\${mods[*]}" ]] && _describe -t modules 'module' mods
      else
        _files
      fi
      ;;
  esac
}
compdef _dotfiles dotfiles`);
    } else {
      console.error("supported: zsh");
    }
    break;
  default:
    console.log(USAGE);
    break;
}
