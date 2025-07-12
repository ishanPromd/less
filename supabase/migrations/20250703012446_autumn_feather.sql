/*
  # Create app_texts table for customizable application texts

  1. New Tables
    - `app_texts`
      - `id` (uuid, primary key)
      - `hero_title` (text, nullable)
      - `hero_subtitle` (text, nullable) 
      - `featured_section_title` (text, nullable)
      - `created_at` (timestamp with time zone)
      - `updated_at` (timestamp with time zone)
      - `created_by` (uuid, references users)

  2. Security
    - Enable RLS on `app_texts` table
    - Add policy for authenticated users to read app texts
    - Add policy for admin users to insert/update app texts

  3. Functions
    - Add trigger to automatically update `updated_at` timestamp
*/

-- Create app_texts table
CREATE TABLE IF NOT EXISTS app_texts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hero_title text,
  hero_subtitle text,
  featured_section_title text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE app_texts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read app texts"
  ON app_texts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can insert app texts"
  ON app_texts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admin users can update app texts"
  ON app_texts
  FOR UPDATE
  TO authenticated
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

-- Create trigger for updated_at
DO $$
BEGIN
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

-- Insert default app texts
INSERT INTO app_texts (hero_title, hero_subtitle, featured_section_title)
VALUES (
  'Access Your Complete SFT Quiz Bank',
  'Comprehensive study materials and practice tests',
  'Featured Subjects 👆'
) ON CONFLICT DO NOTHING;