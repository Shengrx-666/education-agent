-- EMPTY TEST DATABASE ONLY. Minimal shape for ea DDL/FK tests, NOT a LearnHouse migration.
\set ON_ERROR_STOP on
CREATE TABLE public.organization (id integer PRIMARY KEY);
CREATE TABLE public."user" (id integer PRIMARY KEY);
CREATE TABLE public.course (id integer PRIMARY KEY,org_id integer NOT NULL REFERENCES public.organization(id),course_uuid text NOT NULL);
CREATE TABLE public.activity (id integer PRIMARY KEY,course_id integer NOT NULL REFERENCES public.course(id),org_id integer NOT NULL REFERENCES public.organization(id));
CREATE TABLE public.assignment (id integer PRIMARY KEY,course_id integer NOT NULL REFERENCES public.course(id),org_id integer NOT NULL REFERENCES public.organization(id));
CREATE TABLE public.usergroup (id integer PRIMARY KEY,org_id integer NOT NULL REFERENCES public.organization(id));
CREATE TABLE public.userorganization (id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id integer NOT NULL REFERENCES public."user"(id),org_id integer NOT NULL REFERENCES public.organization(id),UNIQUE(user_id,org_id));
CREATE TABLE public.usergroupuser (id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,usergroup_id integer NOT NULL REFERENCES public.usergroup(id),user_id integer NOT NULL REFERENCES public."user"(id),org_id integer NOT NULL REFERENCES public.organization(id),expires_at timestamptz);
CREATE TABLE public.usergroupresource (id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,usergroup_id integer NOT NULL REFERENCES public.usergroup(id),org_id integer NOT NULL REFERENCES public.organization(id),resource_uuid text NOT NULL,starts_at timestamptz,expires_at timestamptz);
CREATE TABLE public.learner_note (id integer PRIMARY KEY,user_id integer NOT NULL REFERENCES public."user"(id),course_id integer NOT NULL REFERENCES public.course(id),org_id integer NOT NULL REFERENCES public.organization(id));
