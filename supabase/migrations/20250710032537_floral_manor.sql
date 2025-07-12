/*
  # Create missing database tables for feed functionality

  1. New Tables
    - `subjects` - Subject categories for organizing content
    - `subject_lessons` - Lessons within each subject
    - `lesson_videos` - Videos within each lesson

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for read/write access

  3. Data Structure
    - Hierarchical organization: subjects -> lessons -> videos
    - Proper UUID handling and foreign key relationships
*/

-- Create subjects table
CREATE TABLE IF NOT EXISTS subjects (
  id text PRIMARY KEY,
  name text NOT NULL,
  description text NOT NULL,
  icon text NOT NULL,
  color text NOT NULL,
  image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create subject_lessons table
CREATE TABLE IF NOT EXISTS subject_lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  subject_id text NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  thumbnail_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create lesson_videos table
CREATE TABLE IF NOT EXISTS lesson_videos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  youtube_url text NOT NULL,
  thumbnail_url text,
  duration text DEFAULT '0:00',
  lesson_id uuid NOT NULL REFERENCES subject_lessons(id) ON DELETE CASCADE,
  subject_id text NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create app_texts table if it doesn't exist
CREATE TABLE IF NOT EXISTS app_texts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text UNIQUE NOT NULL,
  value text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Enable RLS on all tables
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_texts ENABLE ROW LEVEL SECURITY;

-- Subjects policies
CREATE POLICY IF NOT EXISTS "Anyone can read subjects" ON subjects
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Admin can insert subjects" ON subjects
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY IF NOT EXISTS "Admin can update subjects" ON subjects
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY IF NOT EXISTS "Admin can delete subjects" ON subjects
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Subject lessons policies
CREATE POLICY IF NOT EXISTS "Anyone can read subject lessons" ON subject_lessons
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Admin can insert subject lessons" ON subject_lessons
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY IF NOT EXISTS "Admin can update subject lessons" ON subject_lessons
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY IF NOT EXISTS "Admin can delete subject lessons" ON subject_lessons
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Lesson videos policies
CREATE POLICY IF NOT EXISTS "Anyone can read lesson videos" ON lesson_videos
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Admin can insert lesson videos" ON lesson_videos
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY IF NOT EXISTS "Admin can update lesson videos" ON lesson_videos
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY IF NOT EXISTS "Admin can delete lesson videos" ON lesson_videos
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- App texts policies
CREATE POLICY IF NOT EXISTS "Anyone can read app texts" ON app_texts
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Admin can manage app texts" ON app_texts
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Insert default subjects
INSERT INTO subjects (id, name, description, icon, color, image_url) VALUES
  ('sft', 'SFT', 'Science for Technology - Core scientific principles', '🔬', 'from-green-500 to-emerald-600', 'https://images.pexels.com/photos/2280571/pexels-photo-2280571.jpeg'),
  ('et', 'ET', 'Engineering Technology - Applied engineering concepts', '⚙️', 'from-orange-500 to-amber-600', 'https://images.pexels.com/photos/159298/gears-cogs-machine-machinery-159298.jpeg'),
  ('ict', 'ICT', 'Information & Communication Technology', '💻', 'from-blue-500 to-indigo-600', 'https://images.pexels.com/photos/546819/pexels-photo-546819.jpeg')
ON CONFLICT (id) DO NOTHING;

-- Insert default app texts
INSERT INTO app_texts (key, value, description) VALUES
  ('hero_title', 'Access Your Complete SFT Quiz Bank', 'Main hero section title'),
  ('hero_subtitle', 'Comprehensive study materials and practice tests', 'Hero section subtitle'),
  ('featured_section_title', 'Featured Subjects 👆', 'Featured section title')
ON CONFLICT (key) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_subject_lessons_subject_id ON subject_lessons(subject_id);
CREATE INDEX IF NOT EXISTS idx_lesson_videos_lesson_id ON lesson_videos(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_videos_subject_id ON lesson_videos(subject_id);
CREATE INDEX IF NOT EXISTS idx_app_texts_key ON app_texts(key);