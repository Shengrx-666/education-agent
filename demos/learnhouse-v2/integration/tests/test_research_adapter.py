"""Offline adapter contract tests. All student/material data here are fixtures."""
from dataclasses import asdict, replace
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from research_adapter import (AdapterError, CurrentContext, INTERPRETER, JobContext,
    LearningEvidenceProjection, PaidAuthorization, Principal, REPOSITORY,
    ResearchAdapter, Snapshot)


class FakeTransport:
    """Explicit fixture transport; it never executes argv or opens the network."""
    def __init__(self):
        self.calls = []
        self.callback = None
        self.returncode = 0
        self.timeout = False

    def __call__(self, argv, **kwargs):
        self.calls.append((argv, kwargs))
        if self.timeout:
            raise subprocess.TimeoutExpired(argv, kwargs["timeout"])
        if self.callback:
            self.callback()
        if "--execute" in argv and self.returncode == 0:
            output = Path(argv[argv.index("--output") + 1])
            output.mkdir()
            script = Path(argv[2]).name
            if script == "generate_question.py":
                data = {"schema": "generation-result-v1", "student_id": "student-fixture",
                        "ready_for_student": False, "execution_status": "completed", "status": "needs_review",
                        "private_prompt": "DO_NOT_RETURN_RAW_CONTENT"}
                (output / "generation.json").write_text(json.dumps(data))
            elif script == "run_recommendation.py":
                data = {"schema": "recommendation-round-v1", "student_id": "student-fixture",
                        "strategy": "B", "decision_kind": "model_inference", "execution_status": "completed",
                        "status": "insufficient_evidence"}
                (output / "recommendation.json").write_text(json.dumps(data))
            else:
                profile = {"student_id": "student-fixture", "status": "completed"}
                (output / "profile.json").write_text(json.dumps(profile))
                if script == "update_profile.py":
                    (output / "update.json").write_text(json.dumps({"status": "completed", "profile": profile}))
        return subprocess.CompletedProcess(argv, self.returncode,
            stdout=json.dumps({"mode": "preview", "secret": "DO_NOT_RETURN_RAW_CONTENT"}),
            stderr="DO_NOT_RETURN_RAW_CONTENT")


class ResearchAdapterTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.current = CurrentContext(epoch=4, version=2, active=True)
        self.principal = Principal("teacher-fixture", "course-fixture", frozenset({"student-fixture"}),
                                   frozenset({"java.condition"}), frozenset({"generate", "profile", "update", "recommend"}))
        self.catalog = {"version": "adapter-fixture-v1", "concepts": {"java.condition": "条件判断"},
                        "prerequisites": [], "associations": [], "relation_sources": {}}
        self.snapshot = Snapshot("student-fixture", self.catalog, ("java.condition",), "test_fixture",
                                 target_concept_ids=("java.condition",), requirements=("仅离线接口测试",))
        self.job = JobContext("job-fixture", "fixture-idempotency-key", 4, 2)
        self.fake = FakeTransport()
        self.env = self.root / "fixture.env"
        self.env.write_text("ZZZ_API_KEY=OFFLINE_FIXTURE_NOT_A_SECRET\n")
        self.adapter = self.make_adapter()
        self.network_guard = patch.object(socket.socket, "connect", side_effect=AssertionError("NETWORK_FORBIDDEN"))
        self.network_guard.start()
        self.addCleanup(self.network_guard.stop)

    def make_adapter(self, **extra):
        opts = dict(env_file=self.env, transport=self.fake, fixture_transport=True)
        opts.update(extra)
        return ResearchAdapter(self.root / "private", lambda *args: self.current, **opts)

    def auth(self, operation="generate", snapshot=None, job=None, calls=2):
        snapshot, job = snapshot or self.snapshot, job or self.job
        digest = ResearchAdapter.input_fingerprint(operation, self.principal, snapshot, job, calls)
        return PaidAuthorization("auth-fixture", self.principal.actor_id, job.job_id, operation, digest,
                                  calls, datetime.now(timezone.utc) + timedelta(minutes=1))

    def run_paid(self, **kwargs):
        return self.adapter.run("generate", self.principal, self.snapshot, self.job,
                                mode="execute", max_calls=2, authorization=self.auth(), **kwargs)

    def assert_code(self, code, action):
        with self.assertRaises(AdapterError) as found:
            action()
        self.assertEqual(found.exception.code, code)

    def test_default_preview_uses_only_fixed_cli_and_no_credentials(self):
        result = self.adapter.run("generate", self.principal, self.snapshot, self.job)
        self.assertEqual(result.status, "previewed")
        argv, kwargs = self.fake.calls[0]
        self.assertEqual(argv[:3], [str(INTERPRETER), "-B", str(REPOSITORY / "generate_question.py")])
        self.assertNotIn("--execute", argv)
        self.assertNotIn(str(self.env), argv)
        self.assertEqual(kwargs["cwd"], REPOSITORY)
        self.assertEqual(result.artifact_refs, ())
        self.assertNotIn("DO_NOT_RETURN", json.dumps(asdict(result)))

    def test_frontend_command_and_paths_are_rejected(self):
        for field in ("command", "argv", "env_file", "repository", "output", "profile_path", "recommendation_run"):
            data = asdict(self.snapshot)
            data[field] = "/tmp/untrusted"
            self.assert_code("UNSUPPORTED_SNAPSHOT_FIELD", lambda: Snapshot.from_mapping(data))

    def test_java_and_arbitrary_operations_are_not_available(self):
        for operation in ("verify_student", "verify_reference", "submit", "shell"):
            self.assert_code("UNSUPPORTED_OPERATION", lambda: self.adapter.run(operation, self.principal, self.snapshot, self.job))
        self.assertEqual(self.fake.calls, [])

    def test_subject_course_operation_and_concepts_must_fit_trusted_scope(self):
        principals = [replace(self.principal, subject_ids=frozenset()),
                      replace(self.principal, operations=frozenset()),
                      replace(self.principal, concept_ids=frozenset())]
        for principal in principals:
            self.assert_code("OUTSIDE_TRUSTED_SCOPE", lambda: self.adapter.run("generate", principal, self.snapshot, self.job))

    def test_context_is_checked_before_dispatch(self):
        self.current = CurrentContext(5, 2, True)
        self.assert_code("STALE_CONTEXT", lambda: self.adapter.run("generate", self.principal, self.snapshot, self.job))
        self.assertEqual(self.fake.calls, [])

    def test_paid_execution_requires_authorization(self):
        self.assert_code("PAID_AUTHORIZATION_REQUIRED", lambda: self.adapter.run("generate", self.principal,
            self.snapshot, self.job, mode="execute", max_calls=2))

    def test_explicit_budget_and_matching_authorization_required(self):
        self.assert_code("EXPLICIT_BUDGET_REQUIRED", lambda: self.adapter.run("generate", self.principal,
            self.snapshot, self.job, mode="execute", authorization=self.auth()))
        self.assert_code("AUTHORIZATION_MISMATCH", lambda: self.adapter.run("generate", self.principal,
            self.snapshot, self.job, mode="execute", max_calls=1, authorization=self.auth()))
        self.assert_code("INVALID_BUDGET", lambda: self.adapter.run("recommend", self.principal,
            self.snapshot, self.job, max_calls=3))

    def test_expired_authorization_rejected(self):
        auth = replace(self.auth(), expires_at=datetime.now(timezone.utc) - timedelta(seconds=1))
        self.assert_code("AUTHORIZATION_EXPIRED", lambda: self.adapter.run("generate", self.principal,
            self.snapshot, self.job, mode="execute", max_calls=2, authorization=auth))

    def test_missing_env_rejected_without_dispatch(self):
        self.env.unlink()
        self.assert_code("MODEL_NOT_CONFIGURED", self.run_paid)
        self.assertEqual(self.fake.calls, [])

    def test_fixture_cannot_reach_real_subprocess_execution(self):
        adapter = self.make_adapter(fixture_transport=False)
        self.assert_code("FIXTURE_EXECUTION_FORBIDDEN", lambda: adapter.run("generate", self.principal,
            self.snapshot, self.job, mode="execute", max_calls=2, authorization=self.auth()))
        self.assertEqual(self.fake.calls, [])

    def test_fake_execute_returns_only_marked_artifact_reference(self):
        result = self.run_paid()
        self.assertEqual(result.status, "needs_review")
        self.assertEqual(result.model_connection, "not_verified_fixture")
        self.assertFalse(result.ready_for_student)
        self.assertEqual(result.artifact_refs[0].kind, "generation")
        serialized = json.dumps(asdict(result))
        self.assertNotIn("DO_NOT_RETURN", serialized)
        self.assertNotIn(str(self.root), serialized)
        self.assertNotIn("OFFLINE_FIXTURE_NOT_A_SECRET", serialized)

    def test_same_idempotency_key_reuses_without_another_dispatch(self):
        first = self.run_paid()
        self.assertEqual(first, self.run_paid())
        # A new adapter instance uses the durable ledger too.
        other = self.make_adapter()
        second = other.run("generate", self.principal, self.snapshot, self.job,
                           mode="execute", max_calls=2, authorization=self.auth())
        self.assertEqual(first, second)
        self.assertEqual(len(self.fake.calls), 1)

    def test_idempotency_cannot_change_inputs_or_create_new_job(self):
        self.adapter.run("generate", self.principal, self.snapshot, self.job)
        for snapshot, job in ((replace(self.snapshot, requirements=("changed",)), self.job),
                              (self.snapshot, replace(self.job, job_id="another-job"))):
            self.assert_code("IDEMPOTENCY_CONFLICT", lambda: self.adapter.run("generate", self.principal, snapshot, job))

    def test_preview_job_cannot_be_promoted_to_execute(self):
        self.adapter.run("generate", self.principal, self.snapshot, self.job)
        self.assert_code("IDEMPOTENCY_CONFLICT", self.run_paid)

    def test_timeout_stays_unknown_and_is_not_retried(self):
        self.fake.timeout = True
        first = self.run_paid()
        self.assertEqual(first.status, "unknown")
        self.assertEqual(first, self.run_paid())
        self.assertEqual(len(self.fake.calls), 1)

    def test_revoke_during_execution_discards_all_artifact_references(self):
        self.fake.callback = lambda: setattr(self, "current", CurrentContext(4, 2, False))
        result = self.run_paid()
        self.assertEqual(result.status, "discarded")
        self.assertEqual(result.error_code, "CONTEXT_REVOKED")
        self.assertEqual(result.artifact_refs, ())

    def test_version_change_during_execution_discards_result(self):
        self.fake.callback = lambda: setattr(self, "current", CurrentContext(4, 3, True))
        result = self.run_paid()
        self.assertEqual(result.status, "discarded")
        self.assertEqual(result.error_code, "STALE_CONTEXT")

    def test_revoked_context_cannot_replay_a_previous_success(self):
        self.run_paid()
        self.current = CurrentContext(4, 2, False)
        self.assert_code("CONTEXT_REVOKED", self.run_paid)

    def test_upstream_error_does_not_leak_stderr(self):
        self.fake.returncode = 1
        result = self.run_paid()
        self.assertEqual(result.error_code, "UPSTREAM_FAILED")
        self.assertNotIn("DO_NOT_RETURN", json.dumps(asdict(result)))

    def test_changed_configuration_cannot_reuse_paid_job(self):
        self.run_paid()
        self.env.write_text("ZZZ_API_KEY=DIFFERENT_OFFLINE_FIXTURE\n")
        self.assert_code("IDEMPOTENCY_CONFLICT", self.run_paid)
        self.assertEqual(len(self.fake.calls), 1)

    def test_unapproved_generation_cannot_return_ready_for_student(self):
        def bad_result(argv, **kwargs):
            completed = self.fake(argv, **kwargs)
            path = Path(argv[argv.index("--output") + 1]) / "generation.json"
            data = json.loads(path.read_text())
            data["ready_for_student"] = True
            path.write_text(json.dumps(data))
            return completed
        self.adapter = self.make_adapter(transport=bad_result)
        result = self.run_paid()
        self.assertEqual(result.status, "failed")
        self.assertEqual(result.error_code, "INVALID_RESULT")
        self.assertEqual(result.artifact_refs, ())

    def test_fixture_recommend_profile_update_return_only_expected_references(self):
        row = {"record_id": "fixture-row", "student_id": "student-fixture", "split": "train",
               "problem_id": "fixture-problem", "question": "OFFLINE FIXTURE", "program": "NOT_EXECUTABLE",
               "source": {"file": "fixture-source", "index": 0}}
        for operation, kinds in (("recommend", ("recommendation",)), ("profile", ("profile",)),
                                 ("update", ("update", "profile"))):
            job = replace(self.job, job_id="fake-" + operation, idempotency_key="fake-" + operation)
            snapshot = replace(self.snapshot, records=(row,) if operation != "recommend" else (),
                profile={"student_id": "student-fixture", "status": "completed"} if operation == "update" else None)
            result = self.adapter.run(operation, self.principal, snapshot, job, mode="execute", max_calls=2,
                authorization=self.auth(operation=operation, snapshot=snapshot, job=job))
            self.assertEqual(tuple(ref.kind for ref in result.artifact_refs), kinds)
            self.assertEqual(result.model_connection, "not_verified_fixture")

    def test_test_split_cannot_be_profile_evidence(self):
        snapshot = replace(self.snapshot, records=({"student_id": "student-fixture", "split": "test"},))
        self.assert_code("INELIGIBLE_EVIDENCE", lambda: self.adapter.run("profile", self.principal, snapshot, self.job))

    def test_requirement_text_cannot_add_another_cli_switch(self):
        snapshot = replace(self.snapshot, requirements=("--execute", "$(touch /tmp/should-not-exist)"))
        self.adapter.run("generate", self.principal, snapshot, self.job)
        argv = self.fake.calls[0][0]
        self.assertNotIn("--execute", argv)
        self.assertIn("--requirement=--execute", argv)

    def test_path_traversal_job_id_rejected(self):
        self.assert_code("INVALID_IDENTIFIER", lambda: self.adapter.run("generate", self.principal,
            self.snapshot, replace(self.job, job_id="../escape")))

    def test_partial_or_cross_student_baseline_rejected(self):
        for profile, code in (({"student_id": "someone-else", "status": "completed"}, "PROFILE_SUBJECT_MISMATCH"),
                              ({"student_id": "student-fixture", "status": "partial"}, "INCOMPLETE_PROFILE")):
            self.assert_code(code, lambda: self.adapter.run("recommend", self.principal,
                replace(self.snapshot, profile=profile), self.job))

    def test_correction_marks_separate_projection_stale(self):
        previous = LearningEvidenceProjection("course-fixture", "student-fixture", ("result-v1",), "current")
        updated = previous.correct_result("result-v1", "result-v2")
        self.assertEqual(updated.research_status, "stale")
        self.assertEqual(updated.mastery_state, "Unknown")
        self.assertIsNone(updated.model_id)
        self.assertEqual(updated.schema, "learning-evidence-projection-v1")
        self.assertEqual(updated.effective_result_ids, ("result-v2",))
        self.assertEqual(previous.effective_result_ids, ("result-v1",))

    def test_correction_cannot_duplicate_an_effective_version(self):
        previous = LearningEvidenceProjection("course-fixture", "student-fixture", ("v1", "v2"))
        self.assert_code("DUPLICATE_RESULT_VERSION", lambda: previous.correct_result("v1", "v2"))

    def test_projection_model_identity_cannot_be_overridden(self):
        with self.assertRaises(TypeError):
            LearningEvidenceProjection("course-fixture", "student-fixture", model_id="invented-model")

    def test_all_four_real_cli_previews_need_no_model_or_java(self):
        """Only actual subprocess calls in this suite: explicit preview, no env."""
        adapter = ResearchAdapter(self.root / "real-preview", lambda *args: self.current)
        fixture_row = {"record_id": "fixture-row", "student_id": "student-fixture", "split": "train",
                       "problem_id": "fixture-problem", "question": "OFFLINE FIXTURE: 判断 true && false",
                       "program": "OFFLINE_FIXTURE_NOT_EXECUTABLE", "source": {"file": "fixture-source", "index": 0}}
        base = {"status": "completed", "student_id": "student-fixture", "model_id": "fixture-only",
                "prompt_version": "fixture-only", "concepts": self.catalog["concepts"],
                "evidence": [], "observations": [], "summaries": {}, "failed_steps": []}
        for operation in ("generate", "recommend", "profile", "update"):
            snapshot = replace(self.snapshot, records=(fixture_row,) if operation in ("profile", "update") else (),
                               profile=base if operation == "update" else None)
            job = replace(self.job, job_id="preview-" + operation, idempotency_key="preview-" + operation)
            with self.subTest(operation=operation):
                result = adapter.run(operation, self.principal, snapshot, job)
                self.assertEqual(result.status, "previewed", asdict(result))
                self.assertEqual(result.model_connection, "not_verified")
                self.assertEqual(result.artifact_refs, ())


if __name__ == "__main__":
    unittest.main()
