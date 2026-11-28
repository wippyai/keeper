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
    res.end(`<script>
      const token = JSON.parse(localStorage.getItem('@wippy_token_info') || '{}').token;
      document.title = (token || 'anonymous') + '/' + (sessionStorage.seen || 'fresh');
      sessionStorage.seen = 'seen';
    </script>`);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = 'http://127.0.0.1:' + server.address().port;
  const lua = fs.readFileSync(path.join(__dirname, '../../keeper/src/keeper/components/ui/supervisor.lua'), 'utf8');
  const script = lua.split('local RUNNER_JS = [[\n')[1].split('\n]]')[0];
  const runner = spawn(process.execPath, ['-e', script], { cwd: __dirname, stdio: ['pipe', 'pipe', 'inherit'] });
  const lines = readline.createInterface({ input: runner.stdout })[Symbol.asyncIterator]();
  let id = 0;
  async function command(op, token) {
    const state = token && { cookies: [], origins: [{ origin, localStorage: [
      { name: '@wippy_token_info', value: JSON.stringify({ token }) },
    ] }] };
    runner.stdin.write(JSON.stringify({ id: ++id, op, origin, url: origin, start_url: origin,
      storage_state: state, wait_until: 'load' }) + '\n');
    for (;;) {
      const line = await lines.next();
      assert.ok(!line.done, 'runner exited before replying');
      const result = JSON.parse(line.value);
      if (result.id === id) { assert.ok(result.ok, result.error); return result.title; }
    }
  }
  try {
    assert.equal(await command('goto'), 'anonymous/fresh');
    assert.equal(await command('open', 'first'), 'first/fresh');
    assert.equal(await command('goto', 'first'), 'first/seen');
    assert.equal(await command('goto', 'second'), 'second/fresh');
    assert.equal(await command('goto'), 'second/seen');
  } finally {
    runner.stdin.end();
    server.close();
  }
}
main().catch(err => { console.error(err); process.exitCode = 1; });
