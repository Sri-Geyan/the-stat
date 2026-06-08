-- Drop profiles table if you want to start fresh (WARNING: drops existing profiles data)
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Create profiles table
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('batter', 'bowler', 'wicketkeeper', 'bowling all rounder', 'batting all rounder', 'proper all rounder')),
  position TEXT NOT NULL,
  batting_hand TEXT CHECK (batting_hand IN ('Right-Hand', 'Left-Hand')),
  bowling_hand TEXT CHECK (bowling_hand IN ('Right-Arm', 'Left-Arm')),
  bowling_type TEXT CHECK (bowling_type IN ('Fast', 'Medium Fast', 'Medium', 'Orthodox', 'Wrist Spin', 'Chinaman')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
CREATE POLICY "Anyone can view profiles" ON public.profiles
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can create/update their own profile" ON public.profiles
  FOR ALL USING (auth.uid() = id);
