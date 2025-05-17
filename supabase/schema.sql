-- Create schema for Link2Chat application

-- Create users table (extends auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'member',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  subscription_tier TEXT NOT NULL DEFAULT 'free',
  subscription_expiry TIMESTAMP WITH TIME ZONE,
  preferences JSONB
);

-- Create phone_entries table for storing WhatsApp/Telegram links
CREATE TABLE public.phone_entries (
  id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users NOT NULL,
  phone_number TEXT NOT NULL,
  country_code TEXT NOT NULL,
  country_name TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  platform TEXT NOT NULL CHECK (platform IN ('whatsapp', 'telegram'))
);

-- Create teams table
CREATE TABLE public.teams (
  id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  owner_id UUID REFERENCES public.users NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  settings JSONB DEFAULT '{}'::JSONB
);

-- Create team_members table
CREATE TABLE public.team_members (
  id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  team_id UUID REFERENCES public.teams NOT NULL,
  user_id UUID REFERENCES public.users NOT NULL,
  role TEXT NOT NULL DEFAULT 'member',
  permissions TEXT[] NOT NULL DEFAULT '{}',
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  UNIQUE (team_id, user_id)
);

-- Create API Keys table
CREATE TABLE public.api_keys (
  id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  key TEXT NOT NULL UNIQUE,
  permissions TEXT[] NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_used_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Set up Row Level Security (RLS)

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phone_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own data" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own data" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Phone entries policies
CREATE POLICY "Users can view their own phone entries" ON public.phone_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own phone entries" ON public.phone_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Team members can view team phone entries" ON public.phone_entries
  FOR SELECT USING (
    phone_entries.user_id IN (
      SELECT t.owner_id FROM public.teams t
      JOIN public.team_members tm ON t.id = tm.team_id
      WHERE tm.user_id = auth.uid()
    )
  );

-- Teams policies
CREATE POLICY "Users can view teams they belong to" ON public.teams
  FOR SELECT USING (
    auth.uid() = owner_id 
    OR 
    teams.id IN (
      SELECT team_id FROM public.team_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create teams" ON public.teams
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Team owners can update team data" ON public.teams
  FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Team owners can delete teams" ON public.teams
  FOR DELETE USING (auth.uid() = owner_id);

-- Team members policies
CREATE POLICY "Users can view team members for their teams" ON public.team_members
  FOR SELECT USING (
    -- المستخدم هو مالك الفريق
    team_members.team_id IN (
      SELECT id FROM public.teams
      WHERE owner_id = auth.uid()
    )
    OR
    -- المستخدم هو عضو في الفريق
    team_members.team_id IN (
      SELECT team_id FROM public.team_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Team owners can manage team members" ON public.team_members
  FOR ALL USING (
    team_members.team_id IN (
      SELECT id FROM public.teams
      WHERE owner_id = auth.uid()
    )
  );

-- API Keys policies
CREATE POLICY "Users can view their own API keys" ON public.api_keys
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own API keys" ON public.api_keys
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own API keys" ON public.api_keys
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own API keys" ON public.api_keys
  FOR DELETE USING (auth.uid() = user_id);

-- Set up functions for analytics and team features
-- (These would need to be expanded based on specific requirements)

-- Function to get user's phone entry count
CREATE OR REPLACE FUNCTION get_user_entry_count(user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*) FROM public.phone_entries 
    WHERE phone_entries.user_id = get_user_entry_count.user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get team's phone entry count
CREATE OR REPLACE FUNCTION get_team_entry_count(team_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*) FROM public.phone_entries 
    WHERE phone_entries.user_id IN (
      SELECT user_id FROM public.team_members
      WHERE team_members.team_id = get_team_entry_count.team_id
      UNION
      SELECT owner_id FROM public.teams
      WHERE teams.id = get_team_entry_count.team_id
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set up Realtime
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;

-- Add tables to Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.phone_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.teams;
ALTER PUBLICATION supabase_realtime ADD TABLE public.team_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.api_keys; 