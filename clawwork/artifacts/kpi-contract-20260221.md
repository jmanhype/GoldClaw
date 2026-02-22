# VAOS KPI Contract (nosales-4h-01)
**Task ID:** 18 (DB ID)
**Sprint:** nosales-4h
**UTC Timestamp:** 2026-02-21T19:35:00Z
**Status:** EXECUTED

---

## North Star Metric

### Daily Waitlist Signups (DWLS)

**Definition:** Number of unique email addresses added to vaos.sh waitlist per 24-hour period (UTC midnight to midnight)

**Formula:**
```
DWLS = COUNT(DISTINCT email) WHERE event_timestamp >= start_of_day AND event_timestamp < end_of_day
```

**Success Threshold:** 10 signups/day (initial target)
**Stretch Goal:** 50 signups/day (validated demand)

---

## Supporting Metrics (3 Core)

### 1. Landing Page Conversion Rate (LPCR)

**Definition:** Percentage of landing page visitors who join waitlist

**Formula:**
```
LP_CR = (waitlist_submissions / landing_page_visitors) * 100
```

**Measurement:**
- Unique page views tracked via `page_view` events
- Waitlist submissions tracked via `waitlist_submit_success` events
- 24-hour rolling window

**Success Threshold:** 5% (industry average for SaaS waitlists)
**Stretch Goal:** 10% (top quartile performance)

### 2. Email Validation Rate (EVR)

**Definition:** Percentage of captured emails that are valid and deliverable

**Formula:**
```
EVR = (valid_emails / total_captured_emails) * 100
```

**Measurement:**
- Valid emails = count without syntax errors
- Deliverable = pass email verification check (future)
- Real-time validation during form submission

**Success Threshold:** 90% (minimal bounce)
**Stretch Goal:** 98% (high-quality leads)

### 3. Source Attribution Quality (SAQ)

**Definition:** Composite score measuring lead quality by acquisition source

**Formula:**
```
SAQ = Σ(source_score * weight) / total_leads
where source_score ∈ [0, 10]
weight = 1.0 (equal weighting)
```

**Source Scoring:**
- Direct (landing page): 10/10 (high intent)
- Referral: 9/10 (social proof)
- Social links (bio/footer): 7/10 (passive discovery)
- Organic search: 8/10 (active seeking)
- Unknown: 0/10 (quality unknown)

**Success Threshold:** 6.0/10 average (60%)
**Stretch Goal:** 8.0/10 average (80% high-intent)

---

## KPI Readiness Score

### Calculation Method

```
KPI_SCORE = (DWLS_ACHIEVED / DWLS_TARGET) * 0.4
           + (LP_CR_ACHIEVED / LP_CR_TARGET) * 0.2
           + (EVR_ACHIEVED / EVR_TARGET) * 0.2
           + (SAQ_ACHIEVED / SAQ_TARGET) * 0.2
```

**Where:**
- DWLS_TARGET = 10 signups/day
- LP_CR_TARGET = 5% conversion
- EVR_TARGET = 90% valid
- SAQ_TARGET = 6.0/10 quality

**Score Range:** 0.0 to 1.0+
**Healthy:** ≥ 0.8 (80% of targets achieved)
**At Risk:** 0.5-0.8 (50-80% of targets achieved)
**Critical:** < 0.5 (less than 50% of targets achieved)

---

## Event Contract Schema

### Standard Event Structure

```typescript
interface VAOSEvent {
  // Required fields
  event_id: string;              // UUID v4
  event_type: string;             // Standardized type (see below)
  event_timestamp: string;         // ISO 8601 (UTC)

  // Context fields
  user_id?: string;              // Clerk user ID (if authenticated)
  session_id?: string;           // Unique session identifier
  page_url?: string;             // Current page when event fired

  // Event-specific payload
  payload: Record<string, unknown>;

  // Attribution
  source?: string;               // Acquisition source
  medium?: string;              // Acquisition medium
  campaign?: string;            // UTM campaign
  referral_code?: string;         // Referral code (if applicable)
}
```

---

## Event Types Registry

### Acquisition Events

#### `page_view`
```typescript
interface PageViewPayload {
  page: string;                 // 'landing', 'pricing', 'faq', etc.
  referrer?: string;             // HTTP referrer header
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
  utm_term?: string;
  utm_content?: string;
}
```

#### `waitlist_submit_start`
```typescript
interface WaitlistSubmitStartPayload {
  email: string;
  source: string;
  offer_variant?: string;
}
```

#### `waitlist_submit_success`
```typescript
interface WaitlistSubmitSuccessPayload {
  email: string;
  email_valid: boolean;
  source: string;
  offer_variant?: string;
  processing_time_ms: number;
}
```

#### `waitlist_submit_fail`
```typescript
interface WaitlistSubmitFailPayload {
  email: string;
  failure_reason: string;        // 'invalid_format', 'duplicate', 'server_error'
  error_code?: string;
  source: string;
}
```

### Engagement Events

#### `faq_expand`
```typescript
interface FAQExpandPayload {
  faq_id: string;               // 'faq-1', 'faq-2', etc.
  faq_question: string;         // Question text
  scroll_depth_px?: number;      // Scroll position when expanded
}
```

#### `pricing_tier_view`
```typescript
interface PricingTierViewPayload {
  tier: string;                  // 'starter', 'pro', 'factory'
  view_duration_ms?: number;   // Time spent viewing tier
  comparison_mode?: boolean;     // User comparing tiers
}
```

#### `cta_hover`
```typescript
interface CTAHoverPayload {
  cta_id: string;                // 'hero-cta', 'pricing-starter-cta', etc.
  hover_duration_ms?: number;   // Time spent hovering
  click_followed?: boolean;      // Did user click after hover?
}
```

### Conversion Events

#### `waitlist_email_verify_request`
```typescript
interface EmailVerifyRequestPayload {
  email: string;
  verification_method: string;   // 'magic_link', 'otp', etc.
}
```

#### `waitlist_email_verify_success`
```typescript
interface EmailVerifySuccessPayload {
  email: string;
  verification_method: string;
  time_to_verify_ms: number;
}
```

#### `upgrade_intent`
```typescript
interface UpgradeIntentPayload {
  current_tier?: string;        // 'free', 'trial'
  target_tier: string;          // 'starter', 'pro', 'factory'
  entry_point: string;          // 'dashboard', 'pricing', 'cta'
}
```

---

## Event Validation Rules

### Required Field Validation

All events MUST include:
- ✅ `event_id` (UUID v4 format)
- ✅ `event_type` (registered type)
- ✅ `event_timestamp` (ISO 8601, UTC)
- ✅ `payload` (object, can be empty `{}`)

### Optional Field Guidelines

- `user_id`: Required for authenticated events
- `session_id`: Required for funnel events
- `source`: Required for attribution
- `page_url`: Recommended for page events

### Data Quality Rules

- Email validation: RFC 5322 format
- Timestamps: UTC timezone always
- Enum values: Must match registry exactly
- Numeric ranges: Non-negative, reasonable bounds

---

## Attribution Tracking

### UTM Parameter Mapping

| Query Param | Event Field | Example Values |
|-------------|--------------|-----------------|
| utm_source | source | 'twitter', 'hackernews', 'direct' |
| utm_medium | medium | 'social', 'email', 'referral' |
| utm_campaign | campaign | 'launch-promo', 'q1-2026' |
| utm_content | content | 'hero-cta', 'footer-link' |
| utm_term | campaign (alias) | 'vaos', 'ai-ops' |

### Referral Code Tracking

Format: `ref=CODE`
- Max length: 32 characters
- Valid chars: A-Z, a-z, 0-9, -, _
- Case-insensitive matching

---

## Event Storage Strategy

### Immediate (Hot Storage)
- **Implementation:** In-memory event buffer
- **Retention:** 100 events max
- **Flush Interval:** Every 30 seconds OR 50 events
- **Purpose:** Low-latency tracking

### Intermediate (Warm Storage)
- **Implementation:** Next.js API route `/api/events`
- **Retention:** 24 hours
- **Purpose:** Analytics aggregation
- **Format:** JSON files or in-memory store (until Supabase)

### Persistent (Cold Storage)
- **Implementation:** Supabase `events` table
- **Retention:** 90 days
- **Purpose:** Long-term analytics
- **Index:** `event_timestamp`, `event_type`, `user_id`

---

## Success Criteria

### KPI Contract Fulfilled When:

1. ✅ North star metric defined and measurable
2. ✅ 3 supporting metrics defined with formulas
3. ✅ Event type registry created (10+ event types)
4. ✅ Standard event schema documented
5. ✅ Validation rules specified
6. ✅ Attribution tracking strategy defined
7. ✅ Storage strategy defined (hot/warm/cold)
8. ✅ Success thresholds set for all KPIs

### Ready for Implementation When:

1. ✅ Event tracking endpoints planned (`/api/events`)
2. ✅ Database schema designed (`events` table)
3. ✅ Frontend instrumentation plan ready
4. ✅ Analytics aggregation queries defined
5. ✅ Dashboard integration requirements documented

---

## KPI Dashboard Requirements

### Real-Time Display (T+0 days)

- Current DWLS (today's signups)
- Daily trend (last 7 days)
- Live conversion rate (rolling 24h)
- Top sources (last 24h)

### Daily Report (T+1 day)

- Previous day DWLS
- Target vs actual comparison
- KPI readiness score
- Blockers and actions

### Weekly Report (T+7 days)

- Week-over-week growth
- Attribution mix breakdown
- Top performing pages
- Conversion funnel visualization

---

## Sprint Deliverables

### Artifact (This File)
- ✅ KPI contract documented
- ✅ Event schema defined
- ✅ Event registry created
- ✅ Validation rules specified

### Next Task (nosales-4h-02)
- Implement core funnel instrumentation
  - Hero CTA tracking
  - Pricing interaction tracking
  - Waitlist submit success/fail tracking
  - Source attribution implementation

---

**Status:** ✅ READY FOR IMPLEMENTATION
**KPI Contract Version:** 1.0
**Valid Through:** Sprint nosales-4h
