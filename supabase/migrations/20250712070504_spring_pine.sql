/*
  # Add position column to lesson_videos table

  1. Changes
    - Add `position` column to `lesson_videos` table for video ordering
    - Set default value to 0
    - Add index for better performance

  2. Security
    - No changes to RLS policies needed
*/

-- Add position column to lesson_videos table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lesson_videos' 
    AND column_name = 'position'
  ) THEN
    ALTER TABLE lesson_videos ADD COLUMN position integer DEFAULT 0;
  END IF;
END $$;

-- Create index for position column
CREATE INDEX IF NOT EXISTS idx_lesson_videos_position ON lesson_videos(position);

-- Update existing videos to have sequential positions within each lesson
DO $$
DECLARE
  lesson_record RECORD;
  video_record RECORD;
  pos INTEGER;
BEGIN
  FOR lesson_record IN SELECT DISTINCT lesson_id FROM lesson_videos LOOP
    pos := 0;
    FOR video_record IN 
      SELECT id FROM lesson_videos 
      WHERE lesson_id = lesson_record.lesson_id 
      ORDER BY created_at ASC 
    LOOP
      UPDATE lesson_videos 
      SET position = pos 
      WHERE id = video_record.id;
      pos := pos + 1;
    END LOOP;
  END LOOP;
END $$;