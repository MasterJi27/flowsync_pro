import { logger } from '../src/config/logger';

const baseUrl = process.env.API_URL ?? 'http://localhost:4000';

async function request<T>(path: string, options: RequestInit & { token?: string } = {}): Promise<T> {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
      ...(options.headers ?? {})
    }
  });

  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${await response.text()}`);
  }
  return (await response.json()) as T;
}

async function login(emailOrPhone: string) {
  return request<{ token: string; user: { id: string; name: string } }>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ emailOrPhone, password: 'Password123!' })
  });
}

async function main() {
  const broker = await login('broker@flowsync.local');
  const client = await login('client@flowsync.local');

  const created = await request<any>('/shipments', {
    method: 'POST',
    token: broker.token,
    body: JSON.stringify({
      origin: 'Mumbai Port',
      destination: 'Bengaluru DC',
      transportType: 'ROAD',
      priorityLevel: 'HIGH',
      steps: [
        {
          stepName: 'Pickup',
          sequenceOrder: 1,
          expectedTime: new Date(Date.now() - 30 * 60 * 1000).toISOString()
        },
        {
          stepName: 'Warehouse',
          sequenceOrder: 2,
          expectedTime: new Date(Date.now() + 90 * 60 * 1000).toISOString()
        },
        {
          stepName: 'Delivery',
          sequenceOrder: 3,
          expectedTime: new Date(Date.now() + 240 * 60 * 1000).toISOString()
        }
      ]
    })
  });

  const invite = await request<any>(`/shipments/${created.id}/invite-transporter`, {
    method: 'POST',
    token: broker.token,
    body: JSON.stringify({ phone: '+919812345678' })
  });

  await request(`/shipments/${created.id}/participants`, {
    method: 'POST',
    token: broker.token,
    body: JSON.stringify({
      userId: client.user.id,
      participantRole: 'CLIENT'
    })
  });

  const inviteAccess = await request<{ token: string }>('/auth/invite-access', {
    method: 'POST',
    body: JSON.stringify({ token: invite.invite.token, phone: '+919812345678' })
  });

  await request('/escalations/trigger', {
    method: 'POST',
    token: broker.token,
    body: JSON.stringify({
      shipmentId: created.id,
      stepId: created.steps[0].id,
      reason: 'Demo flow: pickup is overdue with no valid confirmation'
    })
  });

  const confirmed = await request<any>(`/steps/${created.steps[0].id}`, {
    method: 'PATCH',
    token: inviteAccess.token,
    body: JSON.stringify({
      status: 'COMPLETED',
      notes: 'Pickup completed by invited transporter. POD will follow.',
      confidenceScore: 78
    })
  });

  const clientView = await request<any>(`/shipments/${created.id}`, {
    token: client.token
  });

  logger.info(
    {
      brokerCreatedShipment: created.referenceNumber,
      inviteToken: invite.invite.token,
      firstStepStatus: confirmed.status,
      clientSeesStatus: clientView.currentStatus,
      timelineStepCount: clientView.steps.length
    },
    'Demo flow completed'
  );
}

main().catch((error) => {
  logger.error({ error }, 'Demo flow failed');
  process.exit(1);
});
