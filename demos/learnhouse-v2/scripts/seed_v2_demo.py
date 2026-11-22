"""Idempotent, explicitly synthetic fixtures for the isolated V2 Demo database.

Run with the LearnHouse API venv. Credentials are generated once into a private
ignored file; no passwords, tokens or model configuration are printed.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import secrets
import sys
from datetime import datetime, timezone, timedelta
from uuid import UUID, uuid5

ROOT = Path(__file__).resolve().parents[1]
API = ROOT / "upstream/learnhouse/apps/api"
sys.path.insert(0, str(API))

from pwdlib import PasswordHash
from sqlalchemy import MetaData, Table, create_engine, select, text
from sqlalchemy.engine import make_url
from sqlmodel import Session
from src.db.users import User
from src.db.roles import Role, RoleTypeEnum, Rights
from src.db.organizations import Organization
from src.db.user_organizations import UserOrganization
from src.db.courses.courses import Course
from src.db.courses.activities import Activity, ActivityTypeEnum, ActivitySubTypeEnum, ActivityLockType
from src.db.courses.chapters import Chapter, LockType
from src.db.courses.assignments import Assignment, GradingTypeEnum
from src.db.usergroups import UserGroup
from src.db.usergroup_user import UserGroupUser
from src.db.usergroup_resources import UserGroupResource

SEED = "education-v2-demo-v1"
NS = UUID("67b3987f-a87d-4d04-82e7-7777b8f65bea")
RUNTIME = ROOT / ".runtime"
PRIVATE = RUNTIME / "demo-accounts.local.json"
PUBLIC = RUNTIME / "demo-seed-summary.json"
DEFAULT_URL = "postgresql+psycopg:///learnhouse_v2_demo?host=/tmp/edu-v2-pg-20261120&port=55443"
ACCOUNT_SPECS = [
    ("student_a", "学生林同学", "student.a@example.com", "student"),
    ("student_b", "学生陈同学", "student.b@example.com", "student"),
    ("teacher_a", "教师周老师", "teacher.a@example.com", "teacher"),
    ("teacher_b", "教师吴老师", "teacher.b@example.com", "teacher"),
    ("admin", "平台管理员", "education.admin@example.com", "admin"),
]


def uid(name: str) -> UUID:
    return uuid5(NS, SEED + ":" + name)


def digest(value) -> str:
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def private_write(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    tmp = path.with_name(path.name + ".tmp")
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(value, f, ensure_ascii=False, indent=2, default=str)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
        path.chmod(0o600)
    finally:
        if tmp.exists():
            tmp.unlink()


def load_credentials() -> dict:
    if PRIVATE.exists():
        if PRIVATE.stat().st_mode & 0o077:
            raise RuntimeError("Credential file permissions must be 0600")
        value = json.loads(PRIVATE.read_text())
        if value.get("version") != SEED:
            raise RuntimeError("Existing seed credential version differs; refusing reset")
        return value
    value = {"version": SEED, "provenance": "demo", "accounts": [
        {"key": key, "label": label, "email": email, "role": role,
         "password": secrets.token_urlsafe(18)}
        for key, label, email, role in ACCOUNT_SPECS
    ]}
    private_write(PRIVATE, value)
    return value


def seed() -> dict:
    url = make_url(os.environ.get("EDUCATION_DEMO_DATABASE_URL", DEFAULT_URL))
    if url.database != "learnhouse_v2_demo":
        raise RuntimeError("This script is restricted to the isolated learnhouse_v2_demo database")
    credentials = load_credentials()
    accounts = {a["key"]: a for a in credentials["accounts"]}
    if set(accounts) != {a[0] for a in ACCOUNT_SPECS}:
        raise RuntimeError("Credential identities differ from the fixed Demo account set")
    engine = create_engine(url, pool_pre_ping=True, hide_parameters=True)
    meta = MetaData(schema="ea")
    names = ("principal", "action_grant", "policy_version", "knowledge_point", "resource", "resource_version", "rubric_version", "content_check", "publication_event", "assignment_binding", "assignment_recipient")
    tables = {name: Table(name, meta, autoload_with=engine) for name in names}
    stamp = datetime.now(timezone.utc).isoformat()
    with Session(engine, expire_on_commit=False) as session, session.begin():
        if session.execute(text("SELECT current_database() ")).scalar_one() != "learnhouse_v2_demo":
            raise RuntimeError("Unexpected database")
        # Serialize this provisioning operation. Do not bypass business guards.
        session.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": 23814611})
        # Upstream bootstrap inserts fixed role IDs without advancing this
        # sequence. This task-only database must allow the first custom role.
        session.execute(text("SELECT setval(pg_get_serial_sequence('public.role','id'), GREATEST(COALESCE((SELECT max(id) FROM public.role),1),nextval(pg_get_serial_sequence('public.role','id'))),true)"))
        org = session.exec(select(Organization).where(Organization.slug == "default")).scalar_one()
        org_id = org.id
        empty_rights = {key: field.annotation(**{name: False for name in field.annotation.model_fields}).model_dump()
                        for key, field in Rights.model_fields.items()}
        role = session.exec(select(Role).where(Role.role_uuid == "role_" + str(uid("restricted-role")))).scalar_one_or_none()
        if role is None:
            role = Role(name="教育 Demo 受限成员", description="所有教学动作由 ea 范围授权；上游 CRUD 均关闭", rights=empty_rights,
                        org_id=org_id, role_type=RoleTypeEnum.TYPE_ORGANIZATION,
                        role_uuid="role_" + str(uid("restricted-role")), creation_date=stamp, update_date=stamp)
            session.add(role); session.flush()
        if role.id in (1, 2) or role.rights != empty_rights:
            raise RuntimeError("Demo role must have no legacy CRUD privileges")
        password_hash = PasswordHash.recommended()

        def ensure(name: str, ident: UUID, values: dict) -> UUID:
            table = tables[name]
            old = session.execute(select(table).where(table.c.id == ident)).mappings().first()
            if old is None:
                session.execute(table.insert().values(id=ident, **values))
            elif old["org_id"] != org_id:
                raise RuntimeError("Seed ID belongs to a different organization")
            return ident

        for key, label, email, role_name in ACCOUNT_SPECS:
            account = accounts[key]
            if account["email"] != email or account["role"] != role_name or len(account["password"]) < 20:
                raise RuntimeError("Private account file has an unexpected identity or password")
            user = session.exec(select(User).where(User.email == email)).scalar_one_or_none()
            if user is None:
                user = User(username=key, first_name=label, last_name="", email=email,
                            password=password_hash.hash(account["password"]), user_uuid="user_"+str(uid(key)),
                            email_verified=True, is_backoffice_staff=False,
                            extra_metadata={"education_demo_seed": SEED, "provenance": "demo"},
                            creation_date=stamp, update_date=stamp)
                session.add(user); session.flush()
            elif (user.extra_metadata or {}).get("education_demo_seed") != SEED:
                raise RuntimeError("A non-Demo user already owns a seed email; refusing overwrite")
            if user.is_backoffice_staff or not password_hash.verify(account["password"], user.password):
                raise RuntimeError("Existing Demo identity or password differs; refusing silent reset")
            membership = session.exec(select(UserOrganization).where(UserOrganization.user_id == user.id, UserOrganization.org_id == org_id)).scalar_one_or_none()
            if membership is None:
                session.add(UserOrganization(user_id=user.id, org_id=org_id, role_id=role.id, creation_date=stamp, update_date=stamp))
            elif membership.role_id != role.id:
                raise RuntimeError("Existing Demo member unexpectedly has another upstream role")
            principal = ensure("principal", uid("principal:"+key), {"org_id": org_id, "kind": "human", "user_id": user.id})
            account.update(user_id=user.id, principal_id=str(principal), upstream_role_id=role.id)
        session.flush()
        worker = ensure("principal", uid("worker"), {"org_id": org_id, "kind": "service", "service_name": "education-demo-worker"})
        provisioner = ensure("principal", uid("provisioner"), {"org_id": org_id, "kind": "service", "service_name": "education-demo-provisioner"})

        def grant(account_key: str, action: str, course_id=None, class_id=None):
            account = accounts[account_key]
            ensure("action_grant", uid("grant:"+account_key+":"+action+":"+str(course_id)), {
                "org_id": org_id, "principal_id": UUID(account["principal_id"]), "course_id": course_id,
                "usergroup_id": class_id, "action": action, "granted_by": worker, "approved_by": provisioner,
                "reason": "演示初始化授权；受限服务签发的合成配置，不代表真实教师审批"})

        for action in ("access.manage", "policy.manage", "operations.manage", "audit.metadata"):
            grant("admin", action)
        global_rules = {"allowed_generation_modes": ["rule_template", "research_generator"],
                        "required_checks": ["schema", "source_ready", "scope", "answer_consistency", "rubric_bounds", "boolean_truth_table"],
                        "require_human_review": True, "allow_rule_auto_publish": True,
                        "maximum_task_budget": 0, "maximum_task_attempts": 1, "allow_review": True}
        global_policy = ensure("policy_version", uid("global-policy-v1"), {
            "org_id": org_id, "family_id": uid("global-policy"), "version": 1, "policy_type": "global",
            "rules": global_rules, "content_hash": digest(global_rules), "created_by": UUID(accounts["admin"]["principal_id"])})
        courses = []
        for suffix, title, class_name, lesson in [
            ("a", "Java 程序设计：条件与分支", "Java 入门 A 班", "布尔表达式由 true、false 及逻辑运算组成。&& 和 || 使用短路求值；if 分支根据条件选择执行路径。"),
            ("b", "Java 程序设计：循环基础", "Java 入门 B 班", "for 与 while 可以重复执行代码。循环条件在适当时机检查；分析循环时应说明初值、条件、更新和终止。"),
        ]:
            teacher = accounts["teacher_"+suffix]; student = accounts["student_"+suffix]
            course = session.exec(select(Course).where(Course.course_uuid == "course_"+str(uid("course:"+suffix)))).scalar_one_or_none()
            if course is None:
                course = Course(name=title, description="教育智能体 V2 本地演示课程，所有学习数据均为演示数据。", public=False,
                                published=True, open_to_contributors=False, org_id=org_id,
                                course_uuid="course_"+str(uid("course:"+suffix)), slug="education-demo-"+suffix,
                                creation_date=stamp, update_date=stamp, extra_metadata={"education_demo_seed":SEED})
                session.add(course);session.flush()
            if course.org_id != org_id:raise RuntimeError("Course organization mismatch")
            group = session.exec(select(UserGroup).where(UserGroup.usergroup_uuid == "usergroup_"+str(uid("class:"+suffix)))).scalar_one_or_none()
            if group is None:
                group=UserGroup(name=class_name,description="演示手工班级，互相隔离",org_id=org_id,kind="manual",
                                usergroup_uuid="usergroup_"+str(uid("class:"+suffix)),creation_date=stamp,update_date=stamp)
                session.add(group);session.flush()
            if session.exec(select(UserGroupUser).where(UserGroupUser.usergroup_id==group.id, UserGroupUser.user_id==student["user_id"])).scalar_one_or_none() is None:
                session.add(UserGroupUser(org_id=org_id,usergroup_id=group.id,user_id=student["user_id"],sources=["manual"],creation_date=stamp,update_date=stamp))
            if session.exec(select(UserGroupResource).where(UserGroupResource.usergroup_id==group.id,UserGroupResource.resource_uuid==course.course_uuid)).scalar_one_or_none() is None:
                session.add(UserGroupResource(org_id=org_id,usergroup_id=group.id,resource_uuid=course.course_uuid,creation_date=stamp,update_date=stamp))
            for action in ("course.edit","content.read","content.generate","content.edit","content.review","content.publish","task.manage","submission.grade","result.review","profile.read","intervention.write","evidence.read","export.read"):
                grant("teacher_"+suffix,action,course.id,group.id)
            grant("teacher_"+suffix,"course.create")
            course_rules=dict(global_rules)
            policy=ensure("policy_version",uid("course-policy:"+suffix),{"org_id":org_id,"course_id":course.id,"family_id":uid("course-policy-family:"+suffix),"version":1,"parent_policy_id":global_policy,"policy_type":"course","rules":course_rules,"content_hash":digest(course_rules),"created_by":UUID(teacher["principal_id"])})
            points=[]
            for code,label in ([('java.boolean','布尔表达式'),('java.condition','条件与分支')] if suffix=='a' else [('java.loop','循环结构')]):
                point=ensure("knowledge_point",uid("knowledge:"+suffix+":"+code),{"org_id":org_id,"course_id":course.id,"code":code,"version":1,"label":label,"definition":{"provenance":"demo","description":label}})
                points.append({"id":str(point),"code":code,"label":label})
            activity=session.exec(select(Activity).where(Activity.activity_uuid=="activity_"+str(uid("source-activity:"+suffix)))).scalar_one_or_none()
            if activity is None:
                activity=Activity(name="课程学习材料",activity_type=ActivityTypeEnum.TYPE_DOCUMENT,activity_sub_type=ActivitySubTypeEnum.SUBTYPE_DOCUMENT_DOC,content={},published=False,lock_type=ActivityLockType.RESTRICTED,org_id=org_id,course_id=course.id,activity_uuid="activity_"+str(uid("source-activity:"+suffix)),creation_date=stamp,update_date=stamp)
                session.add(activity);session.flush()
            resource=ensure("resource",uid("source:"+suffix),{"org_id":org_id,"course_id":course.id,"activity_id":activity.id,"kind":"source_text","title":"学习材料 · "+title,"owner_id":UUID(teacher["principal_id"])})
            content={"title":title,"body_text":lesson,"questions":[],"knowledge_point_ids":[p['id'] for p in points],"source_refs":[]}
            version=ensure("resource_version",uid("source-version:"+suffix),{"org_id":org_id,"course_id":course.id,"resource_id":resource,"version":1,"policy_version_id":policy,"content":content,"restricted_content":{},"content_hash":digest(content),"processing_state":"ready","generation_mode":"teacher","provenance":"demo","source_manifest":{"seed":SEED},"forced_review":True,"created_by":UUID(teacher["principal_id"])})
            validation=ensure("content_check",uid("source-check:"+suffix),{"org_id":org_id,"course_id":course.id,"resource_version_id":version,"policy_version_id":policy,"check_kind":"deterministic","verdict":"pass","checks":{"demo":True,"nonempty":True},"checker_version":SEED,"actor_id":worker})
            review=ensure("content_check",uid("source-review:"+suffix),{"org_id":org_id,"course_id":course.id,"resource_version_id":version,"policy_version_id":policy,"check_kind":"human_review","verdict":"approve","checks":{"seeded_demo_review":True},"checker_version":SEED,"actor_id":UUID(teacher["principal_id"]),"reason":"预置演示材料的合成审核记录；非真实教学审批"})
            publication=ensure("publication_event",uid("source-publication:"+suffix),{"org_id":org_id,"course_id":course.id,"resource_version_id":version,"usergroup_id":group.id,"event_no":1,"action":"publish","validation_id":validation,"review_id":review,"policy_version_id":policy,"actor_id":UUID(teacher["principal_id"]),"reason":"向演示班级发布预置学习材料"})
            criteria=[{"criterion_id":"c1","item_id":"q1","description":"判断是否正确","maximum_score":50,"knowledge_point_ids":[points[0]['id']]},
                      {"criterion_id":"c2","item_id":"q2","description":"解释是否清晰、依据是否完整","maximum_score":50,"knowledge_point_ids":[points[-1]['id']]}]
            rubric=ensure("rubric_version",uid("rubric:"+suffix),{"org_id":org_id,"course_id":course.id,"family_id":uid("rubric-family:"+suffix),"version":1,"criteria":criteria,"maximum_score":100,"content_hash":digest(criteria),"created_by":UUID(teacher["principal_id"])})
            chapter=session.exec(select(Chapter).where(Chapter.chapter_uuid=='chapter_'+str(uid('chapter:'+suffix)))).scalar_one_or_none()
            if chapter is None:
                chapter=Chapter(name="基础练习",description="V2 演示章节",org_id=org_id,course_id=course.id,lock_type=LockType.RESTRICTED,chapter_uuid='chapter_'+str(uid('chapter:'+suffix)),creation_date=stamp,update_date=stamp)
                session.add(chapter);session.flush()
            assignment_activity=session.exec(select(Activity).where(Activity.activity_uuid=='activity_'+str(uid('assignment-activity:'+suffix)))).scalar_one_or_none()
            if assignment_activity is None:
                assignment_activity=Activity(name="基础诊断练习",activity_type=ActivityTypeEnum.TYPE_ASSIGNMENT,activity_sub_type=ActivitySubTypeEnum.SUBTYPE_ASSIGNMENT_ANY,content={},published=False,lock_type=ActivityLockType.RESTRICTED,org_id=org_id,course_id=course.id,activity_uuid='activity_'+str(uid('assignment-activity:'+suffix)),creation_date=stamp,update_date=stamp)
                session.add(assignment_activity);session.flush()
            assignment=session.exec(select(Assignment).where(Assignment.assignment_uuid=='assignment_'+str(uid('assignment:'+suffix)))).scalar_one_or_none()
            if assignment is None:
                assignment=Assignment(title="基础诊断：判断与解释",description="包含判断题和简答题；判断题可给出规则建议，最终由教师批阅。",grading_type=GradingTypeEnum.NUMERIC,published=False,auto_grading=False,org_id=org_id,course_id=course.id,chapter_id=chapter.id,activity_id=assignment_activity.id,assignment_uuid='assignment_'+str(uid('assignment:'+suffix)),creation_date=stamp,update_date=stamp)
                session.add(assignment);session.flush()
            exercise=ensure('resource',uid('exercise:'+suffix),{'org_id':org_id,'course_id':course.id,'activity_id':assignment_activity.id,'kind':'exercise','title':'基础诊断：判断与解释','owner_id':UUID(teacher['principal_id'])})
            prompt='表达式 true || false 的结果为 true。' if suffix=='a' else 'while 循环开始前会先检查条件。'
            qcontent={'title':'基础诊断：判断与解释','body_text':'完成两道题。你的提交将保留为独立版本，简答题由教师批阅。','questions':[
                {'item_id':'q1','type':'boolean','prompt':prompt,'maximum_score':50,'knowledge_point_ids':[points[0]['id']], 'choices':[], 'language':None},
                {'item_id':'q2','type':'short_answer','prompt':'用自己的话解释本节的执行规则，并举一个简单例子。','maximum_score':50,'knowledge_point_ids':[points[-1]['id']], 'choices':[], 'language':None}],
                'knowledge_point_ids':[p['id'] for p in points],'source_refs':[]}
            answers={'answers':[{'item_id':'q1','value':True,'rationale':'该判断符合课程材料说明。'}],'grading_notes':'简答题须人工评估依据与表达，不能仅按关键词给最终成绩。'}
            ex_version=ensure('resource_version',uid('exercise-version:'+suffix),{'org_id':org_id,'course_id':course.id,'resource_id':exercise,'version':1,'source_version_id':version,'policy_version_id':policy,'content':qcontent,'restricted_content':answers,'content_hash':digest({'content':qcontent,'restricted_content':answers}),'processing_state':'ready','generation_mode':'teacher','provenance':'demo','source_manifest':{'seed':SEED},'forced_review':True,'created_by':UUID(teacher['principal_id'])})
            ex_check=ensure('content_check',uid('exercise-check:'+suffix),{'org_id':org_id,'course_id':course.id,'resource_version_id':ex_version,'policy_version_id':policy,'check_kind':'deterministic','verdict':'pass','checks':{'demo':True,'item_ids_unique':True,'score_total':100},'checker_version':SEED,'actor_id':worker})
            ex_review=ensure('content_check',uid('exercise-review:'+suffix),{'org_id':org_id,'course_id':course.id,'resource_version_id':ex_version,'policy_version_id':policy,'check_kind':'human_review','verdict':'approve','checks':{'seeded_demo_review':True},'checker_version':SEED,'actor_id':UUID(teacher['principal_id']),'reason':'预置演示练习的合成审核记录；非真实教学审批'})
            ex_publish=ensure('publication_event',uid('exercise-publication:'+suffix),{'org_id':org_id,'course_id':course.id,'resource_version_id':ex_version,'usergroup_id':group.id,'event_no':1,'action':'publish','validation_id':ex_check,'review_id':ex_review,'policy_version_id':policy,'actor_id':UUID(teacher['principal_id']),'reason':'向演示班级发布基础诊断练习'})
            now=datetime.now(timezone.utc)
            binding=ensure('assignment_binding',uid('binding:'+suffix),{'org_id':org_id,'course_id':course.id,'assignment_id':assignment.id,'version':1,'resource_version_id':ex_version,'rubric_version_id':rubric,'policy_version_id':policy,'publication_event_id':ex_publish,'usergroup_id':group.id,'opens_at':now-timedelta(days=1),'due_at':now+timedelta(days=30),'max_attempts':2,'answer_release':'after_effective','allow_review':True,'rules_snapshot':{'title':assignment.title,'description':assignment.description,'provenance':'demo'},'created_by':UUID(teacher['principal_id'])})
            recipient=ensure('assignment_recipient',uid('recipient:'+suffix),{'org_id':org_id,'course_id':course.id,'binding_id':binding,'student_id':student['user_id'],'usergroup_id':group.id,'membership_snapshot':{'provenance':'demo','seed':SEED,'direct_membership':True}})
            courses.append({"key":suffix,"id":course.id,"name":title,"course_uuid":course.course_uuid,"class_id":group.id,"class_name":group.name,"teacher_key":"teacher_"+suffix,"student_key":"student_"+suffix,"policy_id":str(policy),"rubric_id":str(rubric),"source_resource_id":str(resource),"source_version_id":str(version),"publication_id":str(publication),"activity_id":activity.id,"activity_uuid":activity.activity_uuid,"knowledge_points":points,'exercise_resource_id':str(exercise),'exercise_version_id':str(ex_version),'binding_id':str(binding),'recipient_id':str(recipient)})
        session.flush()
    engine.dispose()
    credentials.update(org_id=org_id,objects={"courses":courses,"global_policy_id":str(global_policy),"service_principal_id":str(worker),"provisioner_id":str(provisioner)})
    private_write(PRIVATE,credentials)
    public={**credentials,"accounts":[{k:v for k,v in a.items() if k!='password'} for a in credentials['accounts']]}
    private_write(PUBLIC,public)
    return {"status":"seeded","provenance":"demo","accounts":len(accounts),"courses":len(courses),"classes":len(courses),"legacy_role_id":role.id,"credentials_file":".runtime/demo-accounts.local.json","summary_file":".runtime/demo-seed-summary.json"}


if __name__ == '__main__':
    print(json.dumps(seed(),ensure_ascii=False,indent=2))
