import { Router } from 'express';
import { validate } from '../../middleware/validate';
import { register, login, firebaseLogin, inviteAccess, logout, refreshToken, getCurrentUser } from './auth.controller.enhanced';
import { firebaseLoginSchema, inviteAccessSchema, loginSchema, registerSchema } from './auth.validation';

export const authRoutes = Router();

authRoutes.post('/register', validate(registerSchema), register);
authRoutes.post('/login', validate(loginSchema), login);
authRoutes.post('/firebase-login', validate(firebaseLoginSchema), firebaseLogin);
authRoutes.post('/invite-access', validate(inviteAccessSchema), inviteAccess);
authRoutes.post('/logout', logout);
authRoutes.post('/refresh-token', refreshToken);
authRoutes.get('/me', getCurrentUser);
