import type { CheckoutProduct } from '@/lib/types';

export const ANALYSIS_COST = 10;

export const SUBSCRIPTIONS: CheckoutProduct[] = [
  {
    id: 'starter',
    title: 'Starter',
    priceLabel: '$1.99 / month',
    description: '125 credits every week',
    mode: 'subscription',
  },
  {
    id: 'pro',
    title: 'Pro',
    priceLabel: '$5.99 / month',
    description: '250 credits every week',
    mode: 'subscription',
  },
  {
    id: 'trader',
    title: 'Trader',
    priceLabel: '$12.99 / month',
    description: '525 credits every week',
    mode: 'subscription',
  },
  {
    id: 'money_printer',
    title: 'Money Printer',
    priceLabel: '$19.99 / month',
    description: '925 credits every week',
    mode: 'subscription',
  },
];

export const CREDIT_PACKS: CheckoutProduct[] = [
  {
    id: 'pack_50',
    title: '50 credits',
    priceLabel: '$4.99',
    description: '5 chart analyses',
    mode: 'payment',
  },
  {
    id: 'pack_150',
    title: '150 credits',
    priceLabel: '$11.99',
    description: '15 chart analyses',
    mode: 'payment',
  },
  {
    id: 'pack_500',
    title: '500 credits',
    priceLabel: '$29.99',
    description: '50 chart analyses',
    mode: 'payment',
  },
];
