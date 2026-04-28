-- FlowSync Pro analytics RPC functions for Supabase Edge API.
-- Safe to run multiple times.

create or replace function public.fs_analytics_delays()
returns jsonb
language sql
security definer
set search_path = public
as $$
with steps as (
  select
    id,
    status,
    expected_time,
    coalesce(actual_time, now()) as effective_actual_time
  from public.shipment_steps
),
delayed as (
  select *
  from steps
  where status in ('NEEDS_CONFIRMATION', 'ESCALATED', 'BLOCKED')
     or effective_actual_time > expected_time
),
delay_totals as (
  select
    count(*)::int as total_steps,
    (select count(*)::int from delayed) as delayed_steps,
    coalesce(
      (
        select sum(
          greatest(0, round(extract(epoch from (effective_actual_time - expected_time)) / 60)::int)
        )
        from delayed
      ),
      0
    )::int as total_delay_minutes,
    (
      select count(*)::int
      from steps
      where status = 'NEEDS_CONFIRMATION'
    ) as needs_confirmation
  from steps
)
select jsonb_build_object(
  'totalSteps', total_steps,
  'delayedSteps', delayed_steps,
  'delayPercent',
    case
      when total_steps = 0 then 0
      else round((delayed_steps::numeric / total_steps::numeric) * 1000) / 10
    end,
  'averageDelayMinutes',
    case
      when delayed_steps = 0 then 0
      else round(total_delay_minutes::numeric / delayed_steps::numeric)::int
    end,
  'needsConfirmation', needs_confirmation
)
from delay_totals;
$$;

create or replace function public.fs_analytics_performance()
returns jsonb
language sql
security definer
set search_path = public
as $$
with shipment_totals as (
  select
    count(*)::int as total_shipments,
    count(*) filter (
      where current_status in ('PLANNED', 'IN_TRANSIT', 'NEEDS_CONFIRMATION', 'ESCALATED', 'DELAYED')
    )::int as active_shipments,
    count(*) filter (where current_status = 'COMPLETED')::int as completed_shipments
  from public.shipments
),
step_confirmation as (
  select
    coalesce(
      avg(
        greatest(0, round(extract(epoch from (actual_time - expected_time)) / 60)::int)
      ) filter (where actual_time is not null),
      0
    )::int as average_confirmation_minutes
  from public.shipment_steps
),
escalation_totals as (
  select count(*)::int as escalation_count
  from public.escalation_attempts
)
select jsonb_build_object(
  'activeShipments', shipment_totals.active_shipments,
  'completedShipments', shipment_totals.completed_shipments,
  'completionRate',
    case
      when shipment_totals.total_shipments = 0 then 0
      else round((shipment_totals.completed_shipments::numeric / shipment_totals.total_shipments::numeric) * 1000) / 10
    end,
  'averageConfirmationMinutes', step_confirmation.average_confirmation_minutes,
  'escalationFrequency',
    case
      when shipment_totals.total_shipments = 0 then 0
      else round((escalation_totals.escalation_count::numeric / shipment_totals.total_shipments::numeric) * 100) / 100
    end
)
from shipment_totals, step_confirmation, escalation_totals;
$$;

create or replace function public.fs_analytics_reliability(p_limit int default 50)
returns jsonb
language sql
security definer
set search_path = public
as $$
with transporter_rows as (
  select
    sp.id,
    coalesce(u.name, sp.invite_phone, 'External transporter') as transporter_name,
    sp.reliability_score::numeric as reliability_score,
    sp.response_rate::numeric as response_rate,
    s.reference_number
  from public.shipment_participants sp
  join public.shipments s on s.id = sp.shipment_id
  left join public.users u on u.id = sp.user_id
  where sp.participant_role = 'TRANSPORTER'
  order by sp.reliability_score desc, sp.response_rate desc
  limit greatest(coalesce(p_limit, 50), 1)
),
reliability_totals as (
  select coalesce(round(avg(reliability_score))::int, 0) as average_reliability
  from transporter_rows
)
select jsonb_build_object(
  'averageReliability', reliability_totals.average_reliability,
  'transporters',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'name', transporter_name,
            'reliabilityScore', reliability_score,
            'responseRate', response_rate,
            'shipmentReference', reference_number
          )
        )
        from transporter_rows
      ),
      '[]'::jsonb
    )
)
from reliability_totals;
$$;

grant execute on function public.fs_analytics_delays() to anon, authenticated, service_role;
grant execute on function public.fs_analytics_performance() to anon, authenticated, service_role;
grant execute on function public.fs_analytics_reliability(int) to anon, authenticated, service_role;
