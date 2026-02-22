#!/usr/bin/env bun

const SUPABASE_URL = 'https://njlvdciuadmbnnyvxymh.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbHZkY2l1YWRtYm5ueXZ4eW1oIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDczNTk1NSwiZXhwIjoyMDg2MzExOTU1fQ.UAW-bYvS7BhWUH-hs8GthQZrp8NP-TIRkdlpRRbWGSc';

async function fetchTable(table, select = '*', filters = {}) {
  let url = `${SUPABASE_URL}/rest/v1/${table}?select=${select}`;
  if (filters.order) url += `&order=${filters.order.column}.${filters.order.ascending ? 'asc' : 'desc'}`;
  if (filters.limit) url += `&limit=${filters.limit}`;
  if (filters.eq) Object.entries(filters.eq).forEach(([k, v]) => url += `&${k}=eq.${v}`);
  const res = await fetch(url, { headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${SUPABASE_KEY}` }});
  return res.json();
}

console.log('📊 OPS-LOOP V2 OPERATIONAL METRICS\n' + '='.repeat(60));

// Mission Success Rates
const missions = await fetchTable('ops_missions', 'status,created_at,template_name,current_step,total_steps,started_at,completed_at');
const total = missions.length;
const succeeded = missions.filter(m => m.status === 'succeeded').length;
const failed = missions.filter(m => m.status === 'failed').length;
const running = missions.filter(m => m.status === 'running').length;

console.log('\n🎯 MISSION SUCCESS RATES');
console.log(`Total: ${total} | Succeeded: ${succeeded} (${((succeeded/total)*100).toFixed(1)}%) | Failed: ${failed} (${((failed/total)*100).toFixed(1)}%) | Running: ${running}`);

// Step Failure Patterns
const steps = await fetchTable('ops_mission_steps', 'status,kind,executor');
const totalSteps = steps.length;
const succeededSteps = steps.filter(s => s.status === 'succeeded').length;
const failedSteps = steps.filter(s => s.status === 'failed').length;
const queuedSteps = steps.filter(s => s.status === 'queued').length;

console.log('\n❌ STEP FAILURE PATTERNS');
console.log(`Total: ${totalSteps} | Succeeded: ${succeededSteps} (${((succeededSteps/totalSteps)*100).toFixed(1)}%) | Failed: ${failedSteps} (${((failedSteps/totalSteps)*100).toFixed(1)}%) | Queued: ${queuedSteps}`);

// Failures by executor
const failedByExec = {};
steps.filter(s => s.status === 'failed').forEach(s => {
  const key = `${s.kind} (${s.executor || 'none'})`;
  failedByExec[key] = (failedByExec[key] || 0) + 1;
});
console.log('\nFailures by type:');
Object.entries(failedByExec).sort((a,b) => b[1] - a[1]).slice(0,5).forEach(([k,v]) => console.log(`  ${k}: ${v}`));

// Executor performance
console.log('\n👥 EXECUTOR WORKLOAD DISTRIBUTION');
const executors = {};
steps.filter(s => s.executor).forEach(s => {
  if (!executors[s.executor]) executors[s.executor] = { succeeded: 0, failed: 0, running: 0 };
  executors[s.executor][s.status]++;
});
Object.entries(executors).sort((a,b) => (b[1].succeeded+b[1].failed) - (a[1].succeeded+a[1].failed)).slice(0,6).forEach(([exec, stats]) => {
  const total = stats.succeeded + stats.failed + stats.running;
  console.log(`  ${exec}: ${stats.succeeded}/${total} (${((stats.succeeded/total)*100).toFixed(1)}%)`);
});

// Running missions age
console.log('\n⏳ RUNNING MISSIONS');
const runningMissions = await fetchTable('ops_missions', '*', { eq: { status: 'running' } });
const now = Date.now();
const ageBuckets = { '0-1h': 0, '1-4h': 0, '4-12h': 0, '12-24h': 0, '24h+': 0 };
runningMissions.forEach(m => {
  const mins = (now - new Date(m.started_at)) / 60000;
  if (mins < 60) ageBuckets['0-1h']++;
  else if (mins < 240) ageBuckets['1-4h']++;
  else if (mins < 720) ageBuckets['4-12h']++;
  else if (mins < 1440) ageBuckets['12-24h']++;
  else ageBuckets['24h+']++;
});
console.log(`Total running: ${runningMissions.length}`);
Object.entries(ageBuckets).forEach(([bucket, count]) => {
  const status = (bucket === '24h+' && count > 0) ? ' 🚨' : (bucket === '12-24h' && count > 0) ? ' ⚠️' : '';
  console.log(`  ${bucket}: ${count}${status}`);
});

// Recent 24h performance
const dayAgo = new Date(now - 24*60*60*1000);
const recent = missions.filter(m => new Date(m.created_at) > dayAgo);
const recentSucc = recent.filter(m => m.status === 'succeeded').length;
console.log(`\n📈 LAST 24 HOURS: ${recent.length} missions, ${recentSucc} succeeded (${recent.length > 0 ? ((recentSucc/recent.length)*100).toFixed(1) : 0}%)`);

console.log('\n' + '='.repeat(60));
