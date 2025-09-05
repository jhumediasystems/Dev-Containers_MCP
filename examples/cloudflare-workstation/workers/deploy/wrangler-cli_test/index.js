export default {
  async fetch(request, env, ctx) {
    const { GREETING, KV, BUCKET, DB } = env;
    // KV demo
    await KV.put("hello", GREETING || "Hi");
    const kvValue = await KV.get("hello");

    // D1 demo (safe to no-op if not configured)
    let d1Row = "(no d1)";
    try {
      await DB.exec("CREATE TABLE IF NOT EXISTS t (id INTEGER PRIMARY KEY, v TEXT);");
      await DB.exec("INSERT INTO t (v) VALUES ('ok');");
      const { results } = await DB.prepare("SELECT count(*) as c FROM t;").first();
      d1Row = `rows=${results ?? "?"}`;
    } catch (e) {
      d1Row = `(d1 not available: ${e?.message ?? e})`;
    }

    // R2 demo (no-op if not configured)
    let r2Info = "(no r2)";
    try {
      await BUCKET.put("hello.txt", new Blob([kvValue || "Hello!"]));
      const obj = await BUCKET.get("hello.txt");
      r2Info = obj ? `r2=${(await obj.text()).slice(0, 32)}` : "(missing)";
    } catch (_) {}

    return new Response(
      JSON.stringify({ ok: true, kv: kvValue, d1: d1Row, r2: r2Info }, null, 2),
      { headers: { "content-type": "application/json" } }
    );
  },
};

