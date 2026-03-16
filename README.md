# Unravel Board — Creative Ops Tool
**Internal project management for Unravel Digital / Time2Bet88 creatives**

---

## Stack
- **Frontend**: Vanilla HTML/CSS/JS (zero build step, instant deploy)
- **Database**: Supabase (PostgreSQL + Auth + Realtime)
- **Hosting**: Vercel (static)
- **Upgrade path**: Swap localStorage for Supabase JS client (see below)

---

## Deploy to Vercel (5 minutes)

### 1. Push to GitHub
```bash
git init
git add .
git commit -m "init: Unravel Board"
gh repo create unravel-board --private --push
```

### 2. Import to Vercel
- Go to https://vercel.com/new
- Import your repo
- No build command needed — output directory is `.` (root)
- Click Deploy ✅

### 3. Set up Supabase
1. Create project at https://app.supabase.com
2. Go to SQL Editor → paste contents of `supabase-schema.sql` → Run
3. Copy your `SUPABASE_URL` and `SUPABASE_ANON_KEY` from Settings → API

### 4. Connect Supabase to the app
Add this just before `</head>` in `index.html`:
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script>
  const supabase = window.supabase.createClient(
    'YOUR_SUPABASE_URL',
    'YOUR_SUPABASE_ANON_KEY'
  );
  // Replace localStorage save/load with supabase.from('cards').upsert(...)
</script>
```

---

## Vercel Environment Variables
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```
Set in: Vercel Dashboard → Project → Settings → Environment Variables

---

## Database Size Estimate (10–15 users, 12 months)

| Table           | Rows/year est. | Size/row | Annual size |
|-----------------|---------------|----------|-------------|
| cards           | ~2,000        | ~800 B   | ~1.6 MB     |
| columns         | ~50           | ~200 B   | ~10 KB      |
| projects        | ~10           | ~300 B   | ~3 KB       |
| activity        | ~10,000       | ~500 B   | ~5 MB       |
| project_members | ~50           | ~200 B   | ~10 KB      |
| **TOTAL**       |               |          | **~7 MB/yr**|

**Supabase Free Tier gives you 500 MB** — you'd run this tool for **70+ years** 
before hitting the database limit with 15 users.

**Supabase Free bandwidth**: 5 GB/month — easily covers 15 active users.
**Supabase Pro ($25/mo)**: 8 GB DB + 250 GB bandwidth — total overkill for this scale.

**Recommendation**: Stay on Free tier. Upgrade to Pro only if you add file 
attachments (use Supabase Storage) or need daily backups.

---

## Feature Roadmap
- [ ] Supabase Auth (magic link / Google OAuth)
- [ ] Realtime sync (all teammates see card moves live)
- [ ] File attachments (Supabase Storage)
- [ ] @mentions in card descriptions
- [ ] Deadline notifications (Supabase Edge Functions → Telegram)
- [ ] List view / Calendar view
- [ ] CSV export for campaign reporting
