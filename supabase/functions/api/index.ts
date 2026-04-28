import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });

const normalizePath = (pathname: string) => {
  let path = pathname;
  if (path.startsWith('/functions/v1/api')) {
    path = path.slice('/functions/v1/api'.length);
  } else if (path.startsWith('/api')) {
    path = path.slice('/api'.length);
  }
  if (path.length === 0) {
    return '/';
  }
  return path.startsWith('/') ? path : `/${path}`;
};

const createAdminClient = () => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  }

  return createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
};

const runAnalyticsRpc = async (fnName: string, params: Record<string, unknown> = {}) => {
  const supabase = createAdminClient();
  const { data, error } = await supabase.rpc(fnName, params);
  if (error) {
    throw error;
  }
  return data;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = normalizePath(url.pathname);

  try {
    if (req.method === 'GET' && path === '/health') {
      return json({
        status: 'ok',
        service: 'flowsync-supabase-api',
        timestamp: new Date().toISOString(),
      });
    }

    if (req.method === 'GET' && path === '/analytics/delays') {
      return json(await runAnalyticsRpc('fs_analytics_delays'));
    }

    if (req.method === 'GET' && path === '/analytics/performance') {
      return json(await runAnalyticsRpc('fs_analytics_performance'));
    }

    if (req.method === 'GET' && path === '/analytics/reliability') {
      const limitParam = url.searchParams.get('limit');
      const limit = limitParam == null ? 50 : Number.parseInt(limitParam, 10);
      return json(
        await runAnalyticsRpc('fs_analytics_reliability', {
          p_limit: Number.isFinite(limit) && limit > 0 ? limit : 50,
        })
      );
    }

    return json({ error: 'Not found', path }, 404);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return json({ error: message, path }, 500);
  }
});
