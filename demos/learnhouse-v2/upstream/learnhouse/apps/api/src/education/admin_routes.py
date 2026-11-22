"""Identity, administrative metadata and private-note routes for V2."""
from datetime import datetime, timezone, timedelta
from uuid import UUID, uuid4
from fastapi import APIRouter, Depends, Request
from src.core.events.database import get_db_session
from src.education.security import Actor, require_actor, require_course, require_admin, fail, TEACHING_ACTIONS, ADMIN_ACTIONS
from src.education.business import rows, one, execute, clean, digest, etag, matching, validate, write_once, must, canonical

router=APIRouter()
PAGE={'has_more':False,'next_cursor':None}


def capabilities():
    return [{'name':n,'status':'unconfigured','reason_code':'DEMO_OFFLINE'} for n in ['research_generator','ai_evaluation','research_profile','research_recommendation','course_qa','code_execution']]


def scope(g):
    return {k:g[k] for k in ['org_id','course_id','usergroup_id','student_id','action']}


async def note_permissions(db,actor):
    result=await rows(db,'SELECT id,note_id,student_id,course_id,purpose,grantee_id,consent_revision,expires_at,revoked_at FROM ea.note_permission WHERE student_id=:u AND org_id=:o ORDER BY created_at,id',u=actor.user_id,o=actor.org_id)
    return clean([dict(r,etag=etag(str(r['id'])+':'+str(r['revoked_at']))) for r in result])


@router.get('/session')
async def session(actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    notes=await note_permissions(db,actor)
    return clean({'principal':{'id':actor.principal_id,'org_id':actor.org_id,'user_id':actor.user_id,'kind':'human','display_name':actor.name,'disabled_at':None,'role_views':['administrator' if actor.role=='admin' else actor.role]},'scopes':[scope(g) for g in actor.grants],'capabilities':capabilities(),'csrf_mode':'same_origin_enforced','upstream_login_path':'/api/v1/auth/login','upstream_logout_path':'/api/v1/auth/logout','own_note_permissions':notes,'own_note_permissions_etag':etag(digest(notes))})


async def scopes_view(db,actor):
    require_admin(actor,'access.manage')
    accounts=await rows(db,"SELECT p.id,p.org_id,p.user_id,p.disabled_at,u.username FROM ea.principal p JOIN public.\"user\" u ON u.id=p.user_id WHERE p.org_id=:o AND p.kind='human' ORDER BY p.user_id",o=actor.org_id)
    grants=await rows(db,'SELECT * FROM ea.action_grant WHERE org_id=:o ORDER BY created_at,id',o=actor.org_id)
    principals=[]
    now=datetime.now(timezone.utc)
    for p in accounts:
        acts={g['action'] for g in grants if g['principal_id']==p['id'] and not g['revoked_at'] and g['starts_at']<=now and (not g['expires_at'] or g['expires_at']>now)}
        role='administrator' if acts & ADMIN_ACTIONS else ('teacher' if acts & TEACHING_ACTIONS else 'student')
        principals.append({'id':p['id'],'org_id':p['org_id'],'user_id':p['user_id'],'kind':'human','display_name':p['username'],'disabled_at':p['disabled_at'],'role_views':[role]})
    classes=[]
    for g in await rows(db,'SELECT id,name FROM public.usergroup WHERE org_id=:o ORDER BY id',o=actor.org_id):
        members=await rows(db,"SELECT m.user_id AS student_id,u.username AS display_name,(m.expires_at IS NULL OR m.expires_at>now()) AS membership_active FROM public.usergroupuser m JOIN public.\"user\" u ON u.id=m.user_id WHERE m.org_id=:o AND m.usergroup_id=:g ORDER BY m.user_id",o=actor.org_id,g=g['id'])
        classes.append({'usergroup_id':g['id'],'name':g['name'],'members':members})
    records=[{'id':g['id'],'principal_id':g['principal_id'],'scope':scope(g),**{k:g[k] for k in ['starts_at','expires_at','revoked_at','granted_by','approved_by','reason']}} for g in grants]
    courses=await rows(db,'SELECT id,name FROM public.course WHERE org_id=:o ORDER BY id',o=actor.org_id)
    result=clean({'principals':principals,'grants':records,'classes':classes,'courses':courses,'page':PAGE})
    return dict(result,etag=etag(digest(result)))


@router.get('/admin/scopes')
async def get_scopes(actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    return await scopes_view(db,actor)


def command_result(operation,ids,version='done'):
    return {'operation':operation,'result_ids':[str(i) for i in ids],'request_id':str(uuid4()),'etag':etag(version)}


@router.post('/admin/scopes/commands')
async def change_scopes(request:Request,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    require_admin(actor,'access.manage');data=validate('ScopeCommand',await request.json())
    async def change():
        await execute(db,"SELECT pg_advisory_xact_lock(hashtextextended(:k,0))",k='scope:'+str(actor.org_id))
        matching(request,(await scopes_view(db,actor))['etag'])
        action=data['command']
        if action=='revoke':
            grant=must(await one(db,'SELECT * FROM ea.action_grant WHERE id=:i AND org_id=:o FOR UPDATE',i=data['grant_id'],o=actor.org_id))
            if str(grant['principal_id'])==actor.principal_id:fail('SELF_ESCALATION_DENIED',403)
            if not grant['revoked_at']:
                await execute(db,'UPDATE ea.action_grant SET revoked_at=now(),revoked_by=:a WHERE id=:i',a=actor.principal_id,i=grant['id'])
            return command_result('revoke',[grant['id']])
        if action=='grant':
            if data['principal_id']==actor.principal_id:fail('SELF_ESCALATION_DENIED',403)
            if data['action'] not in TEACHING_ACTIONS:fail('DELEGATION_NOT_AVAILABLE',403,'演示后台仅委派教学范围，不创建系统管理员')
            target=must(await one(db,"SELECT id FROM ea.principal WHERE id=:i AND org_id=:o AND kind='human' AND disabled_at IS NULL",i=data['principal_id'],o=actor.org_id))
            if data['course_id'] is None:
                if data['action']!='course.create' or data['usergroup_id'] is not None or data['student_id'] is not None:fail('INVALID_SCOPE',422)
            else:
                must(await one(db,'SELECT id FROM public.course WHERE id=:i AND org_id=:o',i=data['course_id'],o=actor.org_id))
                if data['usergroup_id'] is not None:
                    must(await one(db,'SELECT r.id FROM public.usergroupresource r JOIN public.course c ON c.course_uuid=r.resource_uuid AND c.org_id=r.org_id WHERE r.usergroup_id=:g AND c.id=:c AND c.org_id=:o',g=data['usergroup_id'],c=data['course_id'],o=actor.org_id))
                if data['student_id'] is not None:
                    must(await one(db,'SELECT id FROM public.userorganization WHERE user_id=:u AND org_id=:o',u=data['student_id'],o=actor.org_id))
            starts=datetime.fromisoformat(data['starts_at'].replace('Z','+00:00'))
            expires=datetime.fromisoformat(data['expires_at'].replace('Z','+00:00')) if data['expires_at'] else None
            if expires and expires<=starts:fail('INVALID_TIME_WINDOW',422)
            inserted=await one(db,'INSERT INTO ea.action_grant(org_id,principal_id,course_id,usergroup_id,student_id,action,granted_by,approved_by,reason,starts_at,expires_at) VALUES(:o,:p,:c,:g,:s,:a,:by,:by,:reason,:starts,:expires) RETURNING id',o=actor.org_id,p=target['id'],c=data['course_id'],g=data['usergroup_id'],s=data['student_id'],a=data['action'],by=actor.principal_id,reason=data['reason'],starts=starts,expires=expires)
            return command_result('grant',[inserted['id']])
        # Membership edits affect current access immediately; historical recipients remain.
        must(await one(db,'SELECT r.id FROM public.usergroupresource r JOIN public.course c ON c.course_uuid=r.resource_uuid AND c.org_id=r.org_id WHERE r.usergroup_id=:g AND c.id=:c AND c.org_id=:o',g=data['usergroup_id'],c=data['course_id'],o=actor.org_id))
        principal=must(await one(db,"SELECT id FROM ea.principal WHERE user_id=:u AND org_id=:o AND kind='human' AND disabled_at IS NULL",u=data['student_id'],o=actor.org_id))
        if str(principal['id'])==actor.principal_id:fail('SELF_ESCALATION_DENIED',403)
        member=await one(db,'SELECT id FROM public.usergroupuser WHERE org_id=:o AND usergroup_id=:g AND user_id=:u FOR UPDATE',o=actor.org_id,g=data['usergroup_id'],u=data['student_id'])
        if member:
            await execute(db,'UPDATE public.usergroupuser SET expires_at=:e WHERE id=:i',e=None if data['active'] else datetime.now(timezone.utc),i=member['id'])
        elif data['active']:
            await execute(db,"INSERT INTO public.usergroupuser(org_id,usergroup_id,user_id,creation_date,update_date,sources,added_by_id) VALUES(:o,:g,:u,:d,:d,'[\"manual\"]',:a)",o=actor.org_id,g=data['usergroup_id'],u=data['student_id'],d=datetime.now(timezone.utc).isoformat(),a=actor.user_id)
        return command_result('set_membership',[principal['id']])
    return await write_once(db,actor,request,'admin.scope',data,None,change)


@router.post('/admin/principals/commands')
async def principal_command(request:Request,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    require_admin(actor,'access.manage');data=validate('PrincipalCommand',await request.json())
    if data['principal_id']==actor.principal_id:fail('SELF_ESCALATION_DENIED',403)
    async def change():
        await execute(db,"SELECT pg_advisory_xact_lock(hashtextextended(:k,0))",k='scope:'+str(actor.org_id))
        matching(request,(await scopes_view(db,actor))['etag'])
        target=must(await one(db,"SELECT * FROM ea.principal WHERE id=:i AND org_id=:o AND kind='human' FOR UPDATE",i=data['principal_id'],o=actor.org_id))
        if data['command'] in {'disable_v2','enable_v2'}:
            await execute(db,'UPDATE ea.principal SET disabled_at=:d WHERE id=:i',d=datetime.now(timezone.utc) if data['command']=='disable_v2' else None,i=target['id'])
        if data['command'] in {'disable_v2','revoke_sessions'}:
            # Persist revocation in the same DB transaction. No dependency on a
            # best-effort Redis write or on deleting only the current cookie.
            await execute(db,'UPDATE public."user" SET password_changed_at=:cutoff WHERE id=:u',cutoff=datetime.now(timezone.utc).replace(tzinfo=None)+timedelta(seconds=1),u=target['user_id'])
        return command_result(data['command'],[target['id']])
    return await write_once(db,actor,request,'admin.principal',data,None,change)


async def policy_views(db,actor,course_id=None):
    if actor.role=='admin':require_admin(actor,'policy.manage')
    elif course_id is not None:await require_course(db,actor,course_id,action='course.edit')
    else:fail('COURSE_SCOPE_REQUIRED',403)
    records=await rows(db,'SELECT id,org_id,course_id,family_id,version,policy_type,parent_policy_id,rules,content_hash,created_at FROM ea.policy_version WHERE org_id=:o AND (CAST(:c AS integer) IS NULL OR course_id=:c OR policy_type=\'global\') ORDER BY created_at DESC,id',o=actor.org_id,c=course_id)
    result=clean([dict(r,etag=etag(str(r['id'])+':'+str(r['version']))) for r in records])
    return {'items':result,'page':PAGE,'etag':etag(digest(result))}


@router.get('/admin/policies')
async def get_policies(course_id:int|None=None,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    return await policy_views(db,actor,course_id)


@router.post('/admin/policies')
async def create_policy(request:Request,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    data=validate('PolicyCreate',await request.json())
    if data['policy_type']=='global':require_admin(actor,'policy.manage')
    elif actor.role!='admin':await require_course(db,actor,data['course_id'],action='course.edit')
    else:require_admin(actor,'policy.manage')
    async def change():
        await execute(db,"SELECT pg_advisory_xact_lock(hashtextextended(:k,0))",k='policy:'+str(actor.org_id))
        matching(request,(await policy_views(db,actor,data['course_id'] if actor.role!='admin' else None))['etag'])
        family=data['family_id'] or str(uuid4())
        existing=await one(db,'SELECT family_id FROM ea.policy_version WHERE org_id=:o AND policy_type=:t AND course_id IS NOT DISTINCT FROM CAST(:c AS integer) LIMIT 1',o=actor.org_id,t=data['policy_type'],c=data['course_id'])
        if existing and str(existing['family_id'])!=family:
            fail('POLICY_FAMILY_ALREADY_EXISTS',409,'本版每个范围仅使用一个策略家族；请基于当前版本修订')
        old=await one(db,'SELECT * FROM ea.policy_version WHERE org_id=:o AND family_id=:f ORDER BY version DESC LIMIT 1',o=actor.org_id,f=family)
        if (old['version'] if old else 0)!=data['expected_version']:fail('VERSION_CONFLICT',409)
        if old and (old['course_id']!=data['course_id'] or old['policy_type']!=data['policy_type']):fail('POLICY_FAMILY_MISMATCH',409)
        if data['policy_type']=='global':
            if data['course_id'] is not None or data['parent_policy_id'] is not None:fail('INVALID_POLICY_SCOPE',422)
        else:
            parent=must(await one(db,"SELECT * FROM ea.policy_version WHERE id=:i AND org_id=:o AND policy_type='global'",i=data['parent_policy_id'],o=actor.org_id))
            latest_parent=await one(db,"SELECT id FROM ea.policy_version WHERE org_id=:o AND policy_type='global' ORDER BY version DESC LIMIT 1",o=actor.org_id)
            if latest_parent['id']!=parent['id']:fail('POLICY_PARENT_STALE',409)
            must(await one(db,'SELECT id FROM public.course WHERE id=:c AND org_id=:o',c=data['course_id'],o=actor.org_id))
            p=parent['rules'];q=data['rules']
            if not set(q['allowed_generation_modes'])<=set(p.get('allowed_generation_modes',[])) or not set(p.get('required_checks',[]))<=set(q['required_checks']) or q['maximum_task_budget']>p.get('maximum_task_budget',0) or q['maximum_task_attempts']>p.get('maximum_task_attempts',1) or (p.get('require_human_review',True) and not q['require_human_review']) or (q['allow_rule_auto_publish'] and not p.get('allow_rule_auto_publish',False)) or (q['allow_review'] and not p.get('allow_review',False)):
                fail('POLICY_CANNOT_WIDEN_PARENT',422)
        result=await one(db,'INSERT INTO ea.policy_version(org_id,course_id,family_id,version,parent_policy_id,policy_type,rules,content_hash,created_by) VALUES(:o,:c,:f,:v,:p,:t,CAST(:r AS jsonb),:h,:a) RETURNING id',o=actor.org_id,c=data['course_id'],f=family,v=data['expected_version']+1,p=data['parent_policy_id'],t=data['policy_type'],r=canonical(data['rules']),h=digest(data['rules']),a=actor.principal_id)
        return command_result('policy.create',[result['id']],str(data['expected_version']+1))
    return await write_once(db,actor,request,'admin.policy',data,data['course_id'],change)


@router.get('/admin/operations')
async def operations(actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    require_admin(actor,'operations.manage')
    counts=await one(db,"SELECT (SELECT count(*) FROM ea.principal WHERE org_id=:o AND kind='human') AS accounts,(SELECT count(*) FROM public.course WHERE org_id=:o) AS courses,(SELECT count(*) FROM ea.task_run WHERE org_id=:o AND status='queued') AS queued_tasks,(SELECT count(*) FROM ea.task_run WHERE org_id=:o AND status='running') AS running_tasks,(SELECT count(*) FROM ea.task_run WHERE org_id=:o AND status='failed') AS failed_tasks",o=actor.org_id)
    tasks=await rows(db,'SELECT id,course_id,operation,status,attempt_count,max_attempts,execution_epoch,error_code,budget_limit,budget_spent,created_at,updated_at FROM ea.task_run WHERE org_id=:o ORDER BY created_at DESC LIMIT 50',o=actor.org_id)
    safe=clean([dict(t,etag=etag(t['execution_epoch'])) for t in tasks])
    return {'capabilities':capabilities(),'counts':counts,'budget':{'limit':0,'spent':0,'currency':'unknown'},'tasks':safe,'page':PAGE,'etag':etag(digest(safe))}


@router.get('/admin/audit')
async def audit(actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    require_admin(actor,'audit.metadata')
    records=await rows(db,'SELECT id,org_id,course_id,actor_id,action,target_type,target_id,request_id,task_id,before_version,after_version,reason_code,created_at FROM ea.audit_event WHERE org_id=:o ORDER BY id DESC LIMIT 100',o=actor.org_id)
    return clean({'items':[dict(r,id=str(r['id']),metadata={'outcome':'success'}) for r in records],'page':PAGE,'etag':etag(digest(records))})
