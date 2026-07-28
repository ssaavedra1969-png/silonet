export default async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  const token = process.env.GITHUB_TOKEN;
  const gistId = process.env.GIST_ID;
  res.status(200).json({
    ok: true,
    hasToken: !!token,
    hasGistId: !!gistId,
    node: process.version
  });
};
