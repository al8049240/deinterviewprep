-- Generic review system exposed through Supabase PostgREST.
CREATE TABLE IF NOT EXISTS de_mobile_app.review_targets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO de_mobile_app.review_targets (id, name)
VALUES ('de-interview-prep', 'DE Interview Prep')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS de_mobile_app.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_id TEXT NOT NULL REFERENCES de_mobile_app.review_targets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title TEXT CHECK (char_length(title) <= 120),
  comment TEXT NOT NULL CHECK (char_length(comment) BETWEEN 20 AND 1000),
  media_urls TEXT[] NOT NULL DEFAULT '{}',
  is_verified_use BOOLEAN NOT NULL DEFAULT true,
  status TEXT NOT NULL DEFAULT 'published'
    CHECK (status IN ('published', 'pending_moderation', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS reviews_target_created_idx
  ON de_mobile_app.reviews (target_id, created_at DESC);
CREATE INDEX IF NOT EXISTS reviews_user_created_idx
  ON de_mobile_app.reviews (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS de_mobile_app.review_votes (
  review_id UUID NOT NULL REFERENCES de_mobile_app.reviews(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  value SMALLINT NOT NULL CHECK (value IN (-1, 1)),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (review_id, user_id)
);

CREATE TABLE IF NOT EXISTS de_mobile_app.review_summaries (
  target_id TEXT PRIMARY KEY REFERENCES de_mobile_app.review_targets(id) ON DELETE CASCADE,
  average_rating NUMERIC(3,2) NOT NULL DEFAULT 0,
  total_reviews INTEGER NOT NULL DEFAULT 0,
  rating_breakdown JSONB NOT NULL DEFAULT '{"1":0,"2":0,"3":0,"4":0,"5":0}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION de_mobile_app.refresh_review_summary(p_target_id TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = de_mobile_app, public AS $$
BEGIN
  INSERT INTO review_summaries(target_id, average_rating, total_reviews, rating_breakdown, updated_at)
  SELECT p_target_id,
    COALESCE(round(avg(rating)::numeric, 2), 0),
    count(*)::integer,
    jsonb_build_object(
      '1', count(*) FILTER (WHERE rating = 1), '2', count(*) FILTER (WHERE rating = 2),
      '3', count(*) FILTER (WHERE rating = 3), '4', count(*) FILTER (WHERE rating = 4),
      '5', count(*) FILTER (WHERE rating = 5)
    ), now()
  FROM reviews WHERE target_id = p_target_id AND status = 'published'
  ON CONFLICT (target_id) DO UPDATE SET
    average_rating = EXCLUDED.average_rating, total_reviews = EXCLUDED.total_reviews,
    rating_breakdown = EXCLUDED.rating_breakdown, updated_at = now();
END; $$;

CREATE OR REPLACE FUNCTION de_mobile_app.handle_review_write()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = de_mobile_app, public AS $$
BEGIN
  IF TG_OP = 'INSERT' AND (
    SELECT count(*) FROM reviews
    WHERE user_id = NEW.user_id AND created_at >= now() - interval '1 hour'
  ) >= 5 THEN
    RAISE EXCEPTION 'Review rate limit exceeded';
  END IF;
  -- Never trust an eligibility flag supplied by the client. For this app,
  -- verified use means the account has completed at least one saved quiz.
  NEW.is_verified_use := EXISTS (
    SELECT 1 FROM quiz_attempts
    WHERE user_id = NEW.user_id
    LIMIT 1
  );
  IF NOT NEW.is_verified_use THEN
    RAISE EXCEPTION 'Complete at least one quiz before submitting a review';
  END IF;
  IF TG_OP = 'INSERT' THEN
    NEW.status := 'published';
  ELSE
    NEW.status := OLD.status;
  END IF;
  NEW.updated_at := now();
  IF NEW.comment ~* '(https?://){2,}|(.)\1{9,}' THEN
    NEW.status := 'pending_moderation';
  END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION de_mobile_app.handle_review_summary()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = de_mobile_app, public AS $$
BEGIN
  PERFORM refresh_review_summary(COALESCE(NEW.target_id, OLD.target_id));
  IF TG_OP = 'UPDATE' AND OLD.target_id <> NEW.target_id THEN
    PERFORM refresh_review_summary(OLD.target_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END; $$;

DROP TRIGGER IF EXISTS reviews_before_write ON de_mobile_app.reviews;
CREATE TRIGGER reviews_before_write BEFORE INSERT OR UPDATE ON de_mobile_app.reviews
FOR EACH ROW EXECUTE FUNCTION de_mobile_app.handle_review_write();
DROP TRIGGER IF EXISTS reviews_after_write ON de_mobile_app.reviews;
CREATE TRIGGER reviews_after_write AFTER INSERT OR UPDATE OR DELETE ON de_mobile_app.reviews
FOR EACH ROW EXECUTE FUNCTION de_mobile_app.handle_review_summary();

ALTER TABLE de_mobile_app.review_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app.review_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app.review_summaries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS review_targets_read ON de_mobile_app.review_targets;
DROP POLICY IF EXISTS review_summaries_read ON de_mobile_app.review_summaries;
DROP POLICY IF EXISTS reviews_read_published_or_own ON de_mobile_app.reviews;
DROP POLICY IF EXISTS reviews_insert_own ON de_mobile_app.reviews;
DROP POLICY IF EXISTS reviews_update_own ON de_mobile_app.reviews;
DROP POLICY IF EXISTS reviews_delete_own_or_admin ON de_mobile_app.reviews;
DROP POLICY IF EXISTS review_votes_read ON de_mobile_app.review_votes;
DROP POLICY IF EXISTS review_votes_own ON de_mobile_app.review_votes;

CREATE POLICY review_targets_read ON de_mobile_app.review_targets FOR SELECT USING (true);
CREATE POLICY review_summaries_read ON de_mobile_app.review_summaries FOR SELECT USING (true);
CREATE POLICY reviews_read_published_or_own ON de_mobile_app.reviews FOR SELECT
  USING (status = 'published' OR auth.uid() = user_id);
CREATE POLICY reviews_insert_own ON de_mobile_app.reviews FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY reviews_update_own ON de_mobile_app.reviews FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY reviews_delete_own_or_admin ON de_mobile_app.reviews FOR DELETE TO authenticated
  USING (auth.uid() = user_id OR (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY review_votes_read ON de_mobile_app.review_votes FOR SELECT USING (true);
CREATE POLICY review_votes_own ON de_mobile_app.review_votes FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

GRANT SELECT ON de_mobile_app.review_targets, de_mobile_app.review_summaries TO anon, authenticated;
GRANT SELECT ON de_mobile_app.reviews TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON de_mobile_app.reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON de_mobile_app.review_votes TO authenticated;

SELECT de_mobile_app.refresh_review_summary('de-interview-prep');
