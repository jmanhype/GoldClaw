#!/usr/bin/env python3
"""
OpenClaw Native Kernel Router (V2)

First-slice deterministic router:
- Strict command parsing/validation
- Queue-safe tick ingestion
- Basic approval gating metadata
- Local JSONL record trail
"""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional


ALLOWED_INTENTS = {
    "infra.launch",
    "infra.register_domain",
    "growth.geo_audit",
    "growth.geo_inject",
    "marketing.layers_sync",
    "ops.generate_changelog",
}

APPROVAL_REQUIRED_INTENTS = {
    "infra.register_domain",
    "growth.geo_inject",
    "marketing.layers_sync",
}

ROOT = Path("/Users/speed/.openclaw/workspace")
KERNEL_DIR = ROOT / "kernel"
COMMANDS_LOG = KERNEL_DIR / "commands.jsonl"
REQUESTS_LOG = KERNEL_DIR / "requests.jsonl"
EVENTS_LOG = KERNEL_DIR / "events.jsonl"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def emit(data: Dict[str, Any], code: int = 0) -> int:
    print(json.dumps(data, indent=2, sort_keys=True))
    return code


def ensure_dirs() -> None:
    KERNEL_DIR.mkdir(parents=True, exist_ok=True)


def append_jsonl(path: Path, obj: Dict[str, Any]) -> None:
    ensure_dirs()
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=True) + "\n")


def parse_kv(tokens: List[str]) -> Dict[str, str]:
    values: Dict[str, str] = {}
    for token in tokens:
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def is_valid_domain(domain: str) -> bool:
    # Conservative domain validation.
    return bool(re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9-]{2,63})+", domain))


@dataclass
class ParseResult:
    ok: bool
    command: Optional[Dict[str, Any]]
    errors: List[str]

    def to_json(self) -> Dict[str, Any]:
        return {
            "ok": self.ok,
            "command": self.command,
            "errors": self.errors,
        }


def parse_command(text: str) -> ParseResult:
    if not text or not text.strip():
        return ParseResult(False, None, ["empty command"])

    try:
        parts = shlex.split(text.strip())
    except ValueError as exc:
        return ParseResult(False, None, [f"invalid quoting: {exc}"])

    if not parts:
        return ParseResult(False, None, ["empty command"])

    cmd = parts[0]
    errors: List[str] = []

    if cmd == "/mandate":
        if len(parts) < 3:
            return ParseResult(False, None, ["usage: /mandate <intent> domain=<domain> budget=<usd> ttl_h=<int>"])
        intent = parts[1]
        kv = parse_kv(parts[2:])
        domain = kv.get("domain", "")
        budget_raw = kv.get("budget")
        ttl_raw = kv.get("ttl_h")

        if intent not in ALLOWED_INTENTS:
            errors.append(f"intent not allowed: {intent}")
        if not domain or not is_valid_domain(domain):
            errors.append("invalid domain")
        if budget_raw is None:
            errors.append("missing budget")
            budget = None
        else:
            try:
                budget = float(budget_raw)
                if budget <= 0:
                    errors.append("budget must be > 0")
            except ValueError:
                budget = None
                errors.append("budget must be numeric")
        if ttl_raw is None:
            errors.append("missing ttl_h")
            ttl_h = None
        else:
            try:
                ttl_h = int(ttl_raw)
                if ttl_h <= 0:
                    errors.append("ttl_h must be > 0")
            except ValueError:
                ttl_h = None
                errors.append("ttl_h must be integer")

        if errors:
            return ParseResult(False, None, errors)

        return ParseResult(
            True,
            {
                "type": "mandate",
                "intent": intent,
                "domain": domain,
                "budget_usdc": budget,
                "ttl_h": ttl_h,
                "policy": {
                    "approval_required": intent in APPROVAL_REQUIRED_INTENTS or (budget is not None and budget > 0.50),
                },
            },
            [],
        )

    if cmd == "/approve":
        if len(parts) != 2:
            return ParseResult(False, None, ["usage: /approve <request_id>"])
        return ParseResult(True, {"type": "approve", "request_id": parts[1]}, [])

    if cmd == "/deny":
        if len(parts) < 3:
            return ParseResult(False, None, ['usage: /deny <request_id> reason="<text>"'])
        request_id = parts[1]
        kv = parse_kv(parts[2:])
        reason = kv.get("reason", "").strip()
        if not reason:
            return ParseResult(False, None, ['deny requires reason="<text>"'])
        return ParseResult(True, {"type": "deny", "request_id": request_id, "reason": reason}, [])

    if cmd == "/fund":
        if len(parts) != 2:
            return ParseResult(False, None, ["usage: /fund <amount_usdc>"])
        try:
            amount = float(parts[1])
            if amount <= 0:
                return ParseResult(False, None, ["amount_usdc must be > 0"])
        except ValueError:
            return ParseResult(False, None, ["amount_usdc must be numeric"])
        return ParseResult(True, {"type": "fund", "amount_usdc": amount}, [])

    if cmd in {"/status", "/pause", "/resume"}:
        domain = parts[1] if len(parts) > 1 else None
        if len(parts) > 2:
            return ParseResult(False, None, [f"usage: {cmd} [domain]"])
        if domain is not None and not is_valid_domain(domain):
            return ParseResult(False, None, ["invalid domain"])
        return ParseResult(True, {"type": cmd.lstrip("/"), "domain": domain}, [])

    if cmd == "/kill":
        if len(parts) < 3:
            return ParseResult(False, None, ["usage: /kill <domain> mode=soft|hard"])
        domain = parts[1]
        kv = parse_kv(parts[2:])
        mode = kv.get("mode")
        if not is_valid_domain(domain):
            errors.append("invalid domain")
        if mode not in {"soft", "hard"}:
            errors.append("mode must be soft or hard")
        if errors:
            return ParseResult(False, None, errors)
        return ParseResult(True, {"type": "kill", "domain": domain, "mode": mode}, [])

    return ParseResult(False, None, [f"unknown command: {cmd}"])


def cmd_parse(args: argparse.Namespace) -> int:
    result = parse_command(args.text)
    return emit(result.to_json(), 0 if result.ok else 2)


def cmd_tick(args: argparse.Namespace) -> int:
    ts = now_iso()
    parsed = parse_command(args.text)
    envelope = {
        "ts_utc": ts,
        "source": args.source,
        "raw_text": args.text,
        "parse": parsed.to_json(),
    }
    append_jsonl(COMMANDS_LOG, envelope)

    if not parsed.ok:
        event = {
            "ts_utc": ts,
            "event_type": "validation_error",
            "source": args.source,
            "errors": parsed.errors,
        }
        append_jsonl(EVENTS_LOG, event)
        return emit(
            {
                "ok": False,
                "event_type": "validation_error",
                "errors": parsed.errors,
                "logged_to": str(EVENTS_LOG),
            },
            2,
        )

    command = parsed.command or {}
    event_type = "execution_event"
    response: Dict[str, Any] = {
        "ok": True,
        "event_type": event_type,
        "command": command,
    }

    if command.get("type") == "mandate":
        request_id = str(uuid.uuid4())
        approval_required = bool(command.get("policy", {}).get("approval_required", False))
        request = {
            "ts_utc": ts,
            "request_id": request_id,
            "status": "pending_approval" if approval_required else "queued",
            "command": command,
            "source": args.source,
        }
        append_jsonl(REQUESTS_LOG, request)
        response.update(
            {
                "request_id": request_id,
                "approval_required": approval_required,
                "event_type": "approval_request" if approval_required else "execution_event",
                "logged_to": str(REQUESTS_LOG),
            }
        )

    append_jsonl(
        EVENTS_LOG,
        {
            "ts_utc": ts,
            "event_type": response["event_type"],
            "source": args.source,
            "command": command,
            "request_id": response.get("request_id"),
        },
    )
    return emit(response, 0)


def _count_lines(path: Path) -> int:
    if not path.exists():
        return 0
    with path.open("r", encoding="utf-8") as f:
        return sum(1 for _ in f)


def cmd_heartbeat(args: argparse.Namespace) -> int:
    payload = {
        "ok": True,
        "event_type": "heartbeat",
        "ts_utc": now_iso(),
        "queue_depth": _count_lines(REQUESTS_LOG),
        "commands_seen": _count_lines(COMMANDS_LOG),
        "events_seen": _count_lines(EVENTS_LOG),
        "mode": args.mode,
    }
    append_jsonl(EVENTS_LOG, payload)
    return emit(payload, 0)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="OpenClaw native kernel router")
    sub = parser.add_subparsers(dest="subcommand", required=True)

    parse_p = sub.add_parser("parse", help="parse one command")
    parse_p.add_argument("--text", required=True, help="raw command text")
    parse_p.set_defaults(func=cmd_parse)

    tick_p = sub.add_parser("tick", help="ingest one command into kernel logs")
    tick_p.add_argument("--text", required=True, help="raw command text")
    tick_p.add_argument("--source", default="manual", help="telegram|discord|manual")
    tick_p.set_defaults(func=cmd_tick)

    hb_p = sub.add_parser("heartbeat", help="emit local heartbeat snapshot")
    hb_p.add_argument("--mode", default="dry_run", help="dry_run|live")
    hb_p.set_defaults(func=cmd_heartbeat)

    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
