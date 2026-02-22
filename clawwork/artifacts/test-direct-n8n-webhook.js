#!/usr/bin/env node

/**
 * Direct n8n Webhook Smoke Test
 * Task: direct-webhook-smoke-20260221-1
 * INSTRUCTIONS: DO NOT edit repo. Use SVE_SALES_WEBHOOK_URL and API_KEY
 */

const WEBHOOK_URL = process.env.SVE_SALES_WEBHOOK_URL || '';
const API_KEY = process.env.SVE_SALES_WEBHOOK_API_KEY || '';

const TEST_LEAD = {
  email: 'direct-smoke-test-20260221@vaos.sh',
  source: 'direct-webhook-smoke-20260221-1',
  offerVariant: 'factory',
  metadata: {
    testRun: true,
    taskId: '17',
    timestamp: new Date().toISOString(),
    userAgent: 'clawwork-direct-webhook-tester/1.0',
    platform: 'direct',
    experimentId: 'direct-webhook-smoke-20260221-1',
  },
};

async function dispatchToN8n() {
  console.log('📤 Direct n8n webhook smoke test...');
  console.log('Target:', WEBHOOK_URL);
  console.log('API Key:', API_KEY ? '✅ CONFIGURED' : '❌ NOT SET');
  console.log('Payload:', JSON.stringify(TEST_LEAD, null, 2));

  if (!WEBHOOK_URL) {
    console.error('\n❌ FAILED: SVE_SALES_WEBHOOK_URL not configured');
    return { success: false, error: 'Environment variable not set' };
  }

  if (!API_KEY) {
    console.error('\n❌ FAILED: SVE_SALES_WEBHOOK_API_KEY not configured');
    return { success: false, error: 'API key not set' };
  }

  try {
    const response = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'clawwork-direct-webhook-tester/1.0',
        'X-API-Key': API_KEY,
      },
      body: JSON.stringify(TEST_LEAD),
    });

    console.log('\n✅ n8n Response:');
    console.log('Status:', response.status, response.statusText);

    const responseText = await response.text();
    console.log('Response Body:', responseText);

    let responseData = null;
    try {
      responseData = JSON.parse(responseText);
    } catch {
      // Response is not JSON, use raw text
    }

    console.log('\n📊 Test Summary:');
    console.log('  - n8n Webhook: ✅ CALLED');
    console.log('  - HTTP Status:', response.status);
    console.log('  - Response Type:', responseData ? 'JSON' : 'TEXT');

    if (responseData) {
      console.log('  - Response Data:', JSON.stringify(responseData, null, 2));
    }

    return {
      success: response.ok,
      webhookUrl: WEBHOOK_URL,
      apiKeyConfigured: true,
      httpStatus: response.status,
      httpStatusText: response.statusText,
      response: responseData || responseText,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error('\n❌ Dispatch Failed:');
    console.error('Error:', error instanceof Error ? error.message : String(error));
    return {
      success: false,
      webhookUrl: WEBHOOK_URL,
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    };
  }
}

// Run the test
dispatchToN8n()
  .then((result) => {
    console.log('\n🏁 Final Result:', result.success ? '✅ SUCCESS' : '❌ FAILED');
    process.exit(result.success ? 0 : 1);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
