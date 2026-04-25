'use client';

import { useState } from 'react';
import { LoaderCircle, Mail, LockKeyhole, Chrome } from 'lucide-react';

import { supabase } from '@/lib/supabase';

export function AuthCard() {
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setMessage(null);

    try {
      if (mode === 'signin') {
        const { error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        if (error) throw error;
        window.location.href = '/dashboard';
      } else {
        const { error } = await supabase.auth.signUp({
          email,
          password,
        });
        if (error) throw error;
        setMessage('Fiók létrehozva. Ha a Supabase-ben be van kapcsolva az email megerősítés, nézd meg a postaládádat.');
      }
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Authentication failed.');
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogle() {
    setLoading(true);
    setMessage(null);

    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/dashboard`,
        },
      });
      if (error) throw error;
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Google sign-in failed.');
      setLoading(false);
    }
  }

  return (
    <div>
      <div className="rounded-3xl border border-white/10 bg-gradient-to-br from-orange-500/18 to-transparent p-6">
        <div className="text-sm uppercase tracking-[0.18em] text-orange-200">
          Web access
        </div>
        <h2 className="mt-3 text-3xl font-black text-white">
          {mode === 'signin' ? 'Welcome back' : 'Create your account'}
        </h2>
        <p className="mt-3 text-sm leading-6 text-white/65">
          Start with 15 credits, then top up with Stripe or move onto a weekly plan.
        </p>
      </div>

      <div className="mt-6 inline-flex rounded-2xl border border-white/10 bg-black/20 p-1">
        <button
          type="button"
          onClick={() => setMode('signin')}
          className={`rounded-2xl px-4 py-2 text-sm font-semibold transition ${
            mode === 'signin'
              ? 'bg-orange-500 text-white'
              : 'text-white/60 hover:text-white'
          }`}
        >
          Sign in
        </button>
        <button
          type="button"
          onClick={() => setMode('signup')}
          className={`rounded-2xl px-4 py-2 text-sm font-semibold transition ${
            mode === 'signup'
              ? 'bg-orange-500 text-white'
              : 'text-white/60 hover:text-white'
          }`}
        >
          Sign up
        </button>
      </div>

      <form onSubmit={handleSubmit} className="mt-6 space-y-4">
        <label className="block">
          <span className="mb-2 inline-flex items-center gap-2 text-sm text-white/70">
            <Mail size={16} />
            Email
          </span>
          <input
            type="email"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-4 text-white outline-none transition focus:border-orange-400"
            placeholder="you@example.com"
          />
        </label>

        <label className="block">
          <span className="mb-2 inline-flex items-center gap-2 text-sm text-white/70">
            <LockKeyhole size={16} />
            Password
          </span>
          <input
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-4 text-white outline-none transition focus:border-orange-400"
            placeholder="At least 6 characters"
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="inline-flex w-full items-center justify-center gap-2 rounded-2xl bg-orange-500 px-4 py-4 font-bold text-white transition hover:bg-orange-400 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {loading ? <LoaderCircle className="animate-spin" size={18} /> : null}
          {mode === 'signin' ? 'Sign in' : 'Create account'}
        </button>
      </form>

      <button
        type="button"
        onClick={handleGoogle}
        disabled={loading}
        className="mt-3 inline-flex w-full items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-4 py-4 font-semibold text-white transition hover:border-orange-400/60 hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-60"
      >
        <Chrome size={18} />
        Continue with Google
      </button>

      {message ? (
        <div className="mt-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm leading-6 text-white/75">
          {message}
        </div>
      ) : null}
    </div>
  );
}
