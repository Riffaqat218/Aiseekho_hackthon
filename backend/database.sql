-- Create a table for public user profiles linked to Supabase auth
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
  email TEXT UNIQUE NOT NULL
);

-- Enable Row Level Security (RLS) for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own profile." ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Create a trigger to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Create table for conversations (chat sessions)
CREATE TABLE public.conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT DEFAULT 'New Conversation',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- RLS for conversations
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own conversations." ON public.conversations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own conversations." ON public.conversations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own conversations." ON public.conversations FOR DELETE USING (auth.uid() = user_id);

-- Create table for messages within a conversation
CREATE TABLE public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'ai', 'system')),
  content TEXT NOT NULL,
  tokens_used INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- RLS for messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own messages." ON public.messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.conversations c WHERE c.id = public.messages.conversation_id AND c.user_id = auth.uid()
  )
);
CREATE POLICY "Users can insert their own messages." ON public.messages FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.conversations c WHERE c.id = public.messages.conversation_id AND c.user_id = auth.uid()
  )
);

-- Create table for Student Profiles
CREATE TABLE public.student_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  university TEXT,
  cgpa NUMERIC(3,2),
  field_of_study TEXT,
  degree_level TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- RLS for student_profiles
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own profile." ON public.student_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile." ON public.student_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON public.student_profiles FOR UPDATE USING (auth.uid() = id);

-- Create table for Scholarships
CREATE TABLE public.scholarships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  min_cgpa NUMERIC(3,2) NOT NULL,
  required_degree TEXT NOT NULL,
  required_documents TEXT[] NOT NULL,
  deadline TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- Enable RLS for scholarships (public read, admin write)
ALTER TABLE public.scholarships ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view scholarships." ON public.scholarships FOR SELECT USING (true);

-- Seed Scholarships Table (15+ real matched scholarships categorized by country)
INSERT INTO public.scholarships (name, country, min_cgpa, required_degree, required_documents, deadline) VALUES
-- Local / Pakistan
('HEC Need-Based Scholarship', 'Pakistan', 2.00, 'Bachelor', ARRAY['Transcript', 'Income Certificate', 'CNIC Copy'], '2026-06-30'),
('PEEF Master''s Level Scholarship', 'Pakistan', 2.50, 'Master', ARRAY['Transcript', 'Domicile', 'Income Certificate'], '2026-08-15'),
('Ehsaas Undergraduate Scholarship', 'Pakistan', 2.00, 'Bachelor', ARRAY['Transcript', 'Admission Letter', 'CNIC Copy'], '2026-07-31'),
('HEC Indigenous PhD Fellowship', 'Pakistan', 3.00, 'PhD', ARRAY['Transcript', 'Research Proposal', 'Domicile'], '2026-09-30'),
('Fauji Foundation Excellence Award', 'Pakistan', 2.50, 'Bachelor', ARRAY['Transcript', 'Fauji Card Copy', 'Domicile'], '2026-08-31'),

-- USA
('Fulbright Foreign Student Program', 'USA', 3.00, 'Master', ARRAY['Transcript', 'GRE Score', '3 Recommendation Letters', 'TOEFL Score'], '2026-10-15'),
('Hubert H. Humphrey Fellowship', 'USA', 3.00, 'Master', ARRAY['Transcript', 'TOEFL Score', '5 Years Work Exp Certificate', '2 Recommendation Letters'], '2026-11-01'),
('Global UGRAD Exchange Program', 'USA', 2.50, 'Bachelor', ARRAY['Transcript', 'Personal Statement', 'Recommendation Letter'], '2026-12-15'),
('AAUW International Fellowships', 'USA', 3.00, 'Master', ARRAY['Transcript', 'Research Proposal', 'TOEFL Score', '2 Letters of Recommendation'], '2026-11-15'),

-- Germany
('DAAD Development-Related Postgraduate Courses', 'Germany', 2.70, 'Master', ARRAY['Transcript', 'IELTS Score', '2 Years Work Exp Certificate', 'Motivation Letter'], '2026-10-31'),
('Heinrich Böll Foundation Scholarships', 'Germany', 3.00, 'Master', ARRAY['Transcript', 'German Language Certificate', 'Motivation Letter', 'Recommendation Letter'], '2026-09-01'),
('KAAD Scholarship Program', 'Germany', 2.80, 'Master', ARRAY['Transcript', 'Church/NGO Recommendation', 'Motivation Letter'], '2026-11-30'),

-- United Kingdom
('Commonwealth Master''s Scholarships', 'UK', 3.00, 'Master', ARRAY['Transcript', 'IELTS Score', '3 Recommendation Letters', 'Offer Letter'], '2026-12-01'),
('Chevening Scholarships', 'UK', 3.00, 'Master', ARRAY['Transcript', 'IELTS Score', '2 Years Work Exp Certificate', '2 Recommendation Letters'], '2026-11-05'),
('Gates Cambridge Scholarship', 'UK', 3.50, 'PhD', ARRAY['Transcript', 'Gates Reference', 'Research Proposal', 'IELTS Score'], '2026-10-10');

-- Create table for Action Traces (for Antigravity execution tracking)
CREATE TABLE public.action_traces (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  step TEXT NOT NULL,
  reasoning TEXT NOT NULL,
  tool_called TEXT,
  result TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- RLS for action_traces
ALTER TABLE public.action_traces ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own traces." ON public.action_traces FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own traces." ON public.action_traces FOR INSERT WITH CHECK (auth.uid() = user_id);

