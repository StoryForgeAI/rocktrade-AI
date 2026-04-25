import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

import { corsHeaders } from '../_shared/cors.ts';

const openAiApiKey = Deno.env.get('OPENAI_API_KEY') ?? '';
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const analysisSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    marketSentiment: { type: 'string', enum: ['bullish', 'bearish', 'neutral'] },
    entrySuggestion: { type: 'string' },
    exitSuggestion: { type: 'string' },
    riskLevel: { type: 'string', enum: ['low', 'medium', 'high'] },
    reasoning: { type: 'string' },
    confidenceScore: { type: 'integer', minimum: 0, maximum: 100 },
    whatIsHappening: { type: 'string' },
    whenToBuy: { type: 'string' },
    whenToSell: { type: 'string' },
    keySignals: { type: 'array', items: { type: 'string' } },
    detectedIndicators: { type: 'array', items: { type: 'string' } },
  },
  required: [
    'marketSentiment',
    'entrySuggestion',
    'exitSuggestion',
    'riskLevel',
    'reasoning',
    'confidenceScore',
    'whatIsHappening',
    'whenToBuy',
    'whenToSell',
    'keySignals',
    'detectedIndicators',
  ],
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('analyze-trade-image: request received');
    const authorization = request.headers.get('Authorization');
    if (!authorization) {
      return new Response(JSON.stringify({ error: 'Missing auth header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
      global: { headers: { Authorization: authorization } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    console.log('analyze-trade-image: auth checked', {
      hasUser: Boolean(user),
      authError: authError?.message ?? null,
    });

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { storagePath } = await request.json();
    console.log('analyze-trade-image: payload parsed', { storagePath });
    if (!storagePath) {
      return new Response(JSON.stringify({ error: 'storagePath is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const {
      data: profile,
      error: profileError,
    } = await supabase.from('users').select('credits').eq('id', user.id).single();

    if (profileError) throw profileError;
    console.log('analyze-trade-image: profile loaded', {
      userId: user.id,
      credits: profile?.credits ?? null,
    });
    if ((profile?.credits ?? 0) < 10) {
      return new Response(JSON.stringify({ error: 'Insufficient credits' }), {
        status: 402,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: signedUrlData, error: signedUrlError } = await supabase.storage
      .from('uploads')
      .createSignedUrl(storagePath, 60 * 15);

    if (signedUrlError || !signedUrlData?.signedUrl) {
      throw signedUrlError ?? new Error('Could not create signed URL');
    }
    console.log('analyze-trade-image: signed URL created');

    const openAiResponse = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${openAiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-5.4-mini',
        input: [
          {
            role: 'system',
            content: [
              {
                type: 'input_text',
                text:
                  'Analyze trading screenshots. Return only chart-focused market insight. Avoid financial certainty. If the screenshot is unclear, lower confidence and explain what is missing.',
              },
            ],
          },
          {
            role: 'user',
            content: [
              {
                type: 'input_text',
                text:
                  'Analyze this trading chart screenshot and produce structured JSON with sentiment, entries, exits, risk, reasoning, confidence, and detected indicators.',
              },
              {
                type: 'input_image',
                image_url: signedUrlData.signedUrl,
              },
            ],
          },
        ],
        text: {
          format: {
            type: 'json_schema',
            name: 'trade_analysis',
            strict: true,
            schema: analysisSchema,
          },
        },
      }),
    });

    console.log('analyze-trade-image: openai response received', {
      ok: openAiResponse.ok,
      status: openAiResponse.status,
    });
    if (!openAiResponse.ok) {
      const errorText = await openAiResponse.text();
      throw new Error(`OpenAI error: ${errorText}`);
    }

    const openAiPayload = await openAiResponse.json();
    console.log('analyze-trade-image: openai payload keys', {
      keys: Object.keys(openAiPayload ?? {}),
    });
    const outputText =
      openAiPayload.output_text ??
      openAiPayload.output?.[0]?.content?.find?.((item: { text?: string }) =>
        typeof item?.text === 'string'
      )?.text;
    if (!outputText) {
      throw new Error(`OpenAI returned no parsed output: ${JSON.stringify(openAiPayload)}`);
    }

    const analysis = JSON.parse(outputText);
    console.log('analyze-trade-image: analysis parsed');

    const { data: transaction, error: transactionError } = await supabase.rpc(
      'consume_credits_for_analysis',
      {
        p_user_id: user.id,
        p_image_url: storagePath,
        p_result: analysis,
        p_cost: 10,
      },
    );

    if (transactionError) throw transactionError;
    console.log('analyze-trade-image: transaction saved', { transaction });

    return new Response(
      JSON.stringify({
        analysis,
        transaction,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (error) {
    console.error('analyze-trade-image: fatal error', {
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : null,
      error,
    });
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
});
