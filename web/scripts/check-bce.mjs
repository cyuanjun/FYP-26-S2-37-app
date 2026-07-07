import { readFileSync, readdirSync, statSync } from "node:fs";
import path from "node:path";

const root = process.cwd();
const srcDir = path.join(root, "src");
const sourceExtensions = new Set([".ts", ".vue"]);

const violations = [];

for (const file of walk(srcDir)) {
  const relative = toPosix(path.relative(root, file));
  const content = readFileSync(file, "utf8");
  const imports = extractImports(content);

  for (const specifier of imports) {
    const resolved = normalizeSpecifier(specifier, path.dirname(file));
    if (!resolved) continue;

    checkRule(relative, resolved, specifier);
  }
}

if (violations.length > 0) {
  console.error("BCE dependency check failed:\n");
  for (const violation of violations) {
    console.error(`- ${violation}`);
  }
  process.exit(1);
}

console.log("BCE dependency check passed.");

function* walk(dir) {
  for (const entry of readdirSync(dir)) {
    const full = path.join(dir, entry);
    const stats = statSync(full);
    if (stats.isDirectory()) {
      yield* walk(full);
    } else if (sourceExtensions.has(path.extname(full))) {
      yield full;
    }
  }
}

function extractImports(content) {
  const imports = [];
  const patterns = [
    /import\s+(?:type\s+)?(?:[^'"]+?\s+from\s+)?["']([^"']+)["']/g,
    /import\(\s*["']([^"']+)["']\s*\)/g,
  ];

  for (const pattern of patterns) {
    for (const match of content.matchAll(pattern)) {
      imports.push(match[1]);
    }
  }

  return imports;
}

function normalizeSpecifier(specifier, fromDir) {
  if (specifier.startsWith("@/")) {
    return `src/${specifier.slice(2)}`;
  }

  if (specifier.startsWith(".")) {
    return toPosix(path.relative(root, path.resolve(fromDir, specifier)));
  }

  return null;
}

function checkRule(fromFile, toPath, originalSpecifier) {
  const fromLayer = layerFor(fromFile);
  const toLayer = layerFor(toPath);

  if (!fromLayer || !toLayer) return;

  if (fromLayer === "entity" && toLayer !== "entity") {
    addViolation(fromFile, originalSpecifier, "entities must not import boundary or controller code");
  }

  if (fromLayer === "boundary-ui" && toLayer === "entity") {
    addViolation(fromFile, originalSpecifier, "boundary UI must not import entities directly");
  }

  if (fromLayer === "boundary-ui" && toLayer === "boundary-gateway") {
    addViolation(fromFile, originalSpecifier, "boundary UI must call controllers, not gateways directly");
  }

  if (fromLayer === "boundary-gateway" && toLayer === "controller") {
    addViolation(fromFile, originalSpecifier, "gateways must not import controllers");
  }
}

function layerFor(filePath) {
  if (filePath.startsWith("src/boundary/ui/")) return "boundary-ui";
  if (filePath.startsWith("src/boundary/gateways/")) return "boundary-gateway";
  if (filePath.startsWith("src/controller/")) return "controller";
  if (filePath.startsWith("src/entity/")) return "entity";
  return null;
}

function addViolation(fromFile, specifier, reason) {
  violations.push(`${fromFile} imports "${specifier}": ${reason}.`);
}

function toPosix(value) {
  return value.split(path.sep).join("/");
}
