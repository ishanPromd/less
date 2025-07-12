/*
  # Create app_texts table

  1. New Tables
    - `app_texts`
      - `id` (uuid, primary key)
      - `hero_title` (text)
      - `hero_subtitle` (text)
      - `featured_section_title` (text)
      - `created_by` (uuid, foreign key to users)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `app_texts` table
    - Add policies for authenticated users to read and admin users to write
*/

CREATE TABLE IF NOT EXISTS app_texts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hero_title text NOT NULL DEFAULT 'Access Your Complete SFT Quiz Bank',
  hero_subtitle text NOT NULL DEFAULT 'Comprehensive study materials and practice tests',
  featured_section_title text NOT NULL DEFAULT 'Featured Subjects 👆',
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE app_texts ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read app texts
CREATE POLICY "Anyone can read app texts"
  ON app_texts
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to insert app texts
CREATE POLICY "Authenticated users can insert app texts"
  ON app_texts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Allow users to update their own app texts
CREATE POLICY "Users can update own app texts"
  ON app_texts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- Insert default app texts
INSERT INTO app_texts (hero_title, hero_subtitle, featured_section_title)
VALUES (
  'Access Your Complete SFT Quiz Bank',
  'Comprehensive study materials and practice tests',
  'Featured Subjects 👆'
) ON CONFLICT DO NOTHING;