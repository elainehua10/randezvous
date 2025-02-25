import express, { Request, Response, NextFunction } from 'express';
import morgan from 'morgan';
import helmet from 'helmet';
import cors from 'cors';
import dotenv from 'dotenv';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

import * as middlewares from './middlewares';
import api from './api';
import MessageResponse from './interfaces/MessageResponse';

dotenv.config();

const app = express();

app.use(morgan('dev'));
app.use(helmet());
app.use(cors());
app.use(express.json());

// Initialize Supabase
const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_KEY!);

app.post('/register', async (req, res) => {
  const { email, password, username, firstname, lastname } = req.body;

  if (!email || !password || !username || !firstname || !lastname) {
    return res.status(400).json({ error: 'Missing required fields' }) 
  }

  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { username, firstname, lastname }
      }
    })
    if (error) throw error;
    res.status(201).json({ message: "User registered successfully", user: data.user })
  } catch (error) {
    res.status(500).json({ error: (error as Error).message || "An unknown error occurred" });
  }
})

// Default message
app.get<{}, MessageResponse>('/', (req, res) => {
  res.json({
    message: '🦄🌈✨👋🌎🌍🌏✨🌈🦄',
  });
});

app.use('/api/v1', api);

app.use(middlewares.notFound);
app.use(middlewares.errorHandler);

export default app;
