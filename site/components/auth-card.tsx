'use client';

import { useState } from 'react';
import { Chrome, LoaderCircle, LockKeyhole, Mail } from 'lucide-react';

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
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        window.location.href = '/dashboard';
      } else {
        const { error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;
        setMessage(
          'Account created. If email confirmation is enabled in Supabase, please confirm your email before signing in.',
        );
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
      <div className="rounded-[1.75rem] border border-orange-100 bg-gradient-to-br from-orange-50 via-white to-[#fff5e8] p-6">
        <div className="text-sm font-semibold uppercase tracking-[0.18em] text-orange-500">
          Account access
        </div>
        <h2 className="mt-3 text-3xl font-black text-stone-900">
          {mode === 'signin' ? 'Welcome back' : 'Create your account'}
        </h2>
        <p className="mt-3 text-sm leading-7 text-stone-600">
          Sign in to open your trading dashboard, saved chart analyses, plan details, and credit balance.
        </p>
      </div>

      <div className="mt-6 inline-flex rounded-2xl border border-stone-200 bg-stone-50 p-1">
        <button
          type="button"
          onClick={() => setMode('signin')}
          className={`rounded-2xl px-4 py-2 text-sm font-semibold transition ${
            mode === 'signin'
              ? 'bg-white text-stone-900 shadow-sm'
              : 'text-stone-500 hover:text-stone-900'
          }`}
        >
          Sign in
        </button>
        <button
          type="button"
          onClick={() => setMode('signup')}
          className={`rounded-2xl px-4 py-2 text-sm font-semibold transition ${
            mode === 'signup'
              ? 'bg-white text-stone-900 shadow-sm'
              : 'text-stone-500 hover:text-stone-900'
          }`}
        >
          Sign up
        </button>
      </div>

      <form onSubmit={handleSubmit} className="mt-6 space-y-4">
        <label className="block">
          <span className="mb-2 inline-flex items-center gap-2 text-sm text-stone-600">
            <Mail size={16} />
            Email
          </span>
          <input
            type="email"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="w-full rounded-2xl border border-stone-200 bg-white px-4 py-4 text-stone-900 outline-none transition focus:border-orange-300"
            placeholder="you@example.com"
          />
        </label>

        <label className="block">
          <span className="mb-2 inline-flex items-center gap-2 text-sm text-stone-600">
            <LockKeyhole size={16} />
            Password
          </span>
          <input
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="w-full rounded-2xl border border-stone-200 bg-white px-4 py-4 text-stone-900 outline-none transition focus:border-orange-300"
            placeholder="At least 6 characters"
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="inline-flex w-full items-center justify-center gap-2 rounded-2xl bg-stone-900 px-4 py-4 font-semibold text-white transition hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {loading ? <LoaderCircle className="animate-spin" size={18} /> : null}
          {mode === 'signin' ? 'Sign in' : 'Create account'}
        </button>
      </form>

      <button
        type="button"
        onClick={handleGoogle}
        disabled={loading}
        className="mt-3 inline-flex w-full items-center justify-center gap-2 rounded-2xl border border-stone-200 bg-white px-4 py-4 font-semibold text-stone-800 transition hover:border-orange-300 hover:bg-orange-50 disabled:cursor-not-allowed disabled:opacity-60"
      >
        <Chrome size={18} />
        Continue with Google
      </button>

      {message ? (
        <div className="mt-4 rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3 text-sm leading-6 text-stone-700">
          {message}
        </div>
      ) : null}
    </div>
  );
}
