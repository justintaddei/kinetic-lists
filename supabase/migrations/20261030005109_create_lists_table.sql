CREATE TABLE "public"."lists" (
  "id"   bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "name" text   NOT NULL,
  CONSTRAINT "lists_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."lists"
  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lists_full_access_for_authenticated" ON "public"."lists"
  FOR ALL
  TO "authenticated"
  USING (true)
  WITH CHECK (true);

REVOKE ALL ON SEQUENCE "public"."lists_id_seq" FROM "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."lists_id_seq" TO "anon";

REVOKE ALL ON SEQUENCE "public"."lists_id_seq" FROM "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."lists_id_seq" TO "authenticated";

REVOKE ALL ON SEQUENCE "public"."lists_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."lists_id_seq" TO "postgres";

REVOKE ALL ON SEQUENCE "public"."lists_id_seq" FROM "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."lists_id_seq" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."lists" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "service_role";
