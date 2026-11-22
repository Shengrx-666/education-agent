-- education-agent V2 expansion design, 2026-11-20; Validated only in an isolated stub test database; never applied to production.
-- Target PostgreSQL >= 14; LearnHouse c76cf6f64ab71ed042fe83e985d9c4ab3fa148f5.
-- Run only after upstream Alembic migration; a migration owner is required.
-- All upstream keys are INTEGER, not UUID. ea UUIDs are new extension keys.
-- This file is a one-time transaction, deliberately NOT an IF NOT EXISTS migration.
BEGIN;
SET LOCAL TIME ZONE 'UTC';
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '120s';
DO $$
DECLARE t text;
BEGIN
  IF current_setting('server_version_num')::int < 140000 THEN
    RAISE EXCEPTION 'PostgreSQL >=14 required';
  END IF;
  FOREACH t IN ARRAY ARRAY['organization','user','course','activity','assignment','usergroup','userorganization','usergroupuser','usergroupresource','learner_note'] LOOP
    IF to_regclass('public.' || quote_ident(t)) IS NULL THEN
      RAISE EXCEPTION 'Missing upstream table: %; migrate LearnHouse first', t;
    END IF;
  END LOOP;
END $$;
CREATE SCHEMA ea;
REVOKE ALL ON SCHEMA ea FROM PUBLIC;
-- Additive upstream indexes only: provide exact composite FK targets, no data rewrite.
-- Existing PKs make these unique; fail before proceeding if org/course columns are corrupt.
CREATE UNIQUE INDEX ea_uq_course_scope ON public.course (id, org_id);
CREATE UNIQUE INDEX ea_uq_activity_scope ON public.activity (id, course_id, org_id);
CREATE UNIQUE INDEX ea_uq_assignment_scope ON public.assignment (id, course_id, org_id);
CREATE UNIQUE INDEX ea_uq_group_scope ON public.usergroup (id, org_id);
CREATE UNIQUE INDEX ea_uq_note_scope ON public.learner_note (id, user_id, course_id, org_id);

CREATE TABLE ea.principal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL REFERENCES public.organization(id) ON DELETE RESTRICT,
  kind text NOT NULL CHECK (kind IN ('human','service')),
  user_id integer REFERENCES public."user"(id) ON DELETE RESTRICT,
  service_name text,
  disabled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, org_id),
  CHECK ((kind = 'human' AND user_id IS NOT NULL AND service_name IS NULL) OR
         (kind = 'service' AND user_id IS NULL AND service_name IS NOT NULL AND length(service_name) > 0))
);
CREATE UNIQUE INDEX uq_principal_human ON ea.principal(org_id,user_id) WHERE kind='human';
CREATE UNIQUE INDEX uq_principal_service ON ea.principal(org_id,service_name) WHERE kind='service';

CREATE TABLE ea.action_grant (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL REFERENCES public.organization(id) ON DELETE RESTRICT,
  principal_id uuid NOT NULL,
  course_id integer,
  usergroup_id integer,
  student_id integer REFERENCES public."user"(id) ON DELETE RESTRICT,
  action text NOT NULL CHECK (action IN ('course.create','course.edit','content.read','content.generate','content.edit','content.review','content.publish','task.manage','submission.grade','result.review','profile.read','intervention.write','evidence.read','export.read','access.manage','policy.manage','operations.manage','audit.metadata')),
  granted_by uuid NOT NULL,
  approved_by uuid NOT NULL,
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  starts_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  revoked_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (principal_id,org_id) REFERENCES ea.principal(id,org_id),
  FOREIGN KEY (granted_by,org_id) REFERENCES ea.principal(id,org_id),
  FOREIGN KEY (approved_by,org_id) REFERENCES ea.principal(id,org_id),
  FOREIGN KEY (revoked_by,org_id) REFERENCES ea.principal(id,org_id),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  FOREIGN KEY (usergroup_id,org_id) REFERENCES public.usergroup(id,org_id),
  CHECK (approved_by <> principal_id),
  CHECK (course_id IS NOT NULL OR action IN ('course.create','access.manage','policy.manage','operations.manage','audit.metadata')),
  CHECK ((usergroup_id IS NULL AND student_id IS NULL) OR course_id IS NOT NULL),
  CHECK (expires_at IS NULL OR expires_at > starts_at),
  CHECK ((revoked_at IS NULL) = (revoked_by IS NULL)),
  CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);
CREATE INDEX ix_grant_active_lookup ON ea.action_grant(org_id,principal_id,action,course_id) WHERE revoked_at IS NULL;

CREATE TABLE ea.policy_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL REFERENCES public.organization(id) ON DELETE RESTRICT,
  course_id integer,
  family_id uuid NOT NULL,
  version integer NOT NULL CHECK (version > 0),
  parent_policy_id uuid,
  policy_type text NOT NULL CHECK (policy_type IN ('global','course')),
  rules jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(rules)='object'),
  content_hash text NOT NULL CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,org_id),
  UNIQUE (org_id,family_id,version),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  FOREIGN KEY (parent_policy_id,org_id) REFERENCES ea.policy_version(id,org_id),
  FOREIGN KEY (created_by,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((policy_type='global' AND course_id IS NULL AND parent_policy_id IS NULL) OR
         (policy_type='course' AND course_id IS NOT NULL AND parent_policy_id IS NOT NULL))
);

CREATE TABLE ea.task_run (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL REFERENCES public.organization(id) ON DELETE RESTRICT,
  course_id integer,
  requested_by uuid NOT NULL,
  operation text NOT NULL CHECK (operation IN ('parse','generate','validate','evaluate','profile_update','recommend','recompute','projection')),
  idempotency_key text NOT NULL CHECK (length(idempotency_key) BETWEEN 1 AND 200),
  input_hash text NOT NULL CHECK (input_hash ~ '^[0-9a-f]{64}$'),
  input_refs jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(input_refs)='object'),
  result_refs jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(result_refs)='object'),
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','succeeded','failed','cancelled')),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  max_attempts integer NOT NULL DEFAULT 3 CHECK (max_attempts BETWEEN 1 AND 10),
  execution_epoch bigint NOT NULL DEFAULT 0 CHECK (execution_epoch >= 0),
  lease_until timestamptz,
  not_before timestamptz NOT NULL DEFAULT now(),
  error_code text,
  budget_limit numeric(14,6) NOT NULL DEFAULT 0 CHECK (budget_limit >= 0),
  budget_spent numeric(14,6) NOT NULL DEFAULT 0 CHECK (budget_spent >= 0 AND budget_spent <= budget_limit),
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,org_id),
  UNIQUE (id,course_id,org_id),
  UNIQUE (org_id,requested_by,operation,idempotency_key),
  FOREIGN KEY (requested_by,org_id) REFERENCES ea.principal(id,org_id),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  CHECK (attempt_count <= max_attempts),
  CHECK ((status='cancelled') = (cancelled_at IS NOT NULL)),
  CHECK (status <> 'running' OR lease_until IS NOT NULL)
);
CREATE INDEX ix_task_claim ON ea.task_run(not_before,created_at) WHERE status IN ('queued','running');
CREATE INDEX ix_task_course ON ea.task_run(org_id,course_id,status,created_at DESC);

CREATE TABLE ea.knowledge_point (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  code text NOT NULL,
  version integer NOT NULL DEFAULT 1 CHECK (version > 0),
  label text NOT NULL,
  definition jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(definition)='object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,course_id,org_id),
  UNIQUE (org_id,course_id,code,version),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id)
);

CREATE TABLE ea.resource (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  activity_id integer,
  kind text NOT NULL CHECK (kind IN ('source_text','source_pdf','lesson','exercise')),
  title text NOT NULL,
  owner_id uuid NOT NULL,
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,course_id,org_id),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  FOREIGN KEY (activity_id,course_id,org_id) REFERENCES public.activity(id,course_id,org_id),
  FOREIGN KEY (owner_id,org_id) REFERENCES ea.principal(id,org_id)
);

CREATE TABLE ea.resource_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  resource_id uuid NOT NULL,
  version integer NOT NULL CHECK (version > 0),
  previous_version_id uuid,
  source_version_id uuid,
  generation_task_id uuid,
  policy_version_id uuid NOT NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(content)='object'),
  restricted_content jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(restricted_content)='object'),
  object_key text,
  content_hash text NOT NULL CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  processing_state text NOT NULL CHECK (processing_state IN ('pending','ready','failed')),
  generation_mode text NOT NULL CHECK (generation_mode IN ('upload','teacher','research_generator','rule_template')),
  provenance text NOT NULL CHECK (provenance IN ('real','demo','manual_example','simulated','external')),
  source_manifest jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(source_manifest)='object'),
  forced_review boolean NOT NULL DEFAULT true,
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,course_id,org_id),
  UNIQUE (id,resource_id,course_id,org_id),
  UNIQUE (resource_id,version),
  FOREIGN KEY (resource_id,course_id,org_id) REFERENCES ea.resource(id,course_id,org_id),
  FOREIGN KEY (previous_version_id,resource_id,course_id,org_id) REFERENCES ea.resource_version(id,resource_id,course_id,org_id),
  FOREIGN KEY (source_version_id,course_id,org_id) REFERENCES ea.resource_version(id,course_id,org_id),
  FOREIGN KEY (generation_task_id,course_id,org_id) REFERENCES ea.task_run(id,course_id,org_id),
  FOREIGN KEY (policy_version_id,org_id) REFERENCES ea.policy_version(id,org_id),
  FOREIGN KEY (created_by,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((version=1 AND previous_version_id IS NULL) OR (version>1 AND previous_version_id IS NOT NULL)),
  CHECK (previous_version_id IS NULL OR previous_version_id <> id),
  CHECK (source_version_id IS NULL OR source_version_id <> id),
  CHECK (generation_mode <> 'research_generator' OR forced_review)
);

CREATE TABLE ea.rubric_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  family_id uuid NOT NULL,
  version integer NOT NULL CHECK (version > 0),
  criteria jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(criteria)='array'),
  maximum_score numeric(10,4) NOT NULL CHECK (maximum_score > 0),
  content_hash text NOT NULL CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,course_id,org_id),
  UNIQUE (org_id,course_id,family_id,version),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  FOREIGN KEY (created_by,org_id) REFERENCES ea.principal(id,org_id)
);

CREATE TABLE ea.content_check (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  resource_version_id uuid NOT NULL,
  policy_version_id uuid NOT NULL,
  task_id uuid,
  check_kind text NOT NULL CHECK (check_kind IN ('deterministic','human_review')),
  verdict text NOT NULL CHECK (verdict IN ('pass','fail','approve','reject')),
  checks jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(checks)='object'),
  checker_version text NOT NULL,
  actor_id uuid NOT NULL,
  reason text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,resource_version_id,course_id,org_id),
  FOREIGN KEY (resource_version_id,course_id,org_id) REFERENCES ea.resource_version(id,course_id,org_id),
  FOREIGN KEY (policy_version_id,org_id) REFERENCES ea.policy_version(id,org_id),
  FOREIGN KEY (task_id,course_id,org_id) REFERENCES ea.task_run(id,course_id,org_id),
  FOREIGN KEY (actor_id,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((check_kind='deterministic' AND verdict IN ('pass','fail')) OR
         (check_kind='human_review' AND verdict IN ('approve','reject') AND length(btrim(reason)) > 0))
);
CREATE INDEX ix_check_version ON ea.content_check(resource_version_id,created_at DESC);

CREATE TABLE ea.publication_event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  resource_version_id uuid NOT NULL,
  usergroup_id integer NOT NULL,
  event_no integer NOT NULL CHECK (event_no > 0),
  previous_event_id uuid,
  action text NOT NULL CHECK (action IN ('publish','withdraw')),
  validation_id uuid,
  review_id uuid,
  policy_version_id uuid NOT NULL,
  actor_id uuid NOT NULL,
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,course_id,org_id),
  UNIQUE (id,resource_version_id,usergroup_id,course_id,org_id),
  UNIQUE (resource_version_id,usergroup_id,event_no),
  UNIQUE (previous_event_id),
  FOREIGN KEY (resource_version_id,course_id,org_id) REFERENCES ea.resource_version(id,course_id,org_id),
  FOREIGN KEY (usergroup_id,org_id) REFERENCES public.usergroup(id,org_id),
  FOREIGN KEY (previous_event_id,resource_version_id,usergroup_id,course_id,org_id) REFERENCES ea.publication_event(id,resource_version_id,usergroup_id,course_id,org_id),
  FOREIGN KEY (validation_id,resource_version_id,course_id,org_id) REFERENCES ea.content_check(id,resource_version_id,course_id,org_id),
  FOREIGN KEY (review_id,resource_version_id,course_id,org_id) REFERENCES ea.content_check(id,resource_version_id,course_id,org_id),
  FOREIGN KEY (policy_version_id,org_id) REFERENCES ea.policy_version(id,org_id),
  FOREIGN KEY (actor_id,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((event_no=1 AND previous_event_id IS NULL) OR (event_no>1 AND previous_event_id IS NOT NULL)),
  CHECK (action <> 'publish' OR validation_id IS NOT NULL)
);
CREATE UNIQUE INDEX uq_publication_root ON ea.publication_event(resource_version_id,usergroup_id) WHERE previous_event_id IS NULL;

CREATE TABLE ea.assignment_binding (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  assignment_id integer NOT NULL,
  version integer NOT NULL CHECK (version > 0),
  resource_version_id uuid NOT NULL,
  rubric_version_id uuid NOT NULL,
  policy_version_id uuid NOT NULL,
  publication_event_id uuid NOT NULL,
  usergroup_id integer NOT NULL,
  opens_at timestamptz NOT NULL,
  due_at timestamptz NOT NULL,
  max_attempts integer NOT NULL DEFAULT 1 CHECK (max_attempts BETWEEN 1 AND 100),
  answer_release text NOT NULL DEFAULT 'after_due' CHECK (answer_release IN ('after_due','after_effective','never')),
  allow_review boolean NOT NULL DEFAULT true,
  rules_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(rules_snapshot)='object'),
  status text NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned','paused','closed','archived')),
  state_reason text NOT NULL DEFAULT '',
  state_changed_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,course_id,org_id),
  UNIQUE (id,resource_version_id,rubric_version_id,course_id,org_id),
  UNIQUE (id,usergroup_id,course_id,org_id),
  UNIQUE (assignment_id,version),
  FOREIGN KEY (assignment_id,course_id,org_id) REFERENCES public.assignment(id,course_id,org_id),
  FOREIGN KEY (resource_version_id,course_id,org_id) REFERENCES ea.resource_version(id,course_id,org_id),
  FOREIGN KEY (rubric_version_id,course_id,org_id) REFERENCES ea.rubric_version(id,course_id,org_id),
  FOREIGN KEY (policy_version_id,org_id) REFERENCES ea.policy_version(id,org_id),
  FOREIGN KEY (publication_event_id,resource_version_id,usergroup_id,course_id,org_id) REFERENCES ea.publication_event(id,resource_version_id,usergroup_id,course_id,org_id),
  FOREIGN KEY (created_by,org_id) REFERENCES ea.principal(id,org_id),
  CHECK (due_at > opens_at),
  CHECK (status='assigned' OR length(btrim(state_reason))>0)
);

CREATE TABLE ea.assignment_recipient (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  binding_id uuid NOT NULL,
  student_id integer NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  usergroup_id integer NOT NULL,
  membership_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(membership_snapshot)='object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,binding_id,course_id,org_id),
  UNIQUE (binding_id,student_id),
  FOREIGN KEY (binding_id,usergroup_id,course_id,org_id) REFERENCES ea.assignment_binding(id,usergroup_id,course_id,org_id)
);

CREATE TABLE ea.resubmission_grant (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  recipient_id uuid NOT NULL,
  binding_id uuid NOT NULL,
  student_id integer NOT NULL,
  grant_kind text NOT NULL CHECK (grant_kind IN ('late','correction')),
  starts_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  allowed_attempts integer NOT NULL CHECK (allowed_attempts BETWEEN 1 AND 20),
  granted_by uuid NOT NULL,
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,recipient_id,student_id,binding_id,course_id,org_id),
  FOREIGN KEY (recipient_id,student_id,binding_id,course_id,org_id) REFERENCES ea.assignment_recipient(id,student_id,binding_id,course_id,org_id),
  FOREIGN KEY (granted_by,org_id) REFERENCES ea.principal(id,org_id),
  CHECK (expires_at > starts_at)
);
CREATE INDEX ix_resubmission_active ON ea.resubmission_grant(recipient_id,expires_at) WHERE revoked_at IS NULL;

CREATE TABLE ea.attempt (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  recipient_id uuid NOT NULL,
  binding_id uuid NOT NULL,
  student_id integer NOT NULL,
  attempt_no integer NOT NULL CHECK (attempt_no > 0),
  resource_version_id uuid NOT NULL,
  rubric_version_id uuid NOT NULL,
  resubmission_grant_id uuid,
  grant_slot integer,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','abandoned')),
  draft jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(draft)='object'),
  draft_revision bigint NOT NULL DEFAULT 0 CHECK (draft_revision >= 0),
  start_key text NOT NULL CHECK (length(start_key) BETWEEN 1 AND 200),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,course_id,org_id),
  UNIQUE (recipient_id,attempt_no),
  UNIQUE (recipient_id,start_key),
  UNIQUE (resubmission_grant_id,grant_slot),
  FOREIGN KEY (recipient_id,student_id,binding_id,course_id,org_id) REFERENCES ea.assignment_recipient(id,student_id,binding_id,course_id,org_id),
  FOREIGN KEY (binding_id,resource_version_id,rubric_version_id,course_id,org_id) REFERENCES ea.assignment_binding(id,resource_version_id,rubric_version_id,course_id,org_id),
  FOREIGN KEY (resubmission_grant_id,recipient_id,student_id,binding_id,course_id,org_id) REFERENCES ea.resubmission_grant(id,recipient_id,student_id,binding_id,course_id,org_id),
  CHECK ((resubmission_grant_id IS NULL AND grant_slot IS NULL) OR (resubmission_grant_id IS NOT NULL AND grant_slot IS NOT NULL AND grant_slot > 0))
);
CREATE UNIQUE INDEX uq_one_open_attempt ON ea.attempt(recipient_id) WHERE status='draft';

CREATE TABLE ea.submission (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  attempt_id uuid NOT NULL UNIQUE,
  student_id integer NOT NULL,
  receipt_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  idempotency_key text NOT NULL CHECK (length(idempotency_key) BETWEEN 1 AND 200),
  request_hash text NOT NULL CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  answer_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(answer_snapshot)='object'),
  provenance text NOT NULL CHECK (provenance IN ('real','demo','manual_example','simulated')),
  accepted_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,course_id,org_id),
  UNIQUE (org_id,student_id,idempotency_key),
  FOREIGN KEY (attempt_id,student_id,course_id,org_id) REFERENCES ea.attempt(id,student_id,course_id,org_id)
);
CREATE INDEX ix_submission_student ON ea.submission(org_id,course_id,student_id,accepted_at DESC);

CREATE TABLE ea.evaluation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  submission_id uuid NOT NULL,
  student_id integer NOT NULL,
  rubric_version_id uuid NOT NULL,
  policy_version_id uuid NOT NULL,
  task_id uuid,
  source text NOT NULL CHECK (source IN ('rule','ai_suggestion','teacher')),
  outcome text NOT NULL CHECK (outcome IN ('scored','needs_review','tool_error')),
  score numeric(10,4),
  maximum_score numeric(10,4) NOT NULL CHECK (maximum_score > 0),
  details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(details)='object'),
  feedback jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(feedback)='object'),
  producer_version text NOT NULL,
  actor_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,submission_id,student_id,course_id,org_id),
  FOREIGN KEY (submission_id,student_id,course_id,org_id) REFERENCES ea.submission(id,student_id,course_id,org_id),
  FOREIGN KEY (rubric_version_id,course_id,org_id) REFERENCES ea.rubric_version(id,course_id,org_id),
  FOREIGN KEY (policy_version_id,org_id) REFERENCES ea.policy_version(id,org_id),
  FOREIGN KEY (task_id,course_id,org_id) REFERENCES ea.task_run(id,course_id,org_id),
  FOREIGN KEY (actor_id,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((outcome='scored' AND score IS NOT NULL AND score BETWEEN 0 AND maximum_score) OR (outcome IN ('needs_review','tool_error') AND score IS NULL))
);
CREATE INDEX ix_evaluation_submission ON ea.evaluation(submission_id,created_at DESC);

CREATE TABLE ea.grade_revision (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  submission_id uuid NOT NULL,
  student_id integer NOT NULL,
  evaluation_id uuid NOT NULL,
  revision integer NOT NULL CHECK (revision > 0),
  supersedes_id uuid UNIQUE,
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  actor_id uuid NOT NULL,
  effective_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,course_id,org_id),
  UNIQUE (id,submission_id,student_id,course_id,org_id),
  UNIQUE (submission_id,revision),
  UNIQUE (evaluation_id),
  FOREIGN KEY (evaluation_id,submission_id,student_id,course_id,org_id) REFERENCES ea.evaluation(id,submission_id,student_id,course_id,org_id),
  FOREIGN KEY (supersedes_id,submission_id,student_id,course_id,org_id) REFERENCES ea.grade_revision(id,submission_id,student_id,course_id,org_id),
  FOREIGN KEY (actor_id,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((revision=1 AND supersedes_id IS NULL) OR (revision>1 AND supersedes_id IS NOT NULL))
);
CREATE UNIQUE INDEX uq_grade_root ON ea.grade_revision(submission_id) WHERE supersedes_id IS NULL;

CREATE TABLE ea.review_request (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  submission_id uuid NOT NULL,
  student_id integer NOT NULL,
  grade_revision_id uuid NOT NULL,
  request_text text NOT NULL CHECK (length(btrim(request_text)) > 0),
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','retained','revised','withdrawn')),
  resolved_revision_id uuid,
  resolution text,
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (grade_revision_id,submission_id,student_id,course_id,org_id) REFERENCES ea.grade_revision(id,submission_id,student_id,course_id,org_id),
  FOREIGN KEY (resolved_revision_id,submission_id,student_id,course_id,org_id) REFERENCES ea.grade_revision(id,submission_id,student_id,course_id,org_id),
  FOREIGN KEY (resolved_by,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((status='open' AND resolved_at IS NULL AND resolved_by IS NULL AND resolution IS NULL AND resolved_revision_id IS NULL) OR
    (status<>'open' AND resolved_at IS NOT NULL AND resolved_by IS NOT NULL AND resolution IS NOT NULL AND length(btrim(resolution))>0)),
  CHECK (status<>'revised' OR (resolved_revision_id IS NOT NULL AND resolved_revision_id<>grade_revision_id)),
  CHECK (status NOT IN ('retained','withdrawn') OR resolved_revision_id IS NULL)
);
CREATE UNIQUE INDEX uq_review_active ON ea.review_request(grade_revision_id) WHERE status='open';
CREATE INDEX ix_review_pending ON ea.review_request(org_id,course_id,created_at) WHERE status='open';

CREATE TABLE ea.note_permission (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  note_id integer NOT NULL,
  student_id integer NOT NULL,
  purpose text NOT NULL CHECK (purpose IN ('profile_use','teacher_read')),
  grantee_id uuid,
  consent_revision integer NOT NULL CHECK (consent_revision > 0),
  starts_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,course_id,org_id),
  UNIQUE (note_id,purpose,grantee_id,consent_revision),
  FOREIGN KEY (note_id,student_id,course_id,org_id) REFERENCES public.learner_note(id,user_id,course_id,org_id),
  FOREIGN KEY (grantee_id,org_id) REFERENCES ea.principal(id,org_id),
  CHECK ((purpose='profile_use' AND grantee_id IS NULL) OR (purpose='teacher_read' AND grantee_id IS NOT NULL)),
  CHECK (expires_at IS NULL OR expires_at > starts_at)
);
-- PostgreSQL 14-compatible uniqueness for nullable personal-use grantees.
CREATE UNIQUE INDEX uq_note_personal_revision ON ea.note_permission(note_id,purpose,consent_revision) WHERE grantee_id IS NULL;
CREATE UNIQUE INDEX uq_note_active_teacher ON ea.note_permission(note_id,purpose,grantee_id) WHERE revoked_at IS NULL AND grantee_id IS NOT NULL;
CREATE UNIQUE INDEX uq_note_active_personal ON ea.note_permission(note_id,purpose) WHERE revoked_at IS NULL AND grantee_id IS NULL;

CREATE TABLE ea.evidence_event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  student_id integer NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  knowledge_point_id uuid NOT NULL,
  grade_revision_id uuid,
  note_permission_id uuid,
  source_type text NOT NULL CHECK (source_type IN ('effective_grade','consented_note','observation')),
  provenance text NOT NULL CHECK (provenance IN ('real','demo','manual_example','simulated')),
  judgment_source text NOT NULL CHECK (judgment_source IN ('rule','model','teacher','self_report')),
  source_event_key text NOT NULL CHECK (length(source_event_key) BETWEEN 1 AND 200),
  summary jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(summary)='object'),
  observed_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,course_id,org_id),
  UNIQUE (org_id,source_event_key,knowledge_point_id),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  FOREIGN KEY (knowledge_point_id,course_id,org_id) REFERENCES ea.knowledge_point(id,course_id,org_id),
  FOREIGN KEY (grade_revision_id,student_id,course_id,org_id) REFERENCES ea.grade_revision(id,student_id,course_id,org_id),
  FOREIGN KEY (note_permission_id,student_id,course_id,org_id) REFERENCES ea.note_permission(id,student_id,course_id,org_id),
  CHECK ((source_type='effective_grade' AND grade_revision_id IS NOT NULL AND note_permission_id IS NULL) OR
         (source_type='consented_note' AND note_permission_id IS NOT NULL AND grade_revision_id IS NULL) OR
         (source_type='observation' AND grade_revision_id IS NULL AND note_permission_id IS NULL))
);
CREATE INDEX ix_evidence_student ON ea.evidence_event(org_id,course_id,student_id,observed_at DESC);

CREATE TABLE ea.profile_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  student_id integer NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  version integer NOT NULL CHECK (version > 0),
  previous_version_id uuid UNIQUE,
  trigger_type text NOT NULL CHECK (trigger_type IN ('grade_effective','grade_corrected','note_evidence','consent_revoked','rebuild')),
  trigger_event_key text NOT NULL CHECK (length(trigger_event_key) BETWEEN 1 AND 200),
  trigger_grade_id uuid,
  task_id uuid NOT NULL,
  method_kind text NOT NULL CHECK (method_kind IN ('rule_statistics','research_prototype')),
  capability_status text NOT NULL CHECK (capability_status IN ('connected','not_connected','unvalidated')),
  method_version text NOT NULL,
  provenance text NOT NULL CHECK (provenance IN ('real','demo','manual_example','simulated','mixed')),
  evidence_manifest jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(evidence_manifest)='array'),
  states jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(states)='object'),
  research_fields jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(research_fields)='object'),
  input_hash text NOT NULL CHECK (input_hash ~ '^[0-9a-f]{64}$'),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,course_id,org_id),
  UNIQUE (org_id,course_id,student_id,version),
  UNIQUE (org_id,course_id,student_id,trigger_event_key,method_version),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  FOREIGN KEY (previous_version_id,student_id,course_id,org_id) REFERENCES ea.profile_version(id,student_id,course_id,org_id),
  FOREIGN KEY (trigger_grade_id,student_id,course_id,org_id) REFERENCES ea.grade_revision(id,student_id,course_id,org_id),
  FOREIGN KEY (task_id,course_id,org_id) REFERENCES ea.task_run(id,course_id,org_id),
  CHECK ((version=1 AND previous_version_id IS NULL) OR (version>1 AND previous_version_id IS NOT NULL)),
  CHECK ((trigger_type IN ('grade_effective','grade_corrected') AND trigger_grade_id IS NOT NULL) OR
         (trigger_type IN ('note_evidence','consent_revoked','rebuild') AND trigger_grade_id IS NULL)),
  CHECK (method_kind<>'rule_statistics' OR research_fields='{}'::jsonb)
);
CREATE UNIQUE INDEX uq_profile_root ON ea.profile_version(org_id,course_id,student_id) WHERE previous_version_id IS NULL;

CREATE TABLE ea.recommendation_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  student_id integer NOT NULL,
  profile_version_id uuid NOT NULL,
  method_version text NOT NULL,
  task_id uuid NOT NULL,
  provenance text NOT NULL CHECK (provenance IN ('real','demo','manual_example','simulated','mixed')),
  state text NOT NULL CHECK (state IN ('ready','no_content')),
  reason text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,student_id,course_id,org_id),
  UNIQUE (profile_version_id,method_version),
  FOREIGN KEY (profile_version_id,student_id,course_id,org_id) REFERENCES ea.profile_version(id,student_id,course_id,org_id),
  FOREIGN KEY (task_id,course_id,org_id) REFERENCES ea.task_run(id,course_id,org_id)
);

CREATE TABLE ea.recommendation_item (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  student_id integer NOT NULL,
  recommendation_version_id uuid NOT NULL,
  rank integer NOT NULL CHECK (rank > 0),
  knowledge_point_id uuid NOT NULL,
  evidence_id uuid NOT NULL,
  resource_version_id uuid,
  binding_id uuid,
  recipient_id uuid,
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recommendation_version_id,rank),
  FOREIGN KEY (recommendation_version_id,student_id,course_id,org_id) REFERENCES ea.recommendation_version(id,student_id,course_id,org_id),
  FOREIGN KEY (knowledge_point_id,course_id,org_id) REFERENCES ea.knowledge_point(id,course_id,org_id),
  FOREIGN KEY (evidence_id,student_id,course_id,org_id) REFERENCES ea.evidence_event(id,student_id,course_id,org_id),
  FOREIGN KEY (resource_version_id,course_id,org_id) REFERENCES ea.resource_version(id,course_id,org_id),
  FOREIGN KEY (recipient_id,student_id,binding_id,course_id,org_id) REFERENCES ea.assignment_recipient(id,student_id,binding_id,course_id,org_id),
  CHECK ((resource_version_id IS NOT NULL AND binding_id IS NULL AND recipient_id IS NULL) OR
         (resource_version_id IS NULL AND binding_id IS NOT NULL AND recipient_id IS NOT NULL))
);

CREATE TABLE ea.intervention_event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL,
  course_id integer NOT NULL,
  student_id integer NOT NULL,
  profile_version_id uuid NOT NULL,
  recommendation_version_id uuid,
  target_binding_id uuid,
  action text NOT NULL CHECK (action IN ('assign_next','adjust_next','record_support')),
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  actor_id uuid NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(details)='object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (profile_version_id,student_id,course_id,org_id) REFERENCES ea.profile_version(id,student_id,course_id,org_id),
  FOREIGN KEY (recommendation_version_id,student_id,course_id,org_id) REFERENCES ea.recommendation_version(id,student_id,course_id,org_id),
  FOREIGN KEY (target_binding_id,course_id,org_id) REFERENCES ea.assignment_binding(id,course_id,org_id),
  FOREIGN KEY (actor_id,org_id) REFERENCES ea.principal(id,org_id)
);

CREATE TABLE ea.outbox_event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id integer NOT NULL REFERENCES public.organization(id) ON DELETE RESTRICT,
  course_id integer,
  event_type text NOT NULL,
  aggregate_type text NOT NULL,
  aggregate_id uuid NOT NULL,
  deduplication_key text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload)='object'),
  available_at timestamptz NOT NULL DEFAULT now(),
  claimed_until timestamptz,
  delivery_attempts integer NOT NULL DEFAULT 0 CHECK (delivery_attempts BETWEEN 0 AND 100),
  published_at timestamptz,
  dead_letter_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id,event_type,deduplication_key),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  CHECK (published_at IS NULL OR dead_letter_at IS NULL)
);
CREATE INDEX ix_outbox_dispatch ON ea.outbox_event(available_at,created_at) WHERE published_at IS NULL AND dead_letter_at IS NULL;

CREATE TABLE ea.audit_event (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  org_id integer NOT NULL REFERENCES public.organization(id) ON DELETE RESTRICT,
  course_id integer,
  actor_id uuid NOT NULL,
  action text NOT NULL,
  target_type text NOT NULL,
  target_id text NOT NULL,
  request_id uuid NOT NULL,
  task_id uuid,
  before_version text,
  after_version text,
  reason_code text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata)='object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (course_id,org_id) REFERENCES public.course(id,org_id),
  FOREIGN KEY (actor_id,org_id) REFERENCES ea.principal(id,org_id),
  FOREIGN KEY (task_id,org_id) REFERENCES ea.task_run(id,org_id)
);
CREATE INDEX ix_audit_trace ON ea.audit_event(org_id,target_type,target_id,created_at DESC);
CREATE INDEX ix_audit_request ON ea.audit_event(request_id);

-- Immutable facts: old versions are never edited, even when superseded.
CREATE FUNCTION ea.reject_fact_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'ea immutable fact: % cannot be %', TG_TABLE_NAME, TG_OP USING ERRCODE='55000';
END $$;
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['policy_version','knowledge_point','resource_version','rubric_version','content_check','publication_event','assignment_recipient','submission','evaluation','grade_revision','evidence_event','profile_version','recommendation_version','recommendation_item','intervention_event','audit_event'] LOOP
    EXECUTE format('CREATE TRIGGER immutable_fact BEFORE UPDATE OR DELETE ON ea.%I FOR EACH ROW EXECUTE FUNCTION ea.reject_fact_mutation()',t);
  END LOOP;
END $$;

-- Mutable state may change only the explicitly named columns; object scope never moves.
CREATE FUNCTION ea.guard_state_columns() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE permitted text[] := string_to_array(TG_ARGV[0],',');
BEGIN
  IF TG_OP='DELETE' THEN
    RAISE EXCEPTION 'Use logical lifecycle operations, not DELETE on ea.%',TG_TABLE_NAME;
  END IF;
  IF (to_jsonb(NEW)-permitted) IS DISTINCT FROM (to_jsonb(OLD)-permitted) THEN
    RAISE EXCEPTION 'Frozen identity/version field changed on ea.%',TG_TABLE_NAME;
  END IF;
  IF TG_TABLE_NAME IN ('action_grant','resubmission_grant','note_permission') AND (to_jsonb(OLD)->>'revoked_at') IS NOT NULL THEN
    RAISE EXCEPTION 'Revocation is final; issue a new grant/consent';
  END IF;
  IF TG_TABLE_NAME='review_request' AND (to_jsonb(OLD)->>'status')<>'open' THEN
    RAISE EXCEPTION 'Resolved review is immutable';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.principal FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('disabled_at');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.action_grant FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('revoked_at,revoked_by');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.resource FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('title,archived_at');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.assignment_binding FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('status,state_reason,state_changed_at');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.resubmission_grant FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('revoked_at');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.note_permission FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('revoked_at');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.review_request FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('status,resolved_revision_id,resolution,resolved_by,resolved_at');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.task_run FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('status,attempt_count,execution_epoch,lease_until,not_before,error_code,budget_spent,cancelled_at,completed_at,result_refs,updated_at');
CREATE TRIGGER guard_state BEFORE UPDATE OR DELETE ON ea.outbox_event FOR EACH ROW EXECUTE FUNCTION ea.guard_state_columns('available_at,claimed_until,delivery_attempts,published_at,dead_letter_at');

CREATE FUNCTION ea.guard_attempt() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP='DELETE' THEN
    IF OLD.status<>'draft' OR EXISTS (SELECT 1 FROM ea.submission WHERE attempt_id=OLD.id) THEN
      RAISE EXCEPTION 'Only an unsubmitted private draft can be deleted';
    END IF;
    RETURN OLD;
  END IF;
  IF (to_jsonb(NEW)-ARRAY['status','draft','draft_revision','updated_at']) IS DISTINCT FROM
     (to_jsonb(OLD)-ARRAY['status','draft','draft_revision','updated_at']) OR OLD.status<>'draft' THEN
    RAISE EXCEPTION 'Attempt identity/frozen version or submitted draft cannot change';
  END IF;
  IF NEW.draft IS DISTINCT FROM OLD.draft AND NEW.draft_revision<>OLD.draft_revision+1 THEN
    RAISE EXCEPTION 'Draft write must increment optimistic revision';
  END IF;
  IF NEW.status='submitted' AND NOT EXISTS (SELECT 1 FROM ea.submission WHERE attempt_id=NEW.id) THEN
    RAISE EXCEPTION 'Insert accepted submission before marking attempt submitted';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER guard_attempt BEFORE UPDATE OR DELETE ON ea.attempt FOR EACH ROW EXECUTE FUNCTION ea.guard_attempt();

-- Cross-table semantic invariants beyond composite FKs.
CREATE FUNCTION ea.validate_scoped_policy() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE p ea.policy_version;
BEGIN
  SELECT * INTO STRICT p FROM ea.policy_version WHERE id=NEW.policy_version_id AND org_id=NEW.org_id;
  IF p.course_id IS NOT NULL AND p.course_id<>NEW.course_id THEN
    RAISE EXCEPTION 'Policy belongs to another course';
  END IF;
  RETURN NEW;
END $$;
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['resource_version','content_check','publication_event','assignment_binding','evaluation'] LOOP
    EXECUTE format('CREATE TRIGGER check_policy BEFORE INSERT ON ea.%I FOR EACH ROW EXECUTE FUNCTION ea.validate_scoped_policy()',t);
  END LOOP;
END $$;

CREATE FUNCTION ea.validate_publication() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v ea.resource_version; c ea.content_check; prev ea.publication_event; p ea.principal;
BEGIN
  SELECT * INTO STRICT v FROM ea.resource_version WHERE id=NEW.resource_version_id;
  PERFORM 1 FROM ea.resource WHERE id=v.resource_id FOR UPDATE;
  IF NEW.previous_event_id IS NOT NULL THEN
    SELECT * INTO STRICT prev FROM ea.publication_event WHERE id=NEW.previous_event_id FOR UPDATE;
    IF NEW.event_no<>prev.event_no+1 OR prev.action=NEW.action THEN
      RAISE EXCEPTION 'Publication events must be a consecutive publish/withdraw chain';
    END IF;
  ELSIF NEW.action<>'publish' THEN
    RAISE EXCEPTION 'First publication event must publish';
  END IF;
  IF NEW.action='publish' THEN
    IF v.processing_state<>'ready' THEN RAISE EXCEPTION 'Resource not ready'; END IF;
    SELECT * INTO STRICT c FROM ea.content_check WHERE id=NEW.validation_id;
    IF c.check_kind<>'deterministic' OR c.verdict<>'pass' OR c.policy_version_id<>NEW.policy_version_id THEN
      RAISE EXCEPTION 'Passing deterministic check under publication policy is required';
    END IF;
    IF v.forced_review AND NEW.review_id IS NULL THEN RAISE EXCEPTION 'Forced review cannot be waived'; END IF;
    IF NEW.review_id IS NOT NULL THEN
      SELECT * INTO STRICT c FROM ea.content_check WHERE id=NEW.review_id;
      IF c.check_kind<>'human_review' OR c.verdict<>'approve' OR c.policy_version_id<>NEW.policy_version_id THEN
        RAISE EXCEPTION 'Valid approval under publication policy required';
      END IF;
    END IF;
    SELECT * INTO STRICT p FROM ea.principal WHERE id=NEW.actor_id;
    IF p.kind='service' AND (v.generation_mode<>'rule_template' OR v.forced_review) THEN
      RAISE EXCEPTION 'Automatic publish is limited to eligible rule templates';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_publication BEFORE INSERT ON ea.publication_event FOR EACH ROW EXECUTE FUNCTION ea.validate_publication();

CREATE FUNCTION ea.validate_evaluation() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE r ea.rubric_version; a ea.attempt; p ea.principal;
BEGIN
  SELECT * INTO STRICT r FROM ea.rubric_version WHERE id=NEW.rubric_version_id;
  SELECT a0.* INTO STRICT a FROM ea.submission s JOIN ea.attempt a0 ON a0.id=s.attempt_id WHERE s.id=NEW.submission_id;
  IF a.rubric_version_id<>NEW.rubric_version_id OR NEW.maximum_score<>r.maximum_score THEN
    RAISE EXCEPTION 'Evaluation must use the frozen rubric and its scoring scale';
  END IF;
  SELECT * INTO STRICT p FROM ea.principal WHERE id=NEW.actor_id;
  IF NEW.source='teacher' AND p.kind<>'human' THEN RAISE EXCEPTION 'Teacher judgment requires a human principal'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_evaluation BEFORE INSERT ON ea.evaluation FOR EACH ROW EXECUTE FUNCTION ea.validate_evaluation();

CREATE FUNCTION ea.validate_grade() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE e ea.evaluation; prev ea.grade_revision;
BEGIN
  SELECT * INTO STRICT e FROM ea.evaluation WHERE id=NEW.evaluation_id;
  IF e.outcome<>'scored' OR e.source='ai_suggestion' THEN
    RAISE EXCEPTION 'Only scored rule or teacher evaluations can become effective';
  END IF;
  IF NEW.supersedes_id IS NOT NULL THEN
    SELECT * INTO STRICT prev FROM ea.grade_revision WHERE id=NEW.supersedes_id;
    IF NEW.revision<>prev.revision+1 THEN RAISE EXCEPTION 'Grade revision must be consecutive'; END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_grade BEFORE INSERT ON ea.grade_revision FOR EACH ROW EXECUTE FUNCTION ea.validate_grade();


-- Current access remains an upstream fact. Demo uses explicitly provisioned,
-- direct class membership; smart/nested group expansion is outside this adapter.
CREATE FUNCTION ea.assert_recipient_access(rec ea.assignment_recipient) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.userorganization u WHERE u.org_id=rec.org_id AND u.user_id=rec.student_id) OR
     NOT EXISTS (SELECT 1 FROM public.usergroupuser u WHERE u.org_id=rec.org_id AND u.usergroup_id=rec.usergroup_id AND u.user_id=rec.student_id AND (u.expires_at IS NULL OR u.expires_at>clock_timestamp())) OR
     NOT EXISTS (SELECT 1 FROM public.usergroupresource gr JOIN public.course c ON c.course_uuid=gr.resource_uuid AND c.org_id=gr.org_id
                 WHERE c.id=rec.course_id AND gr.org_id=rec.org_id AND gr.usergroup_id=rec.usergroup_id
                   AND (gr.starts_at IS NULL OR gr.starts_at<=clock_timestamp()) AND (gr.expires_at IS NULL OR gr.expires_at>clock_timestamp())) THEN
    RAISE EXCEPTION 'Current upstream organization/class/course authorization is missing' USING ERRCODE='42501';
  END IF;
END $$;
CREATE FUNCTION ea.validate_recipient() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM ea.assert_recipient_access(NEW);
  RETURN NEW;
END $$;
CREATE TRIGGER check_recipient BEFORE INSERT ON ea.assignment_recipient FOR EACH ROW EXECUTE FUNCTION ea.validate_recipient();

CREATE FUNCTION ea.validate_binding() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE p ea.publication_event;
BEGIN
  PERFORM 1 FROM ea.resource r JOIN ea.resource_version v ON v.resource_id=r.id WHERE v.id=NEW.resource_version_id FOR UPDATE OF r;
  SELECT * INTO STRICT p FROM ea.publication_event WHERE id=NEW.publication_event_id FOR UPDATE;
  IF p.action<>'publish' OR EXISTS (SELECT 1 FROM ea.publication_event WHERE previous_event_id=p.id) THEN
    RAISE EXCEPTION 'Assignment must bind a currently published event';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_binding BEFORE INSERT ON ea.assignment_binding FOR EACH ROW EXECUTE FUNCTION ea.validate_binding();

CREATE FUNCTION ea.assert_attempt_window(a ea.attempt, is_new boolean) RETURNS void LANGUAGE plpgsql AS $$
DECLARE b ea.assignment_binding; rec ea.assignment_recipient; g ea.resubmission_grant; pe ea.publication_event;
BEGIN
  -- Serialize starts and hand-ins for one recipient; grant_slot uniqueness also
  -- protects parallel allocation. Recheck at submit, not just at page entry.
  SELECT * INTO STRICT rec FROM ea.assignment_recipient WHERE id=a.recipient_id FOR UPDATE;
  SELECT * INTO STRICT b FROM ea.assignment_binding WHERE id=a.binding_id FOR UPDATE;
  PERFORM ea.assert_recipient_access(rec);
  IF b.status<>'assigned' THEN RAISE EXCEPTION 'Assignment is paused, closed or archived'; END IF;
  IF a.resubmission_grant_id IS NULL THEN
    IF clock_timestamp()<b.opens_at OR clock_timestamp()>b.due_at THEN
      RAISE EXCEPTION 'Outside normal submission window';
    END IF;
    IF is_new AND (SELECT count(*) FROM ea.attempt WHERE recipient_id=rec.id AND resubmission_grant_id IS NULL)>=b.max_attempts THEN
      RAISE EXCEPTION 'Normal attempt limit reached';
    END IF;
  ELSE
    SELECT * INTO STRICT g FROM ea.resubmission_grant WHERE id=a.resubmission_grant_id FOR UPDATE;
    IF g.revoked_at IS NOT NULL OR clock_timestamp()<g.starts_at OR clock_timestamp()>=g.expires_at OR a.grant_slot>g.allowed_attempts THEN
      RAISE EXCEPTION 'Late/correction grant expired, revoked or exhausted';
    END IF;
  END IF;
  IF is_new THEN
    PERFORM 1 FROM ea.resource r JOIN ea.resource_version v ON v.resource_id=r.id WHERE v.id=a.resource_version_id FOR UPDATE OF r;
    SELECT * INTO STRICT pe FROM ea.publication_event WHERE resource_version_id=a.resource_version_id AND usergroup_id=rec.usergroup_id ORDER BY event_no DESC LIMIT 1;
    IF pe.action<>'publish' OR EXISTS (SELECT 1 FROM ea.resource r JOIN ea.resource_version v ON v.resource_id=r.id WHERE v.id=a.resource_version_id AND r.archived_at IS NOT NULL) THEN
      RAISE EXCEPTION 'Withdrawn or archived content cannot start a new attempt';
    END IF;
    IF a.attempt_no<>(SELECT coalesce(max(attempt_no),0)+1 FROM ea.attempt WHERE recipient_id=rec.id) THEN
      RAISE EXCEPTION 'Attempt number must be next for this recipient';
    END IF;
  END IF;
END $$;
CREATE FUNCTION ea.validate_attempt_start() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status<>'draft' THEN RAISE EXCEPTION 'An attempt starts as draft'; END IF;
  PERFORM ea.assert_attempt_window(NEW,true);
  RETURN NEW;
END $$;
CREATE TRIGGER check_attempt_start BEFORE INSERT ON ea.attempt FOR EACH ROW EXECUTE FUNCTION ea.validate_attempt_start();
CREATE FUNCTION ea.validate_submission() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE a ea.attempt;
BEGIN
  SELECT * INTO STRICT a FROM ea.attempt WHERE id=NEW.attempt_id FOR UPDATE;
  IF a.status<>'draft' THEN RAISE EXCEPTION 'Only an open draft accepts a submission'; END IF;
  PERFORM ea.assert_attempt_window(a,false);
  NEW.accepted_at := clock_timestamp();
  RETURN NEW;
END $$;
CREATE TRIGGER check_submission BEFORE INSERT ON ea.submission FOR EACH ROW EXECUTE FUNCTION ea.validate_submission();
CREATE FUNCTION ea.finish_attempt() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE ea.attempt SET status='submitted',updated_at=clock_timestamp() WHERE id=NEW.attempt_id;
  RETURN NEW;
END $$;
CREATE TRIGGER finish_attempt AFTER INSERT ON ea.submission FOR EACH ROW EXECUTE FUNCTION ea.finish_attempt();

CREATE FUNCTION ea.validate_profile() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE prev ea.profile_version; item jsonb; field jsonb; kp text; state_value jsonb; ev ea.evidence_event;
BEGIN
  IF NEW.previous_version_id IS NOT NULL THEN
    SELECT * INTO STRICT prev FROM ea.profile_version WHERE id=NEW.previous_version_id;
    IF NEW.version<>prev.version+1 THEN RAISE EXCEPTION 'Profile version must be consecutive'; END IF;
  END IF;
  -- JSON manifests stay compact but every evidence identifier is verified in DB.
  FOR item IN SELECT value FROM jsonb_array_elements(NEW.evidence_manifest) LOOP
    SELECT * INTO ev FROM ea.evidence_event e WHERE e.id=(item->>'evidence_id')::uuid AND e.org_id=NEW.org_id AND e.course_id=NEW.course_id AND e.student_id=NEW.student_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Profile evidence identifier is missing or crosses a student/course'; END IF;
    IF NEW.provenance='real' AND ev.provenance<>'real' THEN RAISE EXCEPTION 'Example/simulated evidence cannot become real provenance'; END IF;
    IF ev.source_type='consented_note' AND NOT EXISTS (SELECT 1 FROM ea.note_permission n WHERE n.id=ev.note_permission_id AND n.purpose='profile_use' AND n.revoked_at IS NULL AND n.starts_at<=clock_timestamp() AND (n.expires_at IS NULL OR n.expires_at>clock_timestamp())) THEN
      RAISE EXCEPTION 'Revoked or expired note consent cannot be reused in a new profile';
    END IF;
  END LOOP;
  FOR kp,state_value IN SELECT key,value FROM jsonb_each(NEW.states) LOOP
    IF NOT EXISTS (SELECT 1 FROM ea.knowledge_point WHERE id=kp::uuid AND course_id=NEW.course_id AND org_id=NEW.org_id) OR
       jsonb_typeof(state_value)<>'object' OR coalesce(state_value->>'state','') NOT IN ('good','bad','unknown','conflict') THEN
      RAISE EXCEPTION 'State must name a course knowledge point and use good/bad/unknown/conflict';
    END IF;
  END LOOP;
  FOR field IN SELECT value FROM jsonb_each(NEW.research_fields) LOOP
    IF jsonb_typeof(field)<>'object' OR NOT (field ? 'status' AND field ? 'source' AND field ? 'method_version') OR
       coalesce(field->>'status','') NOT IN ('unknown','not_connected','unvalidated','observed','estimated','conflict') THEN
      RAISE EXCEPTION 'Every research field needs explicit status, source and method_version';
    END IF;
  END LOOP;
  RETURN NEW;
END $$;
CREATE TRIGGER check_profile BEFORE INSERT ON ea.profile_version FOR EACH ROW EXECUTE FUNCTION ea.validate_profile();


CREATE FUNCTION ea.validate_parent_policy() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE p ea.policy_version;
BEGIN
  IF NEW.parent_policy_id IS NOT NULL THEN
    SELECT * INTO STRICT p FROM ea.policy_version WHERE id=NEW.parent_policy_id;
    IF p.policy_type<>'global' OR p.org_id<>NEW.org_id THEN RAISE EXCEPTION 'Course policy must pin an organization global policy'; END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_parent_policy BEFORE INSERT ON ea.policy_version FOR EACH ROW EXECUTE FUNCTION ea.validate_parent_policy();
CREATE FUNCTION ea.validate_evidence() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE prov text; consent ea.note_permission;
BEGIN
  IF NEW.source_type='effective_grade' THEN
    SELECT s.provenance INTO STRICT prov FROM ea.grade_revision g JOIN ea.submission s ON s.id=g.submission_id WHERE g.id=NEW.grade_revision_id;
    IF NEW.provenance<>prov THEN RAISE EXCEPTION 'Evidence must retain submission provenance'; END IF;
  ELSIF NEW.source_type='consented_note' THEN
    SELECT * INTO STRICT consent FROM ea.note_permission WHERE id=NEW.note_permission_id;
    IF consent.purpose<>'profile_use' OR consent.revoked_at IS NOT NULL OR consent.starts_at>clock_timestamp() OR
       (consent.expires_at IS NOT NULL AND consent.expires_at<=clock_timestamp()) THEN
      RAISE EXCEPTION 'Active profile-use consent is required; teacher sharing is insufficient';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_evidence BEFORE INSERT ON ea.evidence_event FOR EACH ROW EXECUTE FUNCTION ea.validate_evidence();


CREATE FUNCTION ea.validate_resource_lineage() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE prev ea.resource_version;
BEGIN
  IF NEW.previous_version_id IS NOT NULL THEN
    SELECT * INTO STRICT prev FROM ea.resource_version WHERE id=NEW.previous_version_id;
    IF prev.forced_review AND NOT NEW.forced_review THEN
      RAISE EXCEPTION 'Editing or changing generation mode cannot remove inherited forced review';
    END IF;
    IF NEW.version<>prev.version+1 THEN RAISE EXCEPTION 'Resource version must follow its predecessor'; END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_resource_lineage BEFORE INSERT ON ea.resource_version FOR EACH ROW EXECUTE FUNCTION ea.validate_resource_lineage();

-- Deliberately no GRANT to the ordinary upstream/operations DB role. Application
-- roles and request-scoped authorization must be configured before exposing ea.
REVOKE ALL ON ALL TABLES IN SCHEMA ea FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA ea FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA ea FROM PUBLIC;
COMMENT ON SCHEMA ea IS 'Education-agent V2 extension: upstream identity/LMS, immutable educational evidence; schema design not deployment proof';
COMMIT;
