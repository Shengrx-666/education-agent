"""Private notes with independent, revocable sharing and profile consent."""
from datetime import datetime, timezone
from uuid import uuid4
from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, ConfigDict, Field
from src.core.events.database import get_db_session
from src.education.security import Actor, require_actor, require_course, fail
from src.education.business import rows, one, execute, clean, etag, digest, matching, validate, write_once, must, canonical
from src.education.admin_routes import command_result, note_permissions

router=APIRouter()


class NoteInput(BaseModel):
    model_config=ConfigDict(extra='forbid')
    content_text:str=Field(min_length=1,max_length=20000)
    activity_id:int=Field(gt=0)


async def owned(db,actor,note_id):
    n=must(await one(db,'SELECT * FROM public.learner_note WHERE id=:i AND org_id=:o AND user_id=:u',i=note_id,o=actor.org_id,u=actor.user_id))
    await require_course(db,actor,n['course_id'],student_id=actor.user_id)
    return n


@router.get('/courses/{course_id}/notes')
async def list_notes(course_id:int,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    if actor.role!='student':fail('SCOPE_DENIED',403)
    await require_course(db,actor,course_id,student_id=actor.user_id)
    notes=await rows(db,'SELECT id,note_uuid,activity_id,plain_text AS content_text,updated_at FROM public.learner_note WHERE course_id=:c AND org_id=:o AND user_id=:u ORDER BY id DESC',c=course_id,o=actor.org_id,u=actor.user_id)
    activities=await rows(db,'SELECT id,activity_uuid,name FROM public.activity WHERE course_id=:c AND org_id=:o ORDER BY id',c=course_id,o=actor.org_id)
    return clean({'items':[dict(n,etag=etag(digest(n))) for n in notes],'activities':activities,'etag':etag(digest(notes))})


@router.post('/courses/{course_id}/notes')
async def create_note(course_id:int,body:NoteInput,request:Request,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    if actor.role!='student':fail('SCOPE_DENIED',403)
    await require_course(db,actor,course_id,student_id=actor.user_id)
    must(await one(db,'SELECT id FROM public.activity WHERE id=:i AND course_id=:c AND org_id=:o',i=body.activity_id,c=course_id,o=actor.org_id))
    async def change():
        matching(request,(await list_notes(course_id,actor,db))['etag'])
        doc={'type':'doc','content':[{'type':'paragraph','content':[{'type':'text','text':body.content_text}]}]}
        n=await one(db,'INSERT INTO public.learner_note(note_uuid,org_id,user_id,course_id,activity_id,content,plain_text,created_at,updated_at) VALUES(:id,:o,:u,:c,:a,CAST(:doc AS json),:body,:now,:now) RETURNING id',id='note_'+str(uuid4()),o=actor.org_id,u=actor.user_id,c=course_id,a=body.activity_id,doc=canonical(doc),body=body.content_text,now=datetime.now(timezone.utc).isoformat())
        return command_result('note.create',[n['id']])
    return await write_once(db,actor,request,'note.create',body.model_dump(),course_id,change)


@router.post('/notes/{note_id}/permissions')
async def change_permission(note_id:int,request:Request,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    if actor.role!='student':fail('SCOPE_DENIED',403)
    note=await owned(db,actor,note_id);data=validate('NotePermissionCommand',await request.json())
    if (data['purpose']=='profile_use') != (data['grantee_id'] is None):fail('INVALID_GRANTEE',422)
    if data['grantee_id']:
        target=must(await one(db,"SELECT p.id FROM ea.principal p JOIN ea.action_grant g ON g.principal_id=p.id WHERE p.id=:p AND p.org_id=:o AND p.kind='human' AND p.disabled_at IS NULL AND g.course_id=:c AND g.action='content.read' AND g.revoked_at IS NULL AND g.starts_at<=now() AND (g.expires_at IS NULL OR g.expires_at>now()) AND (g.student_id IS NULL OR g.student_id=:u) AND (g.usergroup_id IS NULL OR EXISTS(SELECT 1 FROM public.usergroupuser m WHERE m.user_id=:u AND m.usergroup_id=g.usergroup_id AND m.org_id=p.org_id AND (m.expires_at IS NULL OR m.expires_at>now())))",p=data['grantee_id'],o=actor.org_id,c=note['course_id'],u=actor.user_id))
    async def change():
        await execute(db,'SELECT id FROM public.learner_note WHERE id=:i FOR UPDATE',i=note_id)
        matching(request,etag(digest(await note_permissions(db,actor))))
        history=await rows(db,'SELECT * FROM ea.note_permission WHERE note_id=:i AND purpose=:p AND grantee_id IS NOT DISTINCT FROM CAST(:g AS uuid) ORDER BY consent_revision DESC FOR UPDATE',i=note_id,p=data['purpose'],g=data['grantee_id'])
        revision=history[0]['consent_revision'] if history else 0
        if revision!=data['expected_version']:fail('VERSION_CONFLICT',409)
        active=next((x for x in history if x['revoked_at'] is None),None)
        if data['command']=='revoke':
            if not active or str(active['id'])!=data['permission_id']:fail('PERMISSION_VERSION_CONFLICT',409)
            await execute(db,'UPDATE ea.note_permission SET revoked_at=now() WHERE id=:i',i=active['id'])
            return command_result('note.revoke',[active['id']])
        if data['permission_id'] is not None:fail('INVALID_REQUEST',422)
        now=datetime.now(timezone.utc)
        if active:
            if not active['expires_at'] or active['expires_at']>now:fail('ALREADY_GRANTED',409)
            await execute(db,'UPDATE ea.note_permission SET revoked_at=expires_at WHERE id=:i',i=active['id'])
        expires=datetime.fromisoformat(data['expires_at'].replace('Z','+00:00')) if data['expires_at'] else None
        if expires and expires<=now:fail('INVALID_EXPIRY',422)
        p=await one(db,'INSERT INTO ea.note_permission(org_id,course_id,note_id,student_id,purpose,grantee_id,consent_revision,expires_at) VALUES(:o,:c,:n,:u,:p,:g,:r,:e) RETURNING id',o=actor.org_id,c=note['course_id'],n=note_id,u=actor.user_id,p=data['purpose'],g=data['grantee_id'],r=revision+1,e=expires)
        return command_result('note.grant',[p['id']],str(revision+1))
    return await write_once(db,actor,request,'note.permission',data,note['course_id'],change)


@router.get('/notes/{note_id}/shared-content')
async def shared_content(note_id:int,actor:Actor=Depends(require_actor),db=Depends(get_db_session)):
    if actor.role=='admin':fail('SCOPE_DENIED',403)
    n=must(await one(db,'SELECT * FROM public.learner_note WHERE id=:i AND org_id=:o',i=note_id,o=actor.org_id))
    await require_course(db,actor,n['course_id'],action='content.read',student_id=n['user_id'])
    p=None
    if n['user_id']!=actor.user_id:
        if actor.role!='teacher':fail('SCOPE_DENIED',403)
        p=await one(db,"SELECT id,consent_revision FROM ea.note_permission WHERE note_id=:n AND org_id=:o AND purpose='teacher_read' AND grantee_id=:p AND revoked_at IS NULL AND starts_at<=now() AND (expires_at IS NULL OR expires_at>now()) FOR SHARE",n=note_id,o=actor.org_id,p=actor.principal_id)
        if not p:fail('NOTE_NOT_SHARED',403)
    return clean({'note_id':n['id'],'note_uuid':n['note_uuid'],'course_id':n['course_id'],'student_id':n['user_id'],'permission_id':p['id'] if p else None,'consent_revision':p['consent_revision'] if p else 0,'content_text':n['plain_text'],'etag':etag(digest([n['updated_at'],n['plain_text'],p]))})
