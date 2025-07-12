/*
  # Create Feed System Tables

  1. New Tables
    - `subjects` - Learning subjects (SFT, ET, ICT)
    - `subject_lessons` - Lessons within subjects
    - `lesson_videos` - Videos within lessons

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to read
    - Add policies for admin users to manage content

  3. Relationships
    - subjects -> subject_lessons (one-to-many)
    - subject_lessons -> lesson_videos (one-to-many)
*/

-- Create subjects table
CREATE TABLE IF NOT EXISTS subjects (
  id text PRIMARY KEY,
  name text NOT NULL,
  description text NOT NULL,
  icon text NOT NULL DEFAULT '📚',
  color text NOT NULL DEFAULT 'from-blue-500 to-indigo-600',
  image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create subject_lessons table
CREATE TABLE IF NOT EXISTS subject_lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id text NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text NOT NULL,
  thumbnail_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Create lesson_videos table
CREATE TABLE IF NOT EXISTS lesson_videos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id uuid NOT NULL REFERENCES subject_lessons(id) ON DELETE CASCADE,
  subject_id text NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text NOT NULL,
  youtube_url text NOT NULL,
  thumbnail_url text NOT NULL,
  duration text DEFAULT '0:00',
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_videos ENABLE ROW LEVEL SECURITY;

-- Subjects policies
CREATE POLICY "Anyone can read subjects"
  ON subjects
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin can insert subjects"
  ON subjects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update subjects"
  ON subjects
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can delete subjects"
  ON subjects
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Subject lessons policies
CREATE POLICY "Anyone can read subject lessons"
  ON subject_lessons
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin can insert subject lessons"
  ON subject_lessons
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update subject lessons"
  ON subject_lessons
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can delete subject lessons"
  ON subject_lessons
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Lesson videos policies
CREATE POLICY "Anyone can read lesson videos"
  ON lesson_videos
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin can insert lesson videos"
  ON lesson_videos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update lesson videos"
  ON lesson_videos
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can delete lesson videos"
  ON lesson_videos
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_subject_lessons_subject_id ON subject_lessons(subject_id);
CREATE INDEX IF NOT EXISTS idx_lesson_videos_lesson_id ON lesson_videos(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_videos_subject_id ON lesson_videos(subject_id);

-- Insert default subjects
INSERT INTO subjects (id, name, description, icon, color, image_url) VALUES
  ('sft', 'SFT', 'Science for Technology - Core scientific principles', '🔬', 'from-green-500 to-emerald-600', 'https://images.pexels.com/photos/2280571/pexels-photo-2280571.jpeg'),
  ('et', 'ET', 'Engineering Technology - Applied engineering concepts', '⚙️', 'from-orange-500 to-amber-600', 'https://images.pexels.com/photos/159298/gears-cogs-machine-machinery-159298.jpeg'),
  ('ict', 'ICT', 'Information & Communication Technology', '💻', 'from-blue-500 to-indigo-600', 'https://images.pexels.com/photos/546819/pexels-photo-546819.jpeg')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon,
  color = EXCLUDED.color,
  image_url = EXCLUDED.image_url,
  updated_at = now();

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
  -- Subjects table trigger
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_subjects_updated_at'
  ) THEN
    CREATE TRIGGER update_subjects_updated_at
      BEFORE UPDATE ON subjects
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- Subject lessons table trigger
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_subject_lessons_updated_at'
  ) THEN
    CREATE TRIGGER update_subject_lessons_updated_at
      BEFORE UPDATE ON subject_lessons
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;