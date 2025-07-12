/*
  # Lesson Request System

  1. New Tables
    - `lesson_requests` - User requests for lesson access
    - `user_lesson_access` - Approved lesson access for users

  2. Security
    - Enable RLS on all tables
    - Add policies for users to create requests and view their access
    - Add policies for admins to manage requests

  3. Features
    - Request tracking with status
    - Admin approval workflow
    - User access management
*/

-- Create lesson_requests table
CREATE TABLE IF NOT EXISTS lesson_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES subject_lessons(id) ON DELETE CASCADE,
  subject_id text NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  message text,
  admin_notes text,
  requested_at timestamptz DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create user_lesson_access table
CREATE TABLE IF NOT EXISTS user_lesson_access (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES subject_lessons(id) ON DELETE CASCADE,
  subject_id text NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  granted_at timestamptz DEFAULT now(),
  granted_by uuid REFERENCES auth.users(id),
  expires_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, lesson_id)
);

-- Enable RLS
ALTER TABLE lesson_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_lesson_access ENABLE ROW LEVEL SECURITY;

-- Lesson requests policies
CREATE POLICY "Users can read own lesson requests"
  ON lesson_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create lesson requests"
  ON lesson_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin can read all lesson requests"
  ON lesson_requests
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin can update lesson requests"
  ON lesson_requests
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- User lesson access policies
CREATE POLICY "Users can read own lesson access"
  ON user_lesson_access
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admin can manage lesson access"
  ON user_lesson_access
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_lesson_requests_user_id ON lesson_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_requests_status ON lesson_requests(status);
CREATE INDEX IF NOT EXISTS idx_lesson_requests_lesson_id ON lesson_requests(lesson_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_access_user_id ON user_lesson_access(user_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_access_lesson_id ON user_lesson_access(lesson_id);

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
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_lesson_requests_updated_at'
  ) THEN
    CREATE TRIGGER update_lesson_requests_updated_at
      BEFORE UPDATE ON lesson_requests
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;