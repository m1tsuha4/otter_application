// supabase/functions/send-fcm-detection-notification/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create } from "https://deno.land/x/djwt@v2.8/mod.ts"; // For creating JWT to get OAuth token
import { decodeString } from "https://deno.land/std@0.177.0/encoding/base64.ts"; // If private key has \n

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const FCM_SERVICE_ACCOUNT_JSON_STRING = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");

// Google OAuth 2.0 token endpoint
const GOOGLE_TOKEN_URI = "https://oauth2.googleapis.com/token";
const FCM_HTTP_V1_ENDPOINT_BASE = "https://fcm.googleapis.com/v1/projects/";

let serviceAccount: any;
let fcmEndpoint: string;

if (FCM_SERVICE_ACCOUNT_JSON_STRING) {
  try {
    serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON_STRING);
    fcmEndpoint = `${FCM_HTTP_V1_ENDPOINT_BASE}${serviceAccount.project_id}/messages:send`;
  } catch (e) {
    console.error("Failed to parse FCM_SERVICE_ACCOUNT_JSON:", e);
  }
} else {
  console.error("FCM_SERVICE_ACCOUNT_JSON environment variable is not set.");
}

const getSupabaseServiceRoleClient = (): SupabaseClient => {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("Supabase URL or Service Role Key environment variables are not set.");
  }
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
};

// Function to get OAuth 2.0 access token from Google
async function getAccessToken(): Promise<string> {
  if (!serviceAccount) {
    throw new Error("Service account not loaded.");
  }

  // The private key might have literal \n characters if pasted directly.
  // If it's stored correctly as a JSON string (e.g., in Supabase secrets),
  // JSON.parse handles the escaped newlines. If not, you might need to replace \\n with \n.
  const privateKeyPem = serviceAccount.private_key.replace(/\\n/g, '\n');

  const nowInSeconds = Math.floor(Date.now() / 1000);
  const expirationInSeconds = nowInSeconds + 3600; // Token valid for 1 hour

  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: GOOGLE_TOKEN_URI,
    iat: nowInSeconds,
    exp: expirationInSeconds,
    scope: "https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/firebase.messaging",
  };

  // Use the 'RSASSA-PKCS1-v1_5' algorithm with SHA-256.
  // The djwt library expects the key in CryptoKey format for RSA.
  // Importing a PEM key requires some steps.
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBinary(privateKeyPem), // Convert PEM to ArrayBuffer
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const jwt = await create({ alg: "RS256", typ: "JWT" }, payload, privateKey);

  const tokenResponse = await fetch(GOOGLE_TOKEN_URI, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    throw new Error(`Error fetching access token: ${tokenResponse.status} ${errorText}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

// Helper to convert PEM PKCS#8 private key to ArrayBuffer
function pemToBinary(pem: string): ArrayBuffer {
    const lines = pem.split('\n');
    let base64 = '';
    for (const line of lines) {
        if (line.startsWith('-----BEGIN') || line.startsWith('-----END')) {
            continue;
        }
        base64 += line.trim();
    }
    return decodeString(base64).buffer; // Use Deno's base64 decoder
}


serve(async (req) => {
  console.log("[EdgeFunction] 'send-fcm-detection-notification' (HTTPv1) invoked.");

  if (!serviceAccount || !fcmEndpoint) {
    console.error("[EdgeFunction] FATAL: FCM Service Account or Project ID not configured correctly.");
    return new Response(JSON.stringify({ error: "FCM Service Account or Project ID not configured." }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const accessToken = await getAccessToken();
    const webhookPayload = await req.json();
    const newDetection = webhookPayload.type === 'INSERT' ? webhookPayload.record : null;

    if (!newDetection) {
      console.warn("[EdgeFunction] Payload not an insert or record missing.");
      return new Response(JSON.stringify({ message: "Payload not an insert or record missing." }), { status: 400 });
    }

    console.log("[EdgeFunction] New detection received:", JSON.stringify(newDetection, null, 2));
    const detectedClass = newDetection.class_name || "A new event";
    const imageUrl = newDetection.image_url || null;

    const supabaseClient = getSupabaseServiceRoleClient();
    const { data: tokensData, error: tokensError } = await supabaseClient
      .from('device_fcm_tokens')
      .select('token')
      .eq('token_type', 'fcm');

    if (tokensError) throw tokensError;
    if (!tokensData || tokensData.length === 0) {
      console.log("[EdgeFunction] No active FCM Tokens found.");
      return new Response(JSON.stringify({ message: "No FCM tokens to notify." }), { status: 200 });
    }

    const registrationTokens = tokensData.map(t => t.token).filter(t => t && typeof t === 'string' && t.length > 0);
    console.log(`[EdgeFunction] Found ${registrationTokens.length} valid FCM tokens.`);
    if (registrationTokens.length === 0) return new Response(JSON.stringify({ message: "No valid FCM tokens." }), { status: 200 });

    // Send a notification to each token individually for HTTP v1
    // (Batch sending with HTTP v1 is done differently via multipart requests, more complex here)
    let successes = 0;
    let failures = 0;

    for (const token of registrationTokens) {
      const fcmMessagePayload = {
        message: {
          token: token,
          notification: {
            title: "🦦 Otter Sighting! (v1)",
            body: `A "${detectedClass}" was just detected!`,
          },
          data: {
            type: "detection_alert",
            className: detectedClass,
            detectionId: String(newDetection.id || "unknown"),
            imageUrl: imageUrl,
          },
          // Android specific options can be nested under 'android'
          // iOS specific options under 'apns'
        },
      };

      console.log(`[EdgeFunction] Sending message to FCM (v1) for token ${token.substring(0,20)}...:`, JSON.stringify(fcmMessagePayload.message.notification, null, 2));

      const fcmResponse = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmMessagePayload),
      });

      if (!fcmResponse.ok) {
        const errorText = await fcmResponse.text();
        console.error(`[EdgeFunction] FCM API v1 request failed for token ${token.substring(0,20)}...: ${fcmResponse.status}`, errorText);
        failures++;
      } else {
        const fcmResult = await fcmResponse.json();
        console.log(`[EdgeFunction] FCM v1 send successful for token ${token.substring(0,20)}...:`, fcmResult);
        successes++;
      }
    }

    return new Response(JSON.stringify({ success: true, successes, failures }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("[EdgeFunction] Critical Error (v1):", error.message, error.stack);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});