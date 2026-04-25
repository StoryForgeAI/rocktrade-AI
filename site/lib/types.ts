export type ThemeMode = 'dark' | 'light';

export type MarketSentiment = 'bullish' | 'bearish' | 'neutral';
export type RiskLevel = 'low' | 'medium' | 'high';

export type UserProfile = {
  id: string;
  email: string;
  credits: number;
  plan: string;
  created_at: string;
};

export type SubscriptionInfo = {
  user_id: string;
  plan: string;
  status: string;
  current_period_end: string | null;
  last_credit_refill_at: string | null;
};

export type TradeAnalysis = {
  marketSentiment: MarketSentiment;
  entrySuggestion: string;
  exitSuggestion: string;
  riskLevel: RiskLevel;
  reasoning: string;
  confidenceScore: number;
  whatIsHappening: string;
  whenToBuy: string;
  whenToSell: string;
  keySignals: string[];
  detectedIndicators: string[];
};

export type AnalysisRecord = {
  id: string;
  image_url: string;
  result: TradeAnalysis;
  created_at: string;
};

export type DashboardData = {
  profile: UserProfile;
  subscription: SubscriptionInfo | null;
  analyses: AnalysisRecord[];
};

export type CheckoutProduct = {
  id: string;
  title: string;
  priceLabel: string;
  description: string;
  mode: 'payment' | 'subscription';
};
