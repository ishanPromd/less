/*
  # Create app_texts table for customizable application text content

  1. New Tables
    - `app_texts`
      - `id` (uuid, primary key)
      - `hero_title` (text) - Main hero section title
      - `hero_subtitle` (text) - Hero section subtitle
      - `featured_section_title` (text) - Featured section title
      - `created_by` (uuid) - References auth.users(id)
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp

  2. Security
    - Enable RLS on `app_texts` table
    - Add policy for authenticated users to read app texts
    - Add policy for authenticated users to insert app texts

  3. Initial Data
    - Insert default text content for the application
*/

CREATE TABLE IF NOT EXISTS app_texts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hero_title text DEFAULT 'Access Your Complete SFT Quiz Bank',
  hero_subtitle text DEFAULT 'Comprehensive study materials and practice tests',
  featured_section_title text DEFAULT 'Featured Subjects 👆',
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE app_texts ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Anyone can read app texts"
  ON app_texts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can insert app texts"
  ON app_texts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY IF NOT EXISTS "Users can update their own app texts"
  ON app_texts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- Insert default app text content if none exists
INSERT INTO app_texts (hero_title, hero_subtitle, featured_section_title)
SELECT 
  'Access Your Complete SFT Quiz Bank',
  'Comprehensive study materials and practice tests',
  'Featured Subjects 👆'
WHERE NOT EXISTS (SELECT 1 FROM app_texts);