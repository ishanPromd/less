/*
  # Complete Database Schema Setup

  1. New Tables
    - `users` - User accounts and profiles
    - `papers` - Academic papers and study materials
    - `quizzes` - Quiz content with questions stored as JSONB
    - `quiz_attempts` - User quiz attempt records
    - `notifications` - User notifications system
    - `lessons` - Video lesson content
    - `app_texts` - Customizable application text content

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for each table
    - Ensure proper access control

  3. Data Types
    - Use JSONB for questions array to ensure proper JSON handling
    - Use proper foreign key relationships
    - Add appropriate indexes for performance
*/

-- Create users table if not exists
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  avatar_url text,
  role text DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create papers table if not exists
CREATE TABLE IF NOT EXISTS papers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  year integer NOT NULL,
  subject text NOT NULL,
  difficulty text NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  description text NOT NULL,
  content_url text NOT NULL,
  thumbnail_url text NOT NULL,
  access_level text DEFAULT 'free' CHECK (access_level IN ('free', 'premium')),
  parameters jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create quizzes table with JSONB questions column
CREATE TABLE IF NOT EXISTS quizzes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id uuid REFERENCES papers(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text NOT NULL,
  questions jsonb NOT NULL DEFAULT '[]',
  time_limit integer NOT NULL DEFAULT 30,
  passing_score integer NOT NULL DEFAULT 70,
  difficulty text NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  category text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create quiz_attempts table if not exists
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quiz_id uuid NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  responses jsonb NOT NULL DEFAULT '[]',
  score integer NOT NULL DEFAULT 0,
  total_points integer NOT NULL DEFAULT 0,
  time_spent integer NOT NULL DEFAULT 0,
  completed_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create notifications table if not exists
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('quiz_result', 'achievement', 'reminder', 'broadcast')),
  title text NOT NULL,
  message text NOT NULL,
  data jsonb DEFAULT '{}',
  priority text DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  read_status boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create lessons table if not exists
CREATE TABLE IF NOT EXISTS lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  youtube_url text NOT NULL,
  thumbnail_url text NOT NULL,
  category text NOT NULL,
  duration text DEFAULT '0:00',
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create app_texts table if not exists
CREATE TABLE IF NOT EXISTS app_texts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hero_title text,
  hero_subtitle text,
  featured_section_title text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_texts ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can read own profile" ON users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admin can read all users" ON users
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Papers policies
CREATE POLICY "Anyone can read papers" ON papers
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admin can insert papers" ON papers
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update papers" ON papers
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can delete papers" ON papers
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Quizzes policies
CREATE POLICY "Anyone can read quizzes" ON quizzes
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admin can insert quizzes" ON quizzes
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update quizzes" ON quizzes
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can delete quizzes" ON quizzes
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Quiz attempts policies
CREATE POLICY "Users can read own attempts" ON quiz_attempts
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own attempts" ON quiz_attempts
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin can read all attempts" ON quiz_attempts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Notifications policies
CREATE POLICY "Users can read own notifications" ON notifications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admin can insert notifications" ON notifications
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Lessons policies
CREATE POLICY "Anyone can read lessons" ON lessons
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admin can insert lessons" ON lessons
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update lessons" ON lessons
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can delete lessons" ON lessons
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- App texts policies
CREATE POLICY "Anyone can read app texts" ON app_texts
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admin can insert app texts" ON app_texts
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update app texts" ON app_texts
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DO $$
BEGIN
  -- Users table trigger
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_users_updated_at'
  ) THEN
    CREATE TRIGGER update_users_updated_at
      BEFORE UPDATE ON users
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- Papers table trigger
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_papers_updated_at'
  ) THEN
    CREATE TRIGGER update_papers_updated_at
      BEFORE UPDATE ON papers
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- Quizzes table trigger
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_quizzes_updated_at'
  ) THEN
    CREATE TRIGGER update_quizzes_updated_at
      BEFORE UPDATE ON quizzes
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- App texts table trigger
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_app_texts_updated_at'
  ) THEN
    CREATE TRIGGER update_app_texts_updated_at
      BEFORE UPDATE ON app_texts
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Insert default app texts if not exists
INSERT INTO app_texts (hero_title, hero_subtitle, featured_section_title)
SELECT 
  'Access Your Complete SFT Quiz Bank',
  'Comprehensive study materials and practice tests',
  'Featured Subjects 👆'
WHERE NOT EXISTS (SELECT 1 FROM app_texts);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_papers_subject ON papers(subject);
CREATE INDEX IF NOT EXISTS idx_papers_difficulty ON papers(difficulty);
CREATE INDEX IF NOT EXISTS idx_papers_created_at ON papers(created_at);
CREATE INDEX IF NOT EXISTS idx_quizzes_category ON quizzes(category);
CREATE INDEX IF NOT EXISTS idx_quizzes_difficulty ON quizzes(difficulty);
CREATE INDEX IF NOT EXISTS idx_quizzes_paper_id ON quizzes(paper_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user_id ON quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz_id ON quiz_attempts(quiz_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read_status ON notifications(read_status);
CREATE INDEX IF NOT EXISTS idx_lessons_category ON lessons(category);

-- Ensure questions column is JSONB type (fix for 0 questions issue)
DO $$
BEGIN
  -- Check if questions column exists and alter if needed
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quizzes' 
    AND column_name = 'questions' 
    AND data_type != 'jsonb'
  ) THEN
    -- Convert existing data to JSONB if column exists but wrong type
    ALTER TABLE quizzes ALTER COLUMN questions TYPE jsonb USING questions::jsonb;
  END IF;
END $$;