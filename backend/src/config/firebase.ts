import admin from 'firebase-admin';
import jwt, { type JwtPayload } from 'jsonwebtoken';
import { env } from './env';

let firebaseApp: admin.app.App | null = null;
let publicCertCache: { certs: Record<string, string>; expiresAt: number } | null = null;

export type FirebaseIdentityToken = {
  uid: string;
  email?: string;
  phone_number?: string;
  name?: string;
};

const hasFirebaseConfig =
  !!env.FIREBASE_PROJECT_ID &&
  !!env.FIREBASE_CLIENT_EMAIL &&
  !!env.FIREBASE_PRIVATE_KEY;

const secureTokenCertsUrl =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

function ensureFirebaseApp(): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  if (!hasFirebaseConfig) {
    throw new Error(
      'Firebase Admin is not configured. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY.'
    );
  }

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      privateKey: env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, '\n')
    })
  });

  return firebaseApp;
}

export async function verifyFirebaseIdToken(idToken: string): Promise<FirebaseIdentityToken> {
  if (hasFirebaseConfig) {
    const app = ensureFirebaseApp();
    const decoded = await admin.auth(app).verifyIdToken(idToken, true);
    return normalizeFirebaseToken({
      uid: decoded.uid,
      email: decoded.email,
      phone_number: decoded.phone_number,
      name: typeof decoded.name === 'string' ? decoded.name : undefined
    });
  }

  return verifyWithGooglePublicCerts(idToken);
}

async function verifyWithGooglePublicCerts(idToken: string): Promise<FirebaseIdentityToken> {
  if (!env.FIREBASE_PROJECT_ID) {
    throw new Error('Firebase token verification requires FIREBASE_PROJECT_ID.');
  }

  const decoded = jwt.decode(idToken, { complete: true });
  if (!decoded || typeof decoded === 'string') {
    throw new Error('Invalid Firebase identity token.');
  }

  const kid = decoded.header.kid;
  if (!kid) {
    throw new Error('Firebase identity token is missing a key id.');
  }

  const certs = await fetchGooglePublicCerts();
  const cert = certs[kid];
  if (!cert) {
    publicCertCache = null;
    throw new Error('Firebase identity token key was not recognized.');
  }

  const verified = jwt.verify(idToken, cert, {
    algorithms: ['RS256'],
    audience: env.FIREBASE_PROJECT_ID,
    issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`
  }) as JwtPayload;

  return normalizeFirebaseToken({
    uid: typeof verified.sub === 'string' ? verified.sub : '',
    email: typeof verified.email === 'string' ? verified.email : undefined,
    phone_number:
      typeof verified.phone_number === 'string' ? verified.phone_number : undefined,
    name: typeof verified.name === 'string' ? verified.name : undefined
  });
}

async function fetchGooglePublicCerts(): Promise<Record<string, string>> {
  if (publicCertCache && publicCertCache.expiresAt > Date.now()) {
    return publicCertCache.certs;
  }

  const response = await fetch(secureTokenCertsUrl);
  if (!response.ok) {
    throw new Error(`Could not fetch Firebase public certificates (${response.status}).`);
  }

  const certs = (await response.json()) as Record<string, string>;
  const maxAge = parseMaxAge(response.headers.get('cache-control'));
  publicCertCache = {
    certs,
    expiresAt: Date.now() + maxAge
  };

  return certs;
}

function parseMaxAge(cacheControl: string | null): number {
  const match = /max-age=(\d+)/i.exec(cacheControl ?? '');
  const seconds = match ? Number(match[1]) : 3600;
  return Math.max(seconds * 1000 - 60_000, 60_000);
}

function normalizeFirebaseToken(token: FirebaseIdentityToken): FirebaseIdentityToken {
  if (!token.uid) {
    throw new Error('Firebase identity token is missing a subject.');
  }

  return token;
}
