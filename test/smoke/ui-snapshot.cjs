// Exercise the supervisor's embedded Playwright runner against a local host.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const readline = require('node:readline');

async function main() {
  const server = http.createServer((_, res) => {
    res.setHeader('Content-Type', 'text/html');
    res.end('<title>Runner fixture</title><button>Continue</button><button hidden>Hidden control</button>');
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = 'http://127.0.0.1:' + server.address().port;
  const lua = fs.readFileSync(path.join(__dirname, '../../keeper/src/keeper/components/ui/supervisor.lua'), 'utf8');
  const script = lua.split('local RUNNER_JS = [[\n')[1].split('\n]]')[0];
  const runner = spawn(process.execPath, ['-e', script], { cwd: __dirname, stdio: ['pipe', 'pipe', 'inherit'] });
  const lines = readline.createInterface({ input: runner.stdout })[Symbol.asyncIterator]();
  let id = 0;
  async function command(op) {
    runner.stdin.write(JSON.stringify({ id: ++id, op, url: origin, start_url: origin, wait_until: 'load' }) + '\n');
    for (;;) {
      const line = await lines.next();
      assert.ok(!line.done, 'runner exited before replying');
      const result = JSON.parse(line.value);
      if (result.id === id) {
        assert.ok(result.ok, result.error);
        return result;
      }
    }
  }
  try {
    for (const op of ['open', 'goto', 'snapshot']) {
      const state = await command(op);
      assert.equal(state.title, 'Runner fixture');
      assert.ok(state.snapshot, op + ' returned an empty accessibility snapshot');
      const tree = typeof state.snapshot === 'string' ? state.snapshot : JSON.stringify(state.snapshot);
      assert.match(tree, /button/);
      assert.match(tree, /Continue/);
      assert.doesNotMatch(tree, /Hidden control/);
    }
  } finally {
    runner.stdin.end();
    server.close();
  }
}
main().catch(err => { console.error(err); process.exitCode = 1; });
