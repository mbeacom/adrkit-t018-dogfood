#!/usr/bin/env node
// Drives the pinned @adrkit/mcp server over stdio JSON-RPC against this
// repository's real corpus and asserts observed behavior.
//
// This is the check that makes the MCP configuration evidence rather than
// aspiration: a config file that names a server proves nothing about whether an
// agent reading it gets correct answers. Everything asserted here was first
// observed by hand at this pin -- see README.md, "MCP server for agents" -- and
// is recorded so a regression fails the build instead of quietly changing what
// agents in this repository are told.
//
// Deliberate properties:
//   * No adrkit source is built. The server is launched exactly the way the
//     checked-in configs launch it (`npx -y @adrkit/mcp@<pin>`), so what is
//     under test is the published artifact an agent actually runs.
//   * Expected values are literals, not recomputed from the corpus. A check that
//     derives its expectation from the same source it validates cannot fail.
//   * Tool input validation surfaces as an `isError: true` *result*, not a
//     JSON-RPC error, so `request()` below rejects only on protocol errors and
//     invalid-input assertions inspect the result.
//   * stdout is protocol-only per the server's contract, so stderr is captured
//     separately and surfaced only on failure.
//
// Usage: assert-mcp-surface.mjs <repoRoot> <serverBin> <expectedVersion>

import { spawn } from 'node:child_process';
import { once } from 'node:events';

const [, , repoRoot, serverBin, expectedVersion] = process.argv;

if (!repoRoot || !serverBin || !expectedVersion) {
  console.error(
    'usage: assert-mcp-surface.mjs <repoRoot> <serverBin> <expectedVersion>',
  );
  process.exit(2);
}

// The four-tool surface is locked upstream by a surface test. Asserting it here
// too means a widened surface surfaces in this repository as a deliberate
// re-verification rather than as tools silently becoming callable by agents.
const EXPECTED_TOOLS = [
  'get_decision',
  'get_decision_context',
  'list_superseded',
  'search_decisions',
];

// Corpus expectations, fixed against docs/adr/0001-0015. These are the same
// values `adr check` and the CI Action resolve for this path, which is the point:
// the MCP answer an agent gets must be the answer CI will enforce.
const GOVERNED_FILE = 'src/payments/api/handler.ts';
const EXPECTED_GOVERNING = [
  ['0001', 'accepted'],
  ['0002', 'accepted'],
];
const EXPECTED_ACTIVE_PROPOSALS = [['0014', 'proposed']];
const EXPECTED_HISTORY = [];
const EXPECTED_RECORD_COUNT = 15;
const EXPECTED_EXCLUDED_COUNT = 0;

// A stable content fingerprint over the corpus. Asserted because it is the one
// value that changes when any governed record changes, which makes an accidental
// corpus edit fail loudly here rather than silently shifting every expectation
// below it.
const EXPECTED_FINGERPRINT =
  '1664c5af7cb42038eb6087ab980499339e28a9f1d1be7e5a9095ce52414bd936';

const TIMEOUT_MS = Number(process.env.ADRKIT_MCP_TIMEOUT_MS ?? 120_000);

const failures = [];
const checks = [];

function assert(id, description, expected, actual) {
  const e = JSON.stringify(expected);
  const a = JSON.stringify(actual);
  const ok = e === a;
  checks.push({ id, description, ok });
  if (!ok) failures.push({ id, description, expected: e, actual: a });
}

// Deliberately strict: a missing field must NOT normalize to []. An
// `items ?? []` fallback would make every "this bucket is empty" assertion pass
// when the server omitted the bucket entirely, which is a different -- and
// worse -- outcome than an empty one.
function summarize(items) {
  if (!Array.isArray(items)) return { missingOrNotAnArray: items === undefined ? 'undefined' : typeof items };
  return items.map((item) => [item.id, item.status]);
}

class McpClient {
  #child;
  #buffer = '';
  #pending = new Map();
  #nextId = 1;
  #closing = false;
  stderr = '';
  protocolViolations = [];

  constructor(child) {
    this.#child = child;
    // Without this, a server that crashes mid-run leaves every in-flight request
    // hanging until the timeout, turning a fast, clear failure into a multi-minute
    // stall with a misleading "timed out" message.
    const failAll = (reason) => {
      for (const [id, resolver] of this.#pending) {
        this.#pending.delete(id);
        resolver.reject(new Error(reason));
      }
    };
    child.on('error', (error) => failAll(`server process error: ${error.message}`));
    child.on('close', (code, signal) => {
      if (!this.#closing) {
        failAll(`server exited before responding (code ${code}, signal ${signal})`);
      }
    });
    child.stdout.setEncoding('utf8');
    child.stdout.on('data', (chunk) => this.#onStdout(chunk));
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', (chunk) => {
      this.stderr += chunk;
    });
  }

  // The server emits newline-delimited JSON-RPC frames on stdout and reserves
  // stdout for nothing else, so line framing is sufficient here.
  #onStdout(chunk) {
    this.#buffer += chunk;
    let index;
    while ((index = this.#buffer.indexOf('\n')) >= 0) {
      const line = this.#buffer.slice(0, index).trim();
      this.#buffer = this.#buffer.slice(index + 1);
      if (!line) continue;
      let message;
      try {
        message = JSON.parse(line);
      } catch {
        // The server's contract reserves stdout for JSON-RPC frames only.
        // Silently skipping unparseable lines would hide exactly the kind of
        // stray logging that corrupts a real client's stream, so it is fatal.
        this.protocolViolations.push(line.slice(0, 200));
        continue;
      }
      if (message.jsonrpc !== '2.0') {
        this.protocolViolations.push(`non-2.0 frame: ${line.slice(0, 200)}`);
      }
      const resolver = this.#pending.get(message.id);
      if (resolver) {
        this.#pending.delete(message.id);
        resolver.resolve(message);
      }
    }
  }

  notify(method, params) {
    this.#child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', method, params })}\n`);
  }

  request(method, params) {
    const id = this.#nextId++;
    const promise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.#pending.delete(id);
        reject(new Error(`timed out waiting for ${method} (id ${id})`));
      }, TIMEOUT_MS);
      this.#pending.set(id, {
        resolve: (message) => {
          clearTimeout(timer);
          if (message.error) {
            reject(new Error(`${method} returned JSON-RPC error: ${JSON.stringify(message.error)}`));
            return;
          }
          resolve(message.result);
        },
        reject: (error) => {
          clearTimeout(timer);
          reject(error);
        },
      });
    });
    this.#child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', id, method, params })}\n`);
    return promise;
  }

  async close() {
    this.#closing = true;
    this.#child.stdin.end();
    this.#child.kill();
    await once(this.#child, 'close').catch(() => {});
  }
}

// Structured results are `{ corpusHealth?, result }` under `structuredContent`,
// where `result` is a union discriminated on `outcome`.
//
// Strict on purpose. An earlier version fell back to the raw result when
// `structuredContent` was absent and ignored `isError`, which meant a tool that
// returned an error -- or stopped returning structured output at all -- could
// still satisfy an `outcome` assertion by accident. Both are now hard failures
// with the tool name attached, because a silently reshaped envelope is precisely
// the kind of upstream change this repository exists to notice.
function structured(toolName, result) {
  if (result?.isError === true) {
    const text = result?.content?.[0]?.text ?? '(no text)';
    throw new Error(`${toolName} returned isError: true -- ${text}`);
  }
  const content = result?.structuredContent;
  if (!content || typeof content !== 'object') {
    throw new Error(
      `${toolName} returned no structuredContent (keys: ${Object.keys(result ?? {}).join(', ') || 'none'})`,
    );
  }
  if (!content.result || typeof content.result !== 'object') {
    throw new Error(`${toolName} structuredContent has no "result" object`);
  }
  return { corpusHealth: content.corpusHealth, payload: content.result };
}

async function main() {
  console.log(`==> Launching: ${serverBin} --cwd <repo> --dir docs/adr`);

  // The binary is the one installed from the integrity-verified tarball by
  // validate-mcp.sh, not a fresh `npx` resolution. Re-resolving by name would
  // reintroduce the possibility of executing a cached or hoisted same-version
  // copy, which no version-string assertion can rule out.
  const child = spawn(
    serverBin,
    ['--cwd', repoRoot, '--dir', 'docs/adr'],
    { stdio: ['pipe', 'pipe', 'pipe'] },
  );

  child.on('error', (error) => {
    console.error(`error: failed to launch the MCP server: ${error.message}`);
    process.exit(1);
  });

  const client = new McpClient(child);
  activeClient = client;

  const init = await client.request('initialize', {
    protocolVersion: '2025-06-18',
    capabilities: {},
    clientInfo: { name: 'adrkit-t018-dogfood-validate-mcp', version: '1' },
  });
  client.notify('notifications/initialized', {});

  assert(
    'MCP-1',
    'server identifies as @adrkit/mcp',
    '@adrkit/mcp',
    init?.serverInfo?.name,
  );

  // A consistency check, not a provenance check. Provenance comes from having
  // launched the binary installed from the sha512-verified tarball; this only
  // confirms the running server agrees about which version that was.
  assert(
    'MCP-2',
    `server reports the pinned version ${expectedVersion}`,
    expectedVersion,
    init?.serverInfo?.version,
  );

  const list = await client.request('tools/list', {});
  const tools = list?.tools ?? [];

  assert(
    'MCP-3',
    'exactly the four expected tools are exposed',
    EXPECTED_TOOLS,
    tools.map((tool) => tool.name).sort(),
  );

  // Every tool must self-describe as read-only and closed-world. Copilot invokes
  // MCP tools autonomously without asking for approval, so this annotation is the
  // boundary that makes that acceptable in this repository.
  const notReadOnly = tools
    .filter((tool) => tool.annotations?.readOnlyHint !== true)
    .map((tool) => tool.name)
    .sort();
  assert('MCP-4', 'every tool is annotated readOnlyHint: true', [], notReadOnly);

  const openWorld = tools
    .filter((tool) => tool.annotations?.openWorldHint !== false)
    .map((tool) => tool.name)
    .sort();
  assert('MCP-5', 'every tool is annotated openWorldHint: false', [], openWorld);

  const context = structured(
    'get_decision_context',
    await client.request('tools/call', {
      name: 'get_decision_context',
      arguments: { files: [GOVERNED_FILE] },
    }),
  );

  assert('MCP-6', 'get_decision_context returns the matches branch', 'matches', context.payload.outcome);
  assert(
    'MCP-7',
    `${GOVERNED_FILE} is governed by 0001 and 0002`,
    EXPECTED_GOVERNING,
    summarize(context.payload.governing),
  );
  assert(
    'MCP-8',
    `${GOVERNED_FILE} has 0014 as an active proposal`,
    EXPECTED_ACTIVE_PROPOSALS,
    summarize(context.payload.activeProposals),
  );
  assert(
    'MCP-9',
    `${GOVERNED_FILE} has no historical decisions`,
    EXPECTED_HISTORY,
    summarize(context.payload.history),
  );

  assert(
    'MCP-10',
    'corpusHealth reports 15 records',
    EXPECTED_RECORD_COUNT,
    context.corpusHealth?.recordCount,
  );
  assert(
    'MCP-11',
    'corpusHealth excludes no records',
    EXPECTED_EXCLUDED_COUNT,
    context.corpusHealth?.excludedCount,
  );
  assert(
    'MCP-12',
    'corpus fingerprint is unchanged',
    EXPECTED_FINGERPRINT,
    context.corpusHealth?.fingerprint,
  );

  const search = structured(
    'search_decisions',
    await client.request('tools/call', {
      name: 'search_decisions',
      arguments: { query: 'payments' },
    }),
  );
  assert('MCP-13', 'search_decisions returns the results branch', 'results', search.payload.outcome);
  assert(
    'MCP-14',
    'search_decisions finds the payments records',
    [
      ['0001', 'accepted'],
      ['0002', 'accepted'],
      ['0014', 'proposed'],
    ],
    summarize(search.payload.items),
  );

  // An ungoverned path must resolve cleanly to empty rather than erroring, so an
  // agent can distinguish "no decision governs this" from "the lookup failed".
  const ungoverned = structured(
    'get_decision_context',
    await client.request('tools/call', {
      name: 'get_decision_context',
      arguments: { files: ['README.md'] },
    }),
  );
  assert('MCP-15', 'an ungoverned path returns the matches branch', 'matches', ungoverned.payload.outcome);
  // All three buckets, not just `governing`: an ungoverned path must come back
  // empty everywhere, and `summarize` fails rather than normalizes if a bucket
  // is missing entirely.
  assert(
    'MCP-16',
    'an ungoverned path is empty in all three buckets',
    { governing: [], activeProposals: [], history: [] },
    {
      governing: summarize(ungoverned.payload.governing),
      activeProposals: summarize(ungoverned.payload.activeProposals),
      history: summarize(ungoverned.payload.history),
    },
  );

  const superseded = structured(
    'list_superseded',
    await client.request('tools/call', { name: 'list_superseded', arguments: {} }),
  );
  assert('MCP-17', 'list_superseded returns the entries branch', 'entries', superseded.payload.outcome);
  // This corpus declares no supersession. Asserted rather than skipped so that a
  // corpus change that introduces one is forced through this check.
  assert('MCP-18', 'this corpus declares no superseded records', [], summarize(superseded.payload.items));

  const decision = structured(
    'get_decision',
    await client.request('tools/call', { name: 'get_decision', arguments: { ref: '0001' } }),
  );
  assert('MCP-19', 'get_decision resolves 0001', 'found', decision.payload.outcome);
  assert('MCP-20', 'get_decision returns the accepted status for 0001', 'accepted', decision.payload.decision?.status);

  // A ref that does not exist must be an explicit not-found outcome, not a
  // protocol error and not a fabricated record.
  const missing = structured(
    'get_decision',
    await client.request('tools/call', { name: 'get_decision', arguments: { ref: '9999' } }),
  );
  assert('MCP-21', 'an unknown ref is an explicit not-found outcome', 'not-found', missing.payload.outcome);

  // A syntactically valid path that does not exist must still resolve cleanly to
  // the matches branch, and must resolve by pattern. This is the positive half of
  // the "paths are compared against `affects` patterns, never opened" claim: if
  // the server stat'd its inputs, a nonexistent path would have to error, and it
  // does not.
  //
  // The two cases also pin nested-matcher discrimination. 0001 governs
  // `src/payments/**` and 0002 governs the narrower `src/payments/api/**`, so a
  // path inside `api/` must match both and a path outside it must match only
  // 0001. A resolver that collapsed nested matchers would pass the first case and
  // fail the second.
  const nonexistentApi = structured(
    'get_decision_context',
    await client.request('tools/call', {
      name: 'get_decision_context',
      arguments: { files: ['src/payments/api/does-not-exist.ts'] },
    }),
  );
  assert(
    'MCP-22',
    'a nonexistent path resolves by pattern rather than erroring',
    'matches',
    nonexistentApi.payload.outcome,
  );
  assert(
    'MCP-23',
    'a nonexistent path under src/payments/api is governed by 0001 and 0002',
    EXPECTED_GOVERNING,
    summarize(nonexistentApi.payload.governing),
  );

  const outsideApi = structured(
    'get_decision_context',
    await client.request('tools/call', {
      name: 'get_decision_context',
      arguments: { files: ['src/payments/does-not-exist.ts'] },
    }),
  );
  assert(
    'MCP-24',
    'a path outside src/payments/api is governed by 0001 only',
    [['0001', 'accepted']],
    summarize(outsideApi.payload.governing),
  );

  // Traversal, absolute, and Windows-separator paths are rejected. Note the shape
  // of the rejection: MCP reports tool input validation as an `isError: true`
  // result, not a JSON-RPC protocol error, so this asserts on the result rather
  // than on a thrown request.
  //
  // The negative half of the never-opened claim is the *kind* of error. Each of
  // these is refused with a schema message about repo-relative POSIX paths --
  // not ENOENT, not EACCES -- which is only possible if the argument was rejected
  // before it ever reached the filesystem. /etc/passwd exists and is readable on
  // the machines this runs on, so a server that opened its inputs would fail
  // differently here.
  const rejectionCases = [
    ['MCP-25', 'a traversal path is rejected', '../../../etc/passwd'],
    ['MCP-26', 'an absolute path is rejected', '/etc/passwd'],
    ['MCP-27', 'a Windows-separator path is rejected', 'src\\payments\\api.ts'],
  ];

  for (const [id, description, file] of rejectionCases) {
    const result = await client.request('tools/call', {
      name: 'get_decision_context',
      arguments: { files: [file] },
    });
    const text = result?.content?.[0]?.text ?? '';
    assert(id, description, { isError: true, schemaRejected: true }, {
      isError: result?.isError === true,
      schemaRejected: /repo-relative POSIX paths/.test(text),
    });
  }

  // stdout is reserved for JSON-RPC frames. Anything else on it would corrupt a
  // real client's stream, so unparseable or non-2.0 frames are a failure rather
  // than something to skip past.
  assert('MCP-28', 'stdout carried only well-formed JSON-RPC 2.0 frames', [], client.protocolViolations);

  await client.close();

  for (const check of checks) {
    console.log(`${check.ok ? 'ok  ' : 'FAIL'} ${check.id}  ${check.description}`);
  }

  if (failures.length > 0) {
    console.error('');
    console.error(`MCP surface validation failed: ${failures.length} assertion(s).`);
    for (const failure of failures) {
      console.error(`  ${failure.id}: ${failure.description}`);
      console.error(`    expected: ${failure.expected}`);
      console.error(`    actual:   ${failure.actual}`);
    }
    if (client.stderr.trim()) {
      console.error('');
      console.error('server stderr:');
      console.error(client.stderr.trim());
    }
    process.exit(1);
  }

  console.log('');
  console.log(
    `MCP surface validation: ${checks.length} assertions passed (@adrkit/mcp@${expectedVersion}, from the verified tarball).`,
  );
}

let activeClient = null;

main().catch((error) => {
  console.error(`error: ${error.message}`);
  if (activeClient?.stderr?.trim()) {
    console.error('');
    console.error('server stderr:');
    console.error(activeClient.stderr.trim());
  }
  // Closed here as well as on the success path: a thrown assertion must not
  // leave the server process behind holding the pipe open.
  activeClient?.close();
  process.exit(1);
});
