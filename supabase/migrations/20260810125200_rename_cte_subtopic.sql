-- Migration: Rename CTE subtopic to CTE & View & Function under SQL topic
-- Table: de_mobile_app."subtopics-legacy"
-- This migration is idempotent (safe to run multiple times)

SET search_path TO de_mobile_app;

UPDATE de_mobile_app."subtopics-legacy"
SET name = 'CTE & View & Function',
    description = 'Common Table Expressions, Views, and User-Defined Functions'
WHERE name = 'CTE'
  AND topic_id = (
    SELECT id FROM de_mobile_app."topics-legacy" WHERE name = 'SQL' LIMIT 1
  );
