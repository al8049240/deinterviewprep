-- Performance optimization: Add indexes on frequently filtered columns
-- in de_mobile_app."quiz-question" to avoid full table scans.
-- The table has 3,211 rows and is filtered by topic, sub_topics, and difficulty
-- on every quiz load, subtopic count fetch, and custom quiz builder call.

-- Index on topic (integer FK → topics-legacy.id)
-- Used by: fetchQuestionsByTopicId, fetchTopicQuestionCountById, fetchTopicQuestionCounts
CREATE INDEX IF NOT EXISTS idx_quiz_question_topic
  ON de_mobile_app."quiz-question" (topic);

-- Index on sub_topics (integer FK → subtopics-legacy.id)
-- Used by: fetchQuestionsBySubtopicId, fetchSubtopicQuestionCount
CREATE INDEX IF NOT EXISTS idx_quiz_question_sub_topics
  ON de_mobile_app."quiz-question" (sub_topics);

-- Index on difficulty (text)
-- Used by future difficulty-filtered queries and the custom quiz builder
CREATE INDEX IF NOT EXISTS idx_quiz_question_difficulty
  ON de_mobile_app."quiz-question" (difficulty);

-- Composite index for the most common combined filter: topic + sub_topics
-- Covers queries that filter by both at once (subtopic drill-down)
CREATE INDEX IF NOT EXISTS idx_quiz_question_topic_subtopic
  ON de_mobile_app."quiz-question" (topic, sub_topics);

-- Index on quiz-answer.question_id for fast answer lookups during quiz loading
-- Used by: _buildModelsFromQuestionData (inFilter on question_id)
CREATE INDEX IF NOT EXISTS idx_quiz_answer_question_id
  ON de_mobile_app."quiz-answer" (question_id);
