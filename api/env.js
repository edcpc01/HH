export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 'no-store');
  
  const supabaseUrl = process.env.SUPABASE_URL || '';
  const supabaseKey = process.env.SUPABASE_KEY || '';
  const geminiKey = process.env.GEMINI_KEY || '';
  
  // Return as JS script that sets window.__ENV
  if (req.query.format === 'js') {
    res.setHeader('Content-Type', 'application/javascript');
    return res.send(`window.__ENV = ${JSON.stringify({ SUPABASE_URL: supabaseUrl, SUPABASE_KEY: supabaseKey, GEMINI_KEY: geminiKey })};`);
  }
  
  res.json({ SUPABASE_URL: supabaseUrl, SUPABASE_KEY: supabaseKey, GEMINI_KEY: geminiKey });
}
