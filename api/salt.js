export default async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, PUT, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }

  const token = process.env.GITHUB_TOKEN;
  const gistId = process.env.GIST_ID;
  if (!token || !gistId) {
    res.status(500).json({ error: 'Faltan GITHUB_TOKEN o GIST_ID' });
    return;
  }

  const headers = {
    Authorization: `token ${token}`,
    Accept: 'application/vnd.github.v3+json'
  };

  const getBody = () => new Promise((resolve, reject) => {
    let chunks = [];
    req.on('data', c => chunks.push(c));
    req.on('end', () => {
      try { resolve(JSON.parse(Buffer.concat(chunks).toString() || '{}')); }
      catch(e) { reject(e); }
    });
    req.on('error', reject);
  });

  try {
    if (req.method === 'GET') {
      const resp = await fetch(`https://api.github.com/gists/${gistId}`, { headers });
      if (!resp.ok) { res.status(500).json({ error: 'GitHub error: ' + resp.status }); return; }
      const data = await resp.json();
      const user = req.query?.user || '1';
      const filename = user + '-salt.txt';
      const raw = data.files?.[filename]?.content || '';
      res.status(200).json({ salt: raw });
    } else if (req.method === 'PUT') {
      const body = await getBody();
      const user = req.query?.user || '1';
      const filename = user + '-salt.txt';
      const resp = await fetch(`https://api.github.com/gists/${gistId}`, {
        method: 'PATCH',
        headers: { ...headers, 'Content-Type': 'application/json' },
        body: JSON.stringify({ files: { [filename]: { content: body.salt || '' } } })
      });
      if (!resp.ok) { res.status(500).json({ error: 'GitHub error: ' + resp.status }); return; }
      res.status(200).json({ ok: true });
    } else {
      res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
