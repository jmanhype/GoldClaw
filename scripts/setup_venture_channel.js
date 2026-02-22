#!/usr/bin/env node

const API = 'https://discord.com/api/v10';

const token = process.env.DISCORD_BOT_TOKEN;
const guildId = process.env.DISCORD_GUILD_ID;

if (!token || !guildId) {
  console.error('Missing DISCORD_BOT_TOKEN or DISCORD_GUILD_ID');
  process.exit(1);
}

async function api(path, method = 'GET', body) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      Authorization: `Bot ${token}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`${method} ${path} failed: ${res.status} ${JSON.stringify(json)}`);
  }
  return json;
}

async function main() {
  const channels = await api(`/guilds/${guildId}/channels`);
  let forum = channels.find((c) => c.name === 'autonomous-revenue' && c.type === 15);

  if (!forum) {
    forum = await api(`/guilds/${guildId}/channels`, 'POST', {
      name: 'autonomous-revenue',
      type: 15,
      topic: 'The Ledger of Sovereign Ventures. Each thread is a Company.',
      available_tags: [
        { name: 'Live', emoji_name: '🟢' },
        { name: 'Staging', emoji_name: '🟡' },
        { name: 'Backlog', emoji_name: '🔴' },
        { name: 'Hibernating', emoji_name: '💀' },
      ],
    });
  }

  const active = await api(`/channels/${forum.id}/threads/active`);
  let flagship = (active.threads || []).find((t) => t.name === 'vaos.sh - Flagship');
  if (!flagship) {
    const liveTag = (forum.available_tags || []).find((t) => t.name.toLowerCase() === 'live');
    flagship = await api(`/channels/${forum.id}/threads`, 'POST', {
      name: 'vaos.sh - Flagship',
      auto_archive_duration: 10080,
      message: {
        content:
          '**🏛️ SOVEREIGN VENTURE ENGINE: ONLINE**\n\n' +
          '**Mission:** Operate under policy-gated autonomous venture rules.\n' +
          '**Status:** 🟡 Staging (`dry_run=true`)\n\n' +
          'Use Telegram command plane for mandates/approvals and keep all execution events in this thread.',
      },
      applied_tags: liveTag ? [liveTag.id] : [],
    });
  }

  console.log(JSON.stringify({ forum_id: forum.id, flagship_thread_id: flagship.id }, null, 2));
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
