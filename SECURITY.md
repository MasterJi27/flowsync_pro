# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | ✅ Yes             |

## Reporting a Vulnerability

If you discover a security vulnerability in FlowSync Pro, please report it responsibly:

1. **Email**: [raghu27kathuria@gmail.com](mailto:raghu27kathuria@gmail.com)
2. **Do NOT** open a public GitHub issue for security vulnerabilities

### What to include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response timeline

- **Acknowledgement**: Within 48 hours
- **Initial assessment**: Within 5 business days
- **Fix & disclosure**: Coordinated with reporter

## Security Measures

FlowSync Pro implements the following security practices:

- 🔐 **Firebase Authentication** with Google Sign-In and email/password
- 🛡️ **Helmet.js** for HTTP security headers
- 🚦 **Rate limiting** on all API endpoints (stricter on auth routes)
- ✅ **Zod schema validation** on all request inputs
- 🔑 **JWT-based session management** with configurable expiry
- 📝 **Immutable audit logs** for all shipment actions
- 🔒 **CORS** with configurable allowed origins
- 🗄️ **Prisma ORM** to prevent SQL injection
- 🚫 **No secrets in source code** — all credentials via environment variables

## Client-Side Firebase Keys

The Firebase API keys present in `firebase_options.dart` and `google-services.json` are **client-side identifiers**, not secret keys. As per [Firebase documentation](https://firebase.google.com/docs/projects/api-keys), these keys only identify the Firebase project and are safe to include in client applications. Data access is controlled through Firebase Security Rules.
