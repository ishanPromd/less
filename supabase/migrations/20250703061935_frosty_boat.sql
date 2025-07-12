/*
  # Create storage buckets and policies

  1. Storage Buckets
    - `question-images` for storing question images

  2. Security
    - Allow authenticated users to upload images
    - Allow public access to read images
*/

-- Create question-images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'question-images',
  'question-images',
  true,
  5242880,
  ARRAY['image/*']
) ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload question images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'question-images');

-- Allow authenticated users to update their own images
CREATE POLICY "Users can update own question images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'question-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow authenticated users to delete their own images
CREATE POLICY "Users can delete own question images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'question-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow public access to read images
CREATE POLICY "Public can view question images"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'question-images');