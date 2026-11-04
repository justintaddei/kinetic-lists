DROP POLICY "Users can delete their own todos" ON "public"."todos";

DROP POLICY "Users can insert their own todos" ON "public"."todos";

DROP POLICY "Users can read their own todos" ON "public"."todos";

DROP POLICY "Users can update their own todos" ON "public"."todos";

CREATE POLICY "Users can delete their own todos" ON "public"."todos"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "Users can insert their own todos" ON "public"."todos"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "Users can read their own todos" ON "public"."todos"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "Users can update their own todos" ON "public"."todos"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
