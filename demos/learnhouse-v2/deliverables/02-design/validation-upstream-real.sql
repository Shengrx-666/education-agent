--
-- PostgreSQL database dump
--

\restrict 1xbKTkor8DegkHthD6dokucKz0qtcZoreGJJEaf4O3BBH2Z9khTvEPocZMC4wxY

-- Dumped from database version 14.24 (Ubuntu 14.24-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.24 (Ubuntu 14.24-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


--
-- Name: activitylocktype; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.activitylocktype AS ENUM (
    'PUBLIC',
    'AUTHENTICATED',
    'RESTRICTED'
);


--
-- Name: activitysubtypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.activitysubtypeenum AS ENUM (
    'SUBTYPE_DYNAMIC_PAGE',
    'SUBTYPE_DYNAMIC_MARKDOWN',
    'SUBTYPE_DYNAMIC_EMBED',
    'SUBTYPE_DYNAMIC_RESOURCE',
    'SUBTYPE_VIDEO_YOUTUBE',
    'SUBTYPE_VIDEO_HOSTED',
    'SUBTYPE_DOCUMENT_PDF',
    'SUBTYPE_DOCUMENT_DOC',
    'SUBTYPE_ASSIGNMENT_ANY',
    'SUBTYPE_CUSTOM',
    'SUBTYPE_SCORM_12',
    'SUBTYPE_SCORM_2004',
    'SUBTYPE_LIVE_SESSION',
    'SUBTYPE_PLAY'
);


--
-- Name: activitytypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.activitytypeenum AS ENUM (
    'TYPE_VIDEO',
    'TYPE_DOCUMENT',
    'TYPE_DYNAMIC',
    'TYPE_ASSIGNMENT',
    'TYPE_CUSTOM',
    'TYPE_SCORM',
    'TYPE_LIVE_SESSION',
    'TYPE_PLAY'
);


--
-- Name: aigenerationkind; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.aigenerationkind AS ENUM (
    'IMAGE',
    'QUIZ',
    'ASSIGNMENT',
    'SCENARIO'
);


--
-- Name: aigradingmodeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.aigradingmodeenum AS ENUM (
    'OFF',
    'SUGGEST',
    'AUTO'
);


--
-- Name: assignmenttasktypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.assignmenttasktypeenum AS ENUM (
    'FILE_SUBMISSION',
    'QUIZ',
    'FORM',
    'CODE',
    'SHORT_ANSWER',
    'NUMBER_ANSWER',
    'CUSTOM',
    'OTHER'
);


--
-- Name: assignmentusersubmissionstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.assignmentusersubmissionstatus AS ENUM (
    'PENDING',
    'SUBMITTED',
    'GRADED',
    'LATE',
    'NOT_SUBMITTED'
);


--
-- Name: blocktypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.blocktypeenum AS ENUM (
    'BLOCK_QUIZ',
    'BLOCK_VIDEO',
    'BLOCK_DOCUMENT_PDF',
    'BLOCK_IMAGE',
    'BLOCK_AUDIO',
    'BLOCK_CUSTOM'
);


--
-- Name: gradingtypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.gradingtypeenum AS ENUM (
    'ALPHABET',
    'NUMERIC',
    'PERCENTAGE',
    'PASS_FAIL',
    'GPA_SCALE'
);


--
-- Name: locktype; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.locktype AS ENUM (
    'PUBLIC',
    'AUTHENTICATED',
    'RESTRICTED'
);


--
-- Name: mediatypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.mediatypeenum AS ENUM (
    'UPLOAD',
    'EMBED'
);


--
-- Name: packstatusenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.packstatusenum AS ENUM (
    'active',
    'cancelled'
);


--
-- Name: packtypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.packtypeenum AS ENUM (
    'ai_credits'
);


--
-- Name: resourceauthorshipenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.resourceauthorshipenum AS ENUM (
    'CREATOR',
    'CONTRIBUTOR',
    'MAINTAINER',
    'REPORTER'
);


--
-- Name: resourceauthorshipstatusenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.resourceauthorshipstatusenum AS ENUM (
    'ACTIVE',
    'PENDING',
    'INACTIVE'
);


--
-- Name: roletypeenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.roletypeenum AS ENUM (
    'TYPE_ORGANIZATION',
    'TYPE_ORGANIZATION_API_TOKEN',
    'TYPE_GLOBAL'
);


--
-- Name: solutionrevealenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.solutionrevealenum AS ENUM (
    'NEVER',
    'ON_SUBMISSION',
    'AFTER_GRADING'
);


--
-- Name: statusenum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statusenum AS ENUM (
    'STATUS_IN_PROGRESS',
    'STATUS_COMPLETED',
    'STATUS_PAUSED',
    'STATUS_CANCELLED'
);


--
-- Name: thumbnail_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.thumbnail_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'BOTH'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity (
    name character varying NOT NULL,
    activity_type public.activitytypeenum NOT NULL,
    activity_sub_type public.activitysubtypeenum NOT NULL,
    content json,
    details json,
    published boolean NOT NULL,
    lock_type public.activitylocktype NOT NULL,
    id integer NOT NULL,
    org_id integer,
    course_id integer,
    activity_uuid character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    extra_metadata jsonb,
    current_version integer NOT NULL,
    last_modified_by_id integer
);


--
-- Name: activity_comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_comment (
    id integer NOT NULL,
    comment_uuid character varying NOT NULL,
    thread_id integer NOT NULL,
    author_id integer,
    body character varying(5000) DEFAULT ''::character varying NOT NULL,
    mentions json DEFAULT '[]'::json NOT NULL,
    edited_at character varying,
    created_at character varying NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: activity_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_comment_id_seq OWNED BY public.activity_comment.id;


--
-- Name: activity_comment_thread; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_comment_thread (
    id integer NOT NULL,
    thread_uuid character varying NOT NULL,
    activity_id integer NOT NULL,
    org_id integer NOT NULL,
    created_by integer,
    quote character varying(500) DEFAULT ''::character varying NOT NULL,
    status character varying(16) DEFAULT 'open'::character varying NOT NULL,
    resolved_by integer,
    resolved_at character varying,
    created_at character varying NOT NULL,
    updated_at character varying NOT NULL,
    locale character varying(20)
);


--
-- Name: activity_comment_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_comment_thread_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_comment_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_comment_thread_id_seq OWNED BY public.activity_comment_thread.id;


--
-- Name: activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_id_seq OWNED BY public.activity.id;


--
-- Name: activity_translation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_translation (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    course_id integer NOT NULL,
    org_id integer NOT NULL,
    locale character varying(20) NOT NULL,
    status character varying(16) NOT NULL,
    translated_by character varying(16),
    name character varying,
    content json,
    extra json,
    source_version integer,
    source_hash character varying(64),
    version integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    updated_by_id integer
);


--
-- Name: activity_translation_collab; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_translation_collab (
    translation_id integer NOT NULL,
    org_id integer NOT NULL,
    ydoc_state bytea,
    ydoc_version integer NOT NULL,
    updated_at timestamp without time zone
);


--
-- Name: activity_translation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_translation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_translation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_translation_id_seq OWNED BY public.activity_translation.id;


--
-- Name: activitycollabstate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activitycollabstate (
    activity_id integer NOT NULL,
    org_id integer,
    ydoc_state bytea,
    ydoc_version integer NOT NULL,
    last_snapshot_at timestamp without time zone,
    last_snapshot_contributors json,
    updated_at timestamp without time zone
);


--
-- Name: activityversion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activityversion (
    content json,
    version_number integer NOT NULL,
    created_by_id integer,
    label character varying(120),
    id integer NOT NULL,
    activity_id integer,
    org_id integer,
    created_at timestamp without time zone
);


--
-- Name: activityversion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activityversion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activityversion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activityversion_id_seq OWNED BY public.activityversion.id;


--
-- Name: agent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent (
    id integer NOT NULL,
    agent_uuid character varying NOT NULL,
    org_id bigint NOT NULL,
    owner_user_id integer,
    name character varying NOT NULL,
    description character varying NOT NULL,
    emoji character varying NOT NULL,
    color character varying NOT NULL,
    secondary_color character varying NOT NULL,
    instructions text DEFAULT ''::text NOT NULL,
    tone character varying NOT NULL,
    knowledge_mode character varying NOT NULL,
    course_uuids json,
    greeting character varying NOT NULL,
    starters json,
    visibility character varying NOT NULL,
    is_default boolean NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: agent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_id_seq OWNED BY public.agent.id;


--
-- Name: ai_usage_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_usage_event (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    user_id integer,
    feature character varying(64) NOT NULL,
    status character varying(16) DEFAULT 'ok'::character varying NOT NULL,
    credits integer DEFAULT 0 NOT NULL,
    cost_micros bigint DEFAULT '0'::bigint NOT NULL,
    units double precision NOT NULL,
    requests integer DEFAULT 0 NOT NULL,
    input_tokens bigint DEFAULT '0'::bigint NOT NULL,
    output_tokens bigint DEFAULT '0'::bigint NOT NULL,
    models json,
    charge_key character varying(128) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: ai_usage_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_usage_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_usage_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_usage_event_id_seq OWNED BY public.ai_usage_event.id;


--
-- Name: aigeneration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aigeneration (
    kind public.aigenerationkind NOT NULL,
    prompt text,
    session_uuid character varying,
    result json,
    id integer NOT NULL,
    ai_generation_uuid character varying NOT NULL,
    creation_date character varying,
    update_date character varying,
    org_id integer,
    user_id integer,
    course_id integer,
    activity_id integer,
    assignment_id integer
);


--
-- Name: aigeneration_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aigeneration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aigeneration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aigeneration_id_seq OWNED BY public.aigeneration.id;


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: apitoken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apitoken (
    name character varying(100) NOT NULL,
    description character varying(500),
    rights json,
    id integer NOT NULL,
    token_uuid character varying(100) NOT NULL,
    token_prefix character varying(12) NOT NULL,
    token_hash character varying(255),
    org_id integer NOT NULL,
    created_by_user_id integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    last_used_at character varying,
    expires_at character varying,
    is_active boolean NOT NULL
);


--
-- Name: apitoken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.apitoken_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: apitoken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.apitoken_id_seq OWNED BY public.apitoken.id;


--
-- Name: assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment (
    title character varying NOT NULL,
    description character varying NOT NULL,
    due_date character varying,
    published boolean,
    grading_type public.gradingtypeenum NOT NULL,
    auto_grading boolean,
    anti_copy_paste boolean,
    show_correct_answers boolean,
    allow_retries boolean,
    max_retries integer,
    pass_threshold_percentage double precision,
    ungraded boolean,
    solution character varying,
    solution_file character varying,
    solution_reveal public.solutionrevealenum,
    ai_grading_mode public.aigradingmodeenum,
    ai_grading_instructions character varying,
    ai_grading_task_instructions json,
    id integer NOT NULL,
    creation_date character varying,
    update_date character varying,
    assignment_uuid character varying NOT NULL,
    org_id integer,
    course_id integer,
    chapter_id integer,
    activity_id integer
);


--
-- Name: assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_id_seq OWNED BY public.assignment.id;


--
-- Name: assignmentaigrade; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignmentaigrade (
    id integer NOT NULL,
    assignment_ai_grade_uuid character varying NOT NULL,
    assignment_id integer NOT NULL,
    user_id integer NOT NULL,
    org_id integer NOT NULL,
    status character varying NOT NULL,
    mode character varying NOT NULL,
    attempt_number integer NOT NULL,
    overall_feedback text,
    tasks json,
    confidence character varying,
    notes text,
    sources json,
    credits_charged integer NOT NULL,
    model character varying,
    error character varying,
    triggered_by integer,
    applied_by integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: assignmentaigrade_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignmentaigrade_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignmentaigrade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignmentaigrade_id_seq OWNED BY public.assignmentaigrade.id;


--
-- Name: assignmenttask; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignmenttask (
    title character varying NOT NULL,
    description character varying NOT NULL,
    hint character varying NOT NULL,
    reference_file character varying,
    assignment_type public.assignmenttasktypeenum NOT NULL,
    contents json,
    max_grade_value integer NOT NULL,
    id integer NOT NULL,
    assignment_task_uuid character varying NOT NULL,
    "order" integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    assignment_id integer,
    org_id integer,
    course_id integer,
    chapter_id integer,
    activity_id integer
);


--
-- Name: assignmenttask_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignmenttask_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignmenttask_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignmenttask_id_seq OWNED BY public.assignmenttask.id;


--
-- Name: assignmenttasksubmission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignmenttasksubmission (
    assignment_task_submission_uuid character varying NOT NULL,
    task_submission json,
    grade integer NOT NULL,
    task_submission_grade_feedback character varying NOT NULL,
    manually_graded boolean NOT NULL,
    assignment_type public.assignmenttasktypeenum NOT NULL,
    user_id integer,
    activity_id integer,
    course_id integer,
    chapter_id integer,
    assignment_task_id integer,
    id integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: assignmenttasksubmission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignmenttasksubmission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignmenttasksubmission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignmenttasksubmission_id_seq OWNED BY public.assignmenttasksubmission.id;


--
-- Name: assignmentusersubmission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignmentusersubmission (
    submission_status public.assignmentusersubmissionstatus NOT NULL,
    grade integer NOT NULL,
    overall_feedback character varying,
    attempt_number integer NOT NULL,
    user_id integer,
    assignment_id integer,
    id integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    assignmentusersubmission_uuid character varying NOT NULL
);


--
-- Name: assignmentusersubmission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignmentusersubmission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignmentusersubmission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignmentusersubmission_id_seq OWNED BY public.assignmentusersubmission.id;


--
-- Name: block; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.block (
    id integer NOT NULL,
    block_type public.blocktypeenum NOT NULL,
    content json,
    org_id integer,
    course_id integer,
    chapter_id integer,
    activity_id integer,
    block_uuid character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: block_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.block_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: block_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.block_id_seq OWNED BY public.block.id;


--
-- Name: certificateuser; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.certificateuser (
    user_id integer,
    certification_id integer,
    user_certification_uuid character varying NOT NULL,
    id integer NOT NULL,
    created_at character varying NOT NULL,
    updated_at character varying NOT NULL
);


--
-- Name: certificateuser_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.certificateuser_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: certificateuser_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.certificateuser_id_seq OWNED BY public.certificateuser.id;


--
-- Name: certifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.certifications (
    id integer NOT NULL,
    certification_uuid character varying NOT NULL,
    course_id integer,
    config json,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: certifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.certifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: certifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.certifications_id_seq OWNED BY public.certifications.id;


--
-- Name: chapter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chapter (
    name character varying NOT NULL,
    description character varying,
    thumbnail_image character varying,
    lock_type public.locktype NOT NULL,
    org_id integer,
    course_id integer,
    id integer NOT NULL,
    chapter_uuid character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    extra_metadata jsonb,
    drip_rule jsonb
);


--
-- Name: chapter_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chapter_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chapter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chapter_id_seq OWNED BY public.chapter.id;


--
-- Name: chapter_translation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chapter_translation (
    id integer NOT NULL,
    chapter_id integer NOT NULL,
    course_id integer NOT NULL,
    org_id integer NOT NULL,
    locale character varying(20) NOT NULL,
    status character varying(16) NOT NULL,
    translated_by character varying(16),
    name character varying,
    description character varying,
    source_hash character varying(64),
    updated_at timestamp without time zone
);


--
-- Name: chapter_translation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chapter_translation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chapter_translation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chapter_translation_id_seq OWNED BY public.chapter_translation.id;


--
-- Name: chapteractivity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chapteractivity (
    id integer NOT NULL,
    "order" integer NOT NULL,
    chapter_id bigint,
    activity_id bigint,
    course_id bigint,
    org_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: chapteractivity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chapteractivity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chapteractivity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chapteractivity_id_seq OWNED BY public.chapteractivity.id;


--
-- Name: code_submission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.code_submission (
    id integer NOT NULL,
    submission_uuid character varying NOT NULL,
    user_id integer NOT NULL,
    activity_uuid character varying NOT NULL,
    block_id character varying NOT NULL,
    language_id integer NOT NULL,
    source_code character varying NOT NULL,
    results json,
    passed boolean NOT NULL,
    total_tests integer NOT NULL,
    passed_tests integer NOT NULL,
    execution_time_ms integer,
    created_at character varying NOT NULL
);


--
-- Name: code_submission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.code_submission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_submission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.code_submission_id_seq OWNED BY public.code_submission.id;


--
-- Name: community; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.community (
    name character varying NOT NULL,
    description text,
    public boolean NOT NULL,
    thumbnail_image character varying,
    id integer NOT NULL,
    org_id integer,
    course_id integer,
    community_uuid character varying NOT NULL,
    slug character varying(100),
    seo jsonb,
    moderation_words json,
    moderation_settings json,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: community_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.community_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: community_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.community_id_seq OWNED BY public.community.id;


--
-- Name: conversation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation (
    id integer NOT NULL,
    conversation_uuid character varying NOT NULL,
    org_id bigint NOT NULL,
    kind character varying NOT NULL,
    title character varying NOT NULL,
    emoji character varying NOT NULL,
    dm_key character varying,
    course_id integer,
    agent_id integer,
    created_by integer,
    last_message_at character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: conversation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_id_seq OWNED BY public.conversation.id;


--
-- Name: conversationmember; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversationmember (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    user_id integer NOT NULL,
    role character varying NOT NULL,
    last_read_message_id integer NOT NULL,
    last_emailed_message_id integer NOT NULL,
    muted boolean NOT NULL,
    pinned boolean NOT NULL,
    archived boolean NOT NULL,
    joined_at character varying NOT NULL
);


--
-- Name: conversationmember_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversationmember_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversationmember_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversationmember_id_seq OWNED BY public.conversationmember.id;


--
-- Name: course; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course (
    name character varying NOT NULL,
    description character varying,
    about character varying,
    learnings character varying,
    tags character varying,
    thumbnail_image character varying,
    thumbnail_video character varying,
    public boolean NOT NULL,
    published boolean NOT NULL,
    open_to_contributors boolean NOT NULL,
    id integer NOT NULL,
    thumbnail_type public.thumbnail_type,
    org_id integer,
    course_uuid character varying NOT NULL,
    slug character varying(100),
    default_locale character varying(20),
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    seo jsonb,
    extra_metadata jsonb,
    drip_settings jsonb
);


--
-- Name: course_embedding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_embedding (
    id integer NOT NULL,
    org_id integer,
    course_id integer,
    activity_id integer,
    activity_uuid character varying NOT NULL,
    block_uuid character varying,
    source_type character varying NOT NULL,
    chunk_text text,
    chunk_index integer NOT NULL,
    locator jsonb,
    content_hash character varying,
    activity_name character varying NOT NULL,
    chapter_name character varying NOT NULL,
    course_name character varying NOT NULL,
    embedding public.vector(768),
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: course_embedding_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_embedding_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_embedding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_embedding_id_seq OWNED BY public.course_embedding.id;


--
-- Name: course_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_id_seq OWNED BY public.course.id;


--
-- Name: course_translation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_translation (
    id integer NOT NULL,
    course_id integer NOT NULL,
    org_id integer NOT NULL,
    locale character varying(20) NOT NULL,
    status character varying(16) NOT NULL,
    translated_by character varying(16),
    name character varying,
    description character varying,
    about character varying,
    learnings character varying,
    tags character varying,
    seo jsonb,
    slug character varying(100),
    source_hash character varying(64),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    updated_by_id integer
);


--
-- Name: course_translation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_translation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_translation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_translation_id_seq OWNED BY public.course_translation.id;


--
-- Name: coursechapter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coursechapter (
    id integer NOT NULL,
    "order" integer NOT NULL,
    course_id integer,
    chapter_id integer,
    org_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: coursechapter_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coursechapter_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coursechapter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coursechapter_id_seq OWNED BY public.coursechapter.id;


--
-- Name: courseupdate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courseupdate (
    id integer NOT NULL,
    courseupdate_uuid character varying NOT NULL,
    title character varying NOT NULL,
    content character varying NOT NULL,
    course_id integer,
    linked_activity_uuids character varying,
    org_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: courseupdate_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courseupdate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courseupdate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courseupdate_id_seq OWNED BY public.courseupdate.id;


--
-- Name: customdomain; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customdomain (
    "primary" boolean NOT NULL,
    id integer NOT NULL,
    domain_uuid character varying(100) NOT NULL,
    domain character varying(255) NOT NULL,
    org_id bigint NOT NULL,
    status character varying(50) NOT NULL,
    verification_token character varying(100) NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    verified_at character varying,
    last_check_at character varying,
    check_error character varying
);


--
-- Name: customdomain_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customdomain_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customdomain_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customdomain_id_seq OWNED BY public.customdomain.id;


--
-- Name: discussion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion (
    title character varying NOT NULL,
    content text,
    label character varying(50),
    emoji character varying(50),
    id integer NOT NULL,
    community_id integer,
    org_id integer,
    author_id integer,
    discussion_uuid character varying NOT NULL,
    upvote_count integer NOT NULL,
    edit_count integer NOT NULL,
    is_pinned boolean,
    is_locked boolean,
    answer_comment_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: discussion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_id_seq OWNED BY public.discussion.id;


--
-- Name: discussioncomment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussioncomment (
    content text,
    id integer NOT NULL,
    discussion_id integer,
    author_id integer,
    comment_uuid character varying NOT NULL,
    upvote_count integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: discussioncomment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussioncomment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussioncomment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussioncomment_id_seq OWNED BY public.discussioncomment.id;


--
-- Name: discussioncommentvote; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussioncommentvote (
    id integer NOT NULL,
    comment_id integer,
    user_id integer,
    vote_uuid character varying NOT NULL,
    creation_date character varying NOT NULL
);


--
-- Name: discussioncommentvote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussioncommentvote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussioncommentvote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussioncommentvote_id_seq OWNED BY public.discussioncommentvote.id;


--
-- Name: discussionreaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussionreaction (
    id integer NOT NULL,
    discussion_id integer,
    user_id integer,
    emoji character varying(50),
    reaction_uuid character varying NOT NULL,
    creation_date character varying NOT NULL
);


--
-- Name: discussionreaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussionreaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussionreaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussionreaction_id_seq OWNED BY public.discussionreaction.id;


--
-- Name: discussionvote; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussionvote (
    id integer NOT NULL,
    discussion_id integer,
    user_id integer,
    vote_uuid character varying NOT NULL,
    creation_date character varying NOT NULL
);


--
-- Name: discussionvote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussionvote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussionvote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussionvote_id_seq OWNED BY public.discussionvote.id;


--
-- Name: drip_notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drip_notification (
    id integer NOT NULL,
    chapter_id integer NOT NULL,
    user_id integer NOT NULL,
    course_id integer NOT NULL,
    org_id integer NOT NULL,
    sent_at character varying NOT NULL
);


--
-- Name: drip_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.drip_notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drip_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.drip_notification_id_seq OWNED BY public.drip_notification.id;


--
-- Name: editortemplate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.editortemplate (
    name character varying NOT NULL,
    description character varying NOT NULL,
    kind character varying DEFAULT 'block'::character varying NOT NULL,
    content json,
    id integer NOT NULL,
    template_uuid character varying NOT NULL,
    org_id integer NOT NULL,
    creator_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: editortemplate_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.editortemplate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: editortemplate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.editortemplate_id_seq OWNED BY public.editortemplate.id;


--
-- Name: editorvariable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.editorvariable (
    key character varying NOT NULL,
    label character varying NOT NULL,
    description character varying NOT NULL,
    default_value character varying NOT NULL,
    variants json,
    id integer NOT NULL,
    variable_uuid character varying NOT NULL,
    org_id integer NOT NULL,
    creator_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: editorvariable_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.editorvariable_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: editorvariable_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.editorvariable_id_seq OWNED BY public.editorvariable.id;


--
-- Name: email_preference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_preference (
    id integer NOT NULL,
    user_id integer NOT NULL,
    lifecycle_opt_out boolean NOT NULL,
    product_updates_opt_out boolean NOT NULL,
    unsubscribed_at timestamp with time zone,
    source character varying(32),
    suppressed boolean NOT NULL,
    suppressed_reason character varying(32)
);


--
-- Name: email_preference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_preference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_preference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_preference_id_seq OWNED BY public.email_preference.id;


--
-- Name: folder; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.folder (
    name character varying NOT NULL,
    public boolean NOT NULL,
    description character varying,
    thumbnail_image character varying,
    color character varying,
    id integer NOT NULL,
    org_id bigint,
    folder_uuid character varying NOT NULL,
    slug character varying(100),
    seo jsonb,
    parent_folder_id integer,
    "order" integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: folder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.folder_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: folder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.folder_id_seq OWNED BY public.folder.id;


--
-- Name: foldercontent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.foldercontent (
    id integer NOT NULL,
    folder_id integer,
    resource_uuid character varying NOT NULL,
    org_id integer,
    "position" integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: foldercontent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.foldercontent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: foldercontent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.foldercontent_id_seq OWNED BY public.foldercontent.id;


--
-- Name: landing_form_submission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.landing_form_submission (
    id integer NOT NULL,
    submission_uuid character varying(100) NOT NULL,
    org_id bigint NOT NULL,
    page_id integer,
    form_id character varying(40) DEFAULT ''::character varying NOT NULL,
    data json NOT NULL,
    creation_date character varying NOT NULL
);


--
-- Name: landing_form_submission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.landing_form_submission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landing_form_submission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.landing_form_submission_id_seq OWNED BY public.landing_form_submission.id;


--
-- Name: landing_legacy_backup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.landing_legacy_backup (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    legacy json,
    status character varying(20) DEFAULT 'running'::character varying NOT NULL,
    page_uuid character varying(100) DEFAULT ''::character varying NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    error character varying(1000) DEFAULT ''::character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: landing_legacy_backup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.landing_legacy_backup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landing_legacy_backup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.landing_legacy_backup_id_seq OWNED BY public.landing_legacy_backup.id;


--
-- Name: landing_page; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.landing_page (
    id integer NOT NULL,
    page_uuid character varying(100) NOT NULL,
    org_id bigint NOT NULL,
    slug character varying(64) DEFAULT ''::character varying NOT NULL,
    title character varying(120) DEFAULT ''::character varying NOT NULL,
    draft json NOT NULL,
    draft_revision integer DEFAULT 1 NOT NULL,
    draft_updated_at character varying NOT NULL,
    draft_updated_by integer,
    published json,
    published_version integer DEFAULT 0 NOT NULL,
    published_at character varying,
    published_by integer,
    preview_token character varying(64) DEFAULT ''::character varying NOT NULL,
    review json,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: landing_page_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.landing_page_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landing_page_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.landing_page_id_seq OWNED BY public.landing_page.id;


--
-- Name: landing_page_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.landing_page_version (
    id integer NOT NULL,
    version_uuid character varying(100) NOT NULL,
    page_id integer NOT NULL,
    org_id bigint NOT NULL,
    kind character varying(20) NOT NULL,
    label character varying(120) DEFAULT ''::character varying NOT NULL,
    number integer DEFAULT 0 NOT NULL,
    doc json NOT NULL,
    created_by integer,
    creation_date character varying NOT NULL
);


--
-- Name: landing_page_version_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.landing_page_version_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landing_page_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.landing_page_version_id_seq OWNED BY public.landing_page_version.id;


--
-- Name: landing_saved_section; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.landing_saved_section (
    id integer NOT NULL,
    section_uuid character varying(100) NOT NULL,
    org_id bigint NOT NULL,
    name character varying(80) DEFAULT ''::character varying NOT NULL,
    node json NOT NULL,
    symbols json NOT NULL,
    created_by integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: landing_saved_section_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.landing_saved_section_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landing_saved_section_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.landing_saved_section_id_seq OWNED BY public.landing_saved_section.id;


--
-- Name: learner_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learner_note (
    id integer NOT NULL,
    note_uuid character varying NOT NULL,
    org_id integer NOT NULL,
    user_id integer NOT NULL,
    course_id integer NOT NULL,
    activity_id integer NOT NULL,
    content json NOT NULL,
    plain_text text DEFAULT ''::text NOT NULL,
    anchor_kind character varying(16),
    anchor_ref character varying(200),
    anchor_label character varying(200),
    anchor_seconds integer,
    created_at character varying NOT NULL,
    updated_at character varying NOT NULL
);


--
-- Name: learner_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.learner_note_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learner_note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.learner_note_id_seq OWNED BY public.learner_note.id;


--
-- Name: mcp_oauth_client; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_oauth_client (
    id integer NOT NULL,
    client_id character varying(255) NOT NULL,
    client_secret_hash character varying(64),
    client_name character varying(200) NOT NULL,
    client_uri character varying(500),
    logo_uri character varying(500),
    redirect_uris json NOT NULL,
    token_endpoint_auth_method character varying(40) NOT NULL,
    created_at bigint NOT NULL
);


--
-- Name: mcp_oauth_client_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mcp_oauth_client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mcp_oauth_client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mcp_oauth_client_id_seq OWNED BY public.mcp_oauth_client.id;


--
-- Name: mcp_oauth_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_oauth_code (
    code_hash character varying(64) NOT NULL,
    grant_id integer NOT NULL,
    redirect_uri character varying(2000) NOT NULL,
    code_challenge character varying(128) NOT NULL,
    resource character varying(2000),
    scope character varying(200) NOT NULL,
    expires_at bigint NOT NULL
);


--
-- Name: mcp_oauth_grant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_oauth_grant (
    id integer NOT NULL,
    grant_uuid character varying(64) NOT NULL,
    client_id character varying(255) NOT NULL,
    user_id integer NOT NULL,
    org_id integer NOT NULL,
    scope character varying(200) NOT NULL,
    auth_method character varying(40),
    created_at bigint NOT NULL,
    last_used_at bigint,
    revoked_at bigint
);


--
-- Name: mcp_oauth_grant_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mcp_oauth_grant_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mcp_oauth_grant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mcp_oauth_grant_id_seq OWNED BY public.mcp_oauth_grant.id;


--
-- Name: mcp_oauth_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_oauth_token (
    id integer NOT NULL,
    token_hash character varying(64) NOT NULL,
    kind character varying(10) NOT NULL,
    grant_id integer NOT NULL,
    scope character varying(200) NOT NULL,
    resource character varying(2000),
    created_at bigint NOT NULL,
    expires_at bigint NOT NULL,
    revoked_at bigint
);


--
-- Name: mcp_oauth_token_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mcp_oauth_token_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mcp_oauth_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mcp_oauth_token_id_seq OWNED BY public.mcp_oauth_token.id;


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
    name character varying NOT NULL,
    description character varying,
    media_type public.mediatypeenum NOT NULL,
    url character varying,
    thumbnail_image character varying,
    public boolean NOT NULL,
    id integer NOT NULL,
    org_id bigint,
    media_uuid character varying NOT NULL,
    file_id character varying,
    storage_key character varying,
    file_format character varying,
    file_size integer,
    file_mime character varying,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.media_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_id_seq OWNED BY public.media.id;


--
-- Name: mediasharetoken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mediasharetoken (
    id integer NOT NULL,
    token character varying NOT NULL,
    media_uuid character varying NOT NULL,
    org_id bigint,
    created_by_user_id integer,
    revoked boolean NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: mediasharetoken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mediasharetoken_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mediasharetoken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mediasharetoken_id_seq OWNED BY public.mediasharetoken.id;


--
-- Name: message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message (
    id integer NOT NULL,
    message_uuid character varying NOT NULL,
    conversation_id integer NOT NULL,
    org_id bigint NOT NULL,
    sender_user_id integer,
    sender_agent_id integer,
    kind character varying NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    attachment json,
    reply_to_id integer,
    status character varying NOT NULL,
    edited_at character varying,
    deleted_at character varying,
    creation_date character varying NOT NULL
);


--
-- Name: message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_id_seq OWNED BY public.message.id;


--
-- Name: messagereaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messagereaction (
    id integer NOT NULL,
    message_id integer NOT NULL,
    user_id integer NOT NULL,
    emoji character varying NOT NULL,
    creation_date character varying NOT NULL
);


--
-- Name: messagereaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messagereaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messagereaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messagereaction_id_seq OWNED BY public.messagereaction.id;


--
-- Name: messagereminder; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messagereminder (
    id integer NOT NULL,
    reminder_uuid character varying NOT NULL,
    org_id bigint NOT NULL,
    user_id integer NOT NULL,
    conversation_id integer NOT NULL,
    agent_id integer,
    text text NOT NULL,
    due_at character varying NOT NULL,
    source_message_id integer,
    sent_at character varying,
    cancelled_at character varying,
    creation_date character varying NOT NULL
);


--
-- Name: messagereminder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messagereminder_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messagereminder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messagereminder_id_seq OWNED BY public.messagereminder.id;


--
-- Name: messagingprofile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messagingprofile (
    id integer NOT NULL,
    user_id integer NOT NULL,
    availability character varying NOT NULL,
    status_emoji character varying NOT NULL,
    status_text character varying NOT NULL,
    status_expires_at character varying,
    last_seen_at character varying,
    allow_dms boolean NOT NULL,
    email_mode character varying NOT NULL,
    email_delay_minutes integer NOT NULL,
    email_broadcasts boolean NOT NULL,
    desktop_notifications boolean NOT NULL,
    sounds boolean NOT NULL,
    read_receipts boolean NOT NULL,
    typing_indicators boolean NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: messagingprofile_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messagingprofile_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messagingprofile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messagingprofile_id_seq OWNED BY public.messagingprofile.id;


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    id integer NOT NULL,
    notification_uuid character varying NOT NULL,
    user_id integer NOT NULL,
    org_id bigint,
    type character varying NOT NULL,
    category character varying NOT NULL,
    title character varying NOT NULL,
    body text DEFAULT ''::text NOT NULL,
    data json,
    image character varying,
    group_key character varying,
    dedupe_key character varying,
    count integer NOT NULL,
    audience character varying DEFAULT 'personal'::character varying NOT NULL,
    priority character varying DEFAULT 'normal'::character varying NOT NULL,
    actor_id integer,
    archived_at character varying,
    expires_at character varying,
    emailed_at character varying,
    read_at character varying,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_id_seq OWNED BY public.notification.id;


--
-- Name: notification_preference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_preference (
    id integer NOT NULL,
    user_id integer NOT NULL,
    push_enabled boolean NOT NULL,
    push_categories json,
    channels json,
    email_digest character varying DEFAULT 'off'::character varying NOT NULL,
    last_digest_at character varying,
    update_date character varying NOT NULL
);


--
-- Name: notification_preference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_preference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_preference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_preference_id_seq OWNED BY public.notification_preference.id;


--
-- Name: nudge_send; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nudge_send (
    id integer NOT NULL,
    nudge_id character varying(64) NOT NULL,
    dedupe_key character varying(160) NOT NULL,
    org_id bigint NOT NULL,
    user_id integer NOT NULL,
    status character varying(16) NOT NULL,
    lang character varying(8) NOT NULL,
    claimed_at timestamp with time zone NOT NULL,
    sent_at timestamp with time zone,
    error character varying(255),
    provider_id character varying(64),
    delivery_checked boolean NOT NULL,
    meta json
);


--
-- Name: nudge_send_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nudge_send_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nudge_send_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nudge_send_id_seq OWNED BY public.nudge_send.id;


--
-- Name: org_downgrade; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_downgrade (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    from_plan character varying(32) NOT NULL,
    to_plan character varying(32) NOT NULL,
    reason character varying(32) NOT NULL,
    changes json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    restored_at timestamp with time zone,
    restored_to_plan character varying(32)
);


--
-- Name: org_downgrade_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.org_downgrade_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_downgrade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.org_downgrade_id_seq OWNED BY public.org_downgrade.id;


--
-- Name: org_invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_invitation (
    id integer NOT NULL,
    invitation_uuid character varying(64) NOT NULL,
    org_id integer NOT NULL,
    email character varying(320) NOT NULL,
    role_id integer,
    usergroup_ids json NOT NULL,
    course_uuids json NOT NULL,
    message text,
    invited_by_user_id integer,
    status character varying(16) NOT NULL,
    token_hash character varying(64),
    token_delivery character varying(16),
    copy_token_hash character varying(64),
    expires_at timestamp with time zone NOT NULL,
    accepted_at timestamp with time zone,
    accepted_user_id integer,
    email_sent boolean NOT NULL,
    send_count integer NOT NULL,
    last_sent_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: org_invitation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.org_invitation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_invitation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.org_invitation_id_seq OWNED BY public.org_invitation.id;


--
-- Name: org_invite_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_invite_code (
    id integer NOT NULL,
    code_uuid character varying(64) NOT NULL,
    org_id integer NOT NULL,
    code character varying(32) NOT NULL,
    role_id integer,
    usergroup_ids json NOT NULL,
    course_uuids json NOT NULL,
    max_uses integer,
    uses integer NOT NULL,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_by_user_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: org_invite_code_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.org_invite_code_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_invite_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.org_invite_code_id_seq OWNED BY public.org_invite_code.id;


--
-- Name: org_member_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_member_profile (
    org_id integer NOT NULL,
    user_id integer NOT NULL,
    manager_user_id integer,
    department character varying(200),
    title character varying(200),
    employee_id character varying(100),
    cost_center character varying(100),
    location character varying(200),
    employment_status character varying(16) NOT NULL,
    source character varying(16) NOT NULL,
    external_id character varying(255),
    attributes json,
    digest_opt_out boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: org_notification_setting; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_notification_setting (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    admin_routing json,
    update_date character varying NOT NULL
);


--
-- Name: org_notification_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.org_notification_setting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_notification_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.org_notification_setting_id_seq OWNED BY public.org_notification_setting.id;


--
-- Name: org_onboarding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_onboarding (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    goal character varying(32),
    state json NOT NULL,
    milestones json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: org_onboarding_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.org_onboarding_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_onboarding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.org_onboarding_id_seq OWNED BY public.org_onboarding.id;


--
-- Name: org_trial; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_trial (
    org_id bigint NOT NULL,
    plan character varying(32) NOT NULL,
    status character varying(16) NOT NULL,
    started_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    converted_plan character varying(32),
    created_by_user_id integer
);


--
-- Name: organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization (
    name character varying NOT NULL,
    description character varying,
    about character varying,
    socials json,
    links json,
    scripts json,
    logo_image character varying,
    thumbnail_image character varying,
    previews json,
    label character varying,
    email character varying NOT NULL,
    id integer NOT NULL,
    org_uuid character varying NOT NULL,
    slug character varying NOT NULL,
    explore boolean,
    is_demo boolean NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: organization_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organization_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organization_id_seq OWNED BY public.organization.id;


--
-- Name: organization_plan_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_plan_history (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    plan character varying(64) NOT NULL,
    effective_from timestamp with time zone NOT NULL
);


--
-- Name: organization_plan_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organization_plan_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_plan_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organization_plan_history_id_seq OWNED BY public.organization_plan_history.id;


--
-- Name: organizationconfig; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizationconfig (
    id integer NOT NULL,
    org_id bigint,
    config json,
    creation_date character varying,
    update_date character varying
);


--
-- Name: organizationconfig_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizationconfig_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizationconfig_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizationconfig_id_seq OWNED BY public.organizationconfig.id;


--
-- Name: orgpack; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orgpack (
    id integer NOT NULL,
    org_id bigint,
    pack_type public.packtypeenum NOT NULL,
    pack_id character varying NOT NULL,
    quantity integer NOT NULL,
    status public.packstatusenum NOT NULL,
    activated_at timestamp without time zone NOT NULL,
    cancelled_at timestamp without time zone,
    cancel_at_period_end boolean DEFAULT false NOT NULL,
    platform_subscription_id character varying NOT NULL
);


--
-- Name: orgpack_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orgpack_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orgpack_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orgpack_id_seq OWNED BY public.orgpack.id;


--
-- Name: path; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.path (
    name character varying NOT NULL,
    description character varying,
    about character varying,
    thumbnail_image character varying,
    level character varying,
    public boolean NOT NULL,
    published boolean NOT NULL,
    sequential boolean NOT NULL,
    electives_required integer NOT NULL,
    certificate_enabled boolean NOT NULL,
    id integer NOT NULL,
    org_id bigint NOT NULL,
    path_uuid character varying NOT NULL,
    slug character varying(100),
    seo jsonb,
    certificate_config json,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: path_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.path_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: path_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.path_id_seq OWNED BY public.path.id;


--
-- Name: pathcertificate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pathcertificate (
    id integer NOT NULL,
    path_id integer NOT NULL,
    user_id integer NOT NULL,
    certificate_uuid character varying NOT NULL,
    created_at character varying NOT NULL,
    revoked_at character varying
);


--
-- Name: pathcertificate_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pathcertificate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pathcertificate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pathcertificate_id_seq OWNED BY public.pathcertificate.id;


--
-- Name: pathcourse; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pathcourse (
    id integer NOT NULL,
    path_id integer NOT NULL,
    course_id integer NOT NULL,
    "position" integer NOT NULL,
    required boolean NOT NULL,
    creation_date character varying NOT NULL
);


--
-- Name: pathcourse_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pathcourse_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pathcourse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pathcourse_id_seq OWNED BY public.pathcourse.id;


--
-- Name: pathenrollment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pathenrollment (
    id integer NOT NULL,
    path_id integer NOT NULL,
    user_id integer NOT NULL,
    enrolled_at character varying NOT NULL,
    completed_at character varying
);


--
-- Name: pathenrollment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pathenrollment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pathenrollment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pathenrollment_id_seq OWNED BY public.pathenrollment.id;


--
-- Name: podcast; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.podcast (
    name character varying NOT NULL,
    description character varying,
    about character varying,
    tags character varying,
    thumbnail_image character varying,
    public boolean NOT NULL,
    published boolean NOT NULL,
    id integer NOT NULL,
    org_id integer,
    podcast_uuid character varying NOT NULL,
    slug character varying(100),
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    seo jsonb
);


--
-- Name: podcast_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.podcast_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: podcast_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.podcast_id_seq OWNED BY public.podcast.id;


--
-- Name: podcastepisode; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.podcastepisode (
    title character varying NOT NULL,
    description character varying,
    audio_file character varying,
    duration_seconds integer,
    episode_number integer,
    thumbnail_image character varying,
    published boolean NOT NULL,
    "order" integer NOT NULL,
    id integer NOT NULL,
    podcast_id integer,
    org_id integer,
    episode_uuid character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: podcastepisode_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.podcastepisode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: podcastepisode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.podcastepisode_id_seq OWNED BY public.podcastepisode.id;


--
-- Name: push_device; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.push_device (
    id integer NOT NULL,
    user_id integer NOT NULL,
    org_id bigint,
    token character varying NOT NULL,
    platform character varying NOT NULL,
    device_name character varying NOT NULL,
    app_version character varying NOT NULL,
    creation_date character varying NOT NULL,
    last_seen_at character varying NOT NULL
);


--
-- Name: push_device_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.push_device_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_device_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.push_device_id_seq OWNED BY public.push_device.id;


--
-- Name: resource_slug_redirect; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_slug_redirect (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    resource_type character varying(32) NOT NULL,
    resource_uuid character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    creation_date character varying NOT NULL
);


--
-- Name: resource_slug_redirect_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resource_slug_redirect_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resource_slug_redirect_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resource_slug_redirect_id_seq OWNED BY public.resource_slug_redirect.id;


--
-- Name: resourceauthor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resourceauthor (
    id integer NOT NULL,
    resource_uuid character varying NOT NULL,
    user_id integer,
    authorship public.resourceauthorshipenum NOT NULL,
    authorship_status public.resourceauthorshipstatusenum NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: resourceauthor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resourceauthor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resourceauthor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resourceauthor_id_seq OWNED BY public.resourceauthor.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role (
    name character varying NOT NULL,
    description character varying,
    rights json,
    id integer NOT NULL,
    org_id integer,
    role_type public.roletypeenum NOT NULL,
    role_uuid character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_id_seq OWNED BY public.role.id;


--
-- Name: superadmin_apitoken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.superadmin_apitoken (
    name character varying(100) NOT NULL,
    description character varying(500),
    id integer NOT NULL,
    token_uuid character varying(100) NOT NULL,
    token_prefix character varying(15) NOT NULL,
    token_hash character varying(255),
    created_by_user_id integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    last_used_at character varying,
    expires_at character varying,
    is_active boolean NOT NULL
);


--
-- Name: superadmin_apitoken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.superadmin_apitoken_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: superadmin_apitoken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.superadmin_apitoken_id_seq OWNED BY public.superadmin_apitoken.id;


--
-- Name: trail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trail (
    org_id integer,
    user_id integer,
    id integer NOT NULL,
    trail_uuid character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: trail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trail_id_seq OWNED BY public.trail.id;


--
-- Name: trailrun; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trailrun (
    id integer NOT NULL,
    data json,
    status public.statusenum NOT NULL,
    trail_id integer,
    course_id integer,
    org_id integer,
    user_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: trailrun_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trailrun_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trailrun_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trailrun_id_seq OWNED BY public.trailrun.id;


--
-- Name: trailstep; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trailstep (
    id integer NOT NULL,
    complete boolean NOT NULL,
    teacher_verified boolean NOT NULL,
    grade character varying NOT NULL,
    data json,
    trailrun_id integer,
    trail_id integer,
    activity_id integer,
    course_id integer,
    org_id integer,
    user_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: trailstep_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trailstep_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trailstep_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trailstep_id_seq OWNED BY public.trailstep.id;


--
-- Name: usageevent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usageevent (
    id integer NOT NULL,
    org_id bigint,
    feature character varying NOT NULL,
    event_type character varying NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    usage_after integer NOT NULL
);


--
-- Name: usageevent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usageevent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usageevent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usageevent_id_seq OWNED BY public.usageevent.id;


--
-- Name: used_link_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.used_link_token (
    jti character varying(128) NOT NULL,
    purpose character varying(32) NOT NULL,
    expires_at bigint NOT NULL
);


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    username character varying NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    email character varying NOT NULL,
    avatar_image character varying,
    bio character varying,
    details json,
    profile json,
    extra_metadata jsonb,
    id integer NOT NULL,
    password character varying NOT NULL,
    user_uuid character varying NOT NULL,
    email_verified boolean NOT NULL,
    email_verified_at character varying,
    failed_login_attempts integer NOT NULL,
    locked_until character varying,
    last_login_at character varying,
    last_login_ip character varying,
    signup_method character varying,
    is_superadmin boolean NOT NULL,
    password_changed_at timestamp without time zone,
    ui_preferences jsonb,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: user_activity_day; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_activity_day (
    id integer NOT NULL,
    org_id bigint NOT NULL,
    user_id integer NOT NULL,
    activity_date date NOT NULL,
    first_seen_at timestamp with time zone NOT NULL
);


--
-- Name: user_activity_day_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_activity_day_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_activity_day_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_activity_day_id_seq OWNED BY public.user_activity_day.id;


--
-- Name: user_audit_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_audit_event (
    id integer NOT NULL,
    org_id integer,
    user_id integer NOT NULL,
    event_type character varying(64) NOT NULL,
    ip character varying(64),
    user_agent text,
    target_uuid character varying(128),
    audit_metadata json,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: user_audit_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_audit_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_audit_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_audit_event_id_seq OWNED BY public.user_audit_event.id;


--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: usergroup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup (
    name character varying NOT NULL,
    description character varying NOT NULL,
    id integer NOT NULL,
    org_id integer NOT NULL,
    usergroup_uuid character varying NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    kind character varying(16) DEFAULT 'manual'::character varying NOT NULL,
    rules json,
    parent_id integer,
    color character varying(16),
    settings json,
    last_synced_at timestamp with time zone
);


--
-- Name: usergroup_announcement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup_announcement (
    id integer NOT NULL,
    announcement_uuid character varying(64) NOT NULL,
    usergroup_id integer NOT NULL,
    org_id integer NOT NULL,
    author_id integer,
    title character varying(200) NOT NULL,
    body text DEFAULT ''::text NOT NULL,
    pinned boolean DEFAULT false NOT NULL,
    emailed integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: usergroup_announcement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroup_announcement_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroup_announcement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroup_announcement_id_seq OWNED BY public.usergroup_announcement.id;


--
-- Name: usergroup_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup_event (
    id integer NOT NULL,
    usergroup_id integer NOT NULL,
    org_id integer NOT NULL,
    action character varying(48) NOT NULL,
    actor_id integer,
    via character varying(24) DEFAULT ''::character varying NOT NULL,
    details json,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: usergroup_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroup_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroup_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroup_event_id_seq OWNED BY public.usergroup_event.id;


--
-- Name: usergroup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroup_id_seq OWNED BY public.usergroup.id;


--
-- Name: usergroup_join_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup_join_code (
    id integer NOT NULL,
    usergroup_id integer NOT NULL,
    org_id integer NOT NULL,
    code character varying(32) NOT NULL,
    label character varying(120) DEFAULT ''::character varying NOT NULL,
    max_uses integer,
    uses integer DEFAULT 0 NOT NULL,
    expires_at timestamp with time zone,
    membership_days integer,
    active boolean DEFAULT true NOT NULL,
    created_by_id integer,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: usergroup_join_code_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroup_join_code_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroup_join_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroup_join_code_id_seq OWNED BY public.usergroup_join_code.id;


--
-- Name: usergroup_manager; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup_manager (
    id integer NOT NULL,
    usergroup_id integer NOT NULL,
    user_id integer NOT NULL,
    org_id integer NOT NULL,
    can_manage_members boolean DEFAULT true NOT NULL,
    can_view_progress boolean DEFAULT true NOT NULL,
    can_post boolean DEFAULT true NOT NULL,
    digest boolean DEFAULT false NOT NULL,
    created_by_id integer,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: usergroup_manager_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroup_manager_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroup_manager_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroup_manager_id_seq OWNED BY public.usergroup_manager.id;


--
-- Name: usergroup_schedule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup_schedule (
    id integer NOT NULL,
    usergroup_id integer NOT NULL,
    org_id integer NOT NULL,
    user_id integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone,
    status character varying(16) DEFAULT 'pending'::character varying NOT NULL,
    created_by_id integer,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: usergroup_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroup_schedule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroup_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroup_schedule_id_seq OWNED BY public.usergroup_schedule.id;


--
-- Name: usergroupresource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroupresource (
    id integer NOT NULL,
    usergroup_id integer,
    resource_uuid character varying NOT NULL,
    org_id integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    starts_at timestamp with time zone,
    expires_at timestamp with time zone
);


--
-- Name: usergroupresource_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroupresource_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroupresource_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroupresource_id_seq OWNED BY public.usergroupresource.id;


--
-- Name: usergroupuser; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroupuser (
    id integer NOT NULL,
    usergroup_id integer NOT NULL,
    user_id integer NOT NULL,
    org_id integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL,
    sources json,
    expires_at timestamp with time zone,
    added_by_id integer
);


--
-- Name: usergroupuser_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usergroupuser_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usergroupuser_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usergroupuser_id_seq OWNED BY public.usergroupuser.id;


--
-- Name: usermfa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usermfa (
    id integer NOT NULL,
    user_id integer NOT NULL,
    secret_encrypted character varying NOT NULL,
    confirmed_at character varying,
    last_used_timestep integer,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: usermfa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usermfa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usermfa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usermfa_id_seq OWNED BY public.usermfa.id;


--
-- Name: usermfabackupcode; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usermfabackupcode (
    id integer NOT NULL,
    user_id integer NOT NULL,
    code_hash character varying NOT NULL,
    used_at character varying,
    creation_date character varying NOT NULL
);


--
-- Name: usermfabackupcode_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usermfabackupcode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usermfabackupcode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usermfabackupcode_id_seq OWNED BY public.usermfabackupcode.id;


--
-- Name: userorganization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.userorganization (
    id integer NOT NULL,
    user_id integer NOT NULL,
    org_id integer NOT NULL,
    role_id integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: userorganization_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.userorganization_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: userorganization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.userorganization_id_seq OWNED BY public.userorganization.id;


--
-- Name: webhook_delivery_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_delivery_log (
    id integer NOT NULL,
    webhook_id integer NOT NULL,
    event_name character varying(100) NOT NULL,
    delivery_uuid character varying(100) NOT NULL,
    request_payload json,
    response_status integer,
    response_body character varying(500),
    success boolean NOT NULL,
    attempt integer NOT NULL,
    error_message character varying(1000),
    created_at character varying NOT NULL
);


--
-- Name: webhook_delivery_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webhook_delivery_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhook_delivery_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webhook_delivery_log_id_seq OWNED BY public.webhook_delivery_log.id;


--
-- Name: webhook_endpoint; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_endpoint (
    id integer NOT NULL,
    webhook_uuid character varying(100) NOT NULL,
    org_id integer NOT NULL,
    url character varying(2048) NOT NULL,
    secret_encrypted text NOT NULL,
    description character varying(500),
    events json NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    source character varying(20) DEFAULT 'manual'::character varying NOT NULL,
    zap_name character varying(200),
    zap_id character varying(100),
    created_by_user_id integer NOT NULL,
    creation_date character varying NOT NULL,
    update_date character varying NOT NULL
);


--
-- Name: webhook_endpoint_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webhook_endpoint_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhook_endpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webhook_endpoint_id_seq OWNED BY public.webhook_endpoint.id;


--
-- Name: activity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity ALTER COLUMN id SET DEFAULT nextval('public.activity_id_seq'::regclass);


--
-- Name: activity_comment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment ALTER COLUMN id SET DEFAULT nextval('public.activity_comment_id_seq'::regclass);


--
-- Name: activity_comment_thread id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment_thread ALTER COLUMN id SET DEFAULT nextval('public.activity_comment_thread_id_seq'::regclass);


--
-- Name: activity_translation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation ALTER COLUMN id SET DEFAULT nextval('public.activity_translation_id_seq'::regclass);


--
-- Name: activityversion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activityversion ALTER COLUMN id SET DEFAULT nextval('public.activityversion_id_seq'::regclass);


--
-- Name: agent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent ALTER COLUMN id SET DEFAULT nextval('public.agent_id_seq'::regclass);


--
-- Name: ai_usage_event id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_usage_event ALTER COLUMN id SET DEFAULT nextval('public.ai_usage_event_id_seq'::regclass);


--
-- Name: aigeneration id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aigeneration ALTER COLUMN id SET DEFAULT nextval('public.aigeneration_id_seq'::regclass);


--
-- Name: apitoken id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apitoken ALTER COLUMN id SET DEFAULT nextval('public.apitoken_id_seq'::regclass);


--
-- Name: assignment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment ALTER COLUMN id SET DEFAULT nextval('public.assignment_id_seq'::regclass);


--
-- Name: assignmentaigrade id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentaigrade ALTER COLUMN id SET DEFAULT nextval('public.assignmentaigrade_id_seq'::regclass);


--
-- Name: assignmenttask id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttask ALTER COLUMN id SET DEFAULT nextval('public.assignmenttask_id_seq'::regclass);


--
-- Name: assignmenttasksubmission id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission ALTER COLUMN id SET DEFAULT nextval('public.assignmenttasksubmission_id_seq'::regclass);


--
-- Name: assignmentusersubmission id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentusersubmission ALTER COLUMN id SET DEFAULT nextval('public.assignmentusersubmission_id_seq'::regclass);


--
-- Name: block id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block ALTER COLUMN id SET DEFAULT nextval('public.block_id_seq'::regclass);


--
-- Name: certificateuser id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificateuser ALTER COLUMN id SET DEFAULT nextval('public.certificateuser_id_seq'::regclass);


--
-- Name: certifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications ALTER COLUMN id SET DEFAULT nextval('public.certifications_id_seq'::regclass);


--
-- Name: chapter id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter ALTER COLUMN id SET DEFAULT nextval('public.chapter_id_seq'::regclass);


--
-- Name: chapter_translation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter_translation ALTER COLUMN id SET DEFAULT nextval('public.chapter_translation_id_seq'::regclass);


--
-- Name: chapteractivity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapteractivity ALTER COLUMN id SET DEFAULT nextval('public.chapteractivity_id_seq'::regclass);


--
-- Name: code_submission id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_submission ALTER COLUMN id SET DEFAULT nextval('public.code_submission_id_seq'::regclass);


--
-- Name: community id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community ALTER COLUMN id SET DEFAULT nextval('public.community_id_seq'::regclass);


--
-- Name: conversation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation ALTER COLUMN id SET DEFAULT nextval('public.conversation_id_seq'::regclass);


--
-- Name: conversationmember id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversationmember ALTER COLUMN id SET DEFAULT nextval('public.conversationmember_id_seq'::regclass);


--
-- Name: course id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course ALTER COLUMN id SET DEFAULT nextval('public.course_id_seq'::regclass);


--
-- Name: course_embedding id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_embedding ALTER COLUMN id SET DEFAULT nextval('public.course_embedding_id_seq'::regclass);


--
-- Name: course_translation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_translation ALTER COLUMN id SET DEFAULT nextval('public.course_translation_id_seq'::regclass);


--
-- Name: coursechapter id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coursechapter ALTER COLUMN id SET DEFAULT nextval('public.coursechapter_id_seq'::regclass);


--
-- Name: courseupdate id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courseupdate ALTER COLUMN id SET DEFAULT nextval('public.courseupdate_id_seq'::regclass);


--
-- Name: customdomain id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customdomain ALTER COLUMN id SET DEFAULT nextval('public.customdomain_id_seq'::regclass);


--
-- Name: discussion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion ALTER COLUMN id SET DEFAULT nextval('public.discussion_id_seq'::regclass);


--
-- Name: discussioncomment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncomment ALTER COLUMN id SET DEFAULT nextval('public.discussioncomment_id_seq'::regclass);


--
-- Name: discussioncommentvote id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncommentvote ALTER COLUMN id SET DEFAULT nextval('public.discussioncommentvote_id_seq'::regclass);


--
-- Name: discussionreaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionreaction ALTER COLUMN id SET DEFAULT nextval('public.discussionreaction_id_seq'::regclass);


--
-- Name: discussionvote id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionvote ALTER COLUMN id SET DEFAULT nextval('public.discussionvote_id_seq'::regclass);


--
-- Name: drip_notification id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drip_notification ALTER COLUMN id SET DEFAULT nextval('public.drip_notification_id_seq'::regclass);


--
-- Name: editortemplate id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editortemplate ALTER COLUMN id SET DEFAULT nextval('public.editortemplate_id_seq'::regclass);


--
-- Name: editorvariable id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editorvariable ALTER COLUMN id SET DEFAULT nextval('public.editorvariable_id_seq'::regclass);


--
-- Name: email_preference id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_preference ALTER COLUMN id SET DEFAULT nextval('public.email_preference_id_seq'::regclass);


--
-- Name: folder id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folder ALTER COLUMN id SET DEFAULT nextval('public.folder_id_seq'::regclass);


--
-- Name: foldercontent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.foldercontent ALTER COLUMN id SET DEFAULT nextval('public.foldercontent_id_seq'::regclass);


--
-- Name: landing_form_submission id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_form_submission ALTER COLUMN id SET DEFAULT nextval('public.landing_form_submission_id_seq'::regclass);


--
-- Name: landing_legacy_backup id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_legacy_backup ALTER COLUMN id SET DEFAULT nextval('public.landing_legacy_backup_id_seq'::regclass);


--
-- Name: landing_page id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page ALTER COLUMN id SET DEFAULT nextval('public.landing_page_id_seq'::regclass);


--
-- Name: landing_page_version id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_version ALTER COLUMN id SET DEFAULT nextval('public.landing_page_version_id_seq'::regclass);


--
-- Name: landing_saved_section id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_saved_section ALTER COLUMN id SET DEFAULT nextval('public.landing_saved_section_id_seq'::regclass);


--
-- Name: learner_note id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learner_note ALTER COLUMN id SET DEFAULT nextval('public.learner_note_id_seq'::regclass);


--
-- Name: mcp_oauth_client id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_client ALTER COLUMN id SET DEFAULT nextval('public.mcp_oauth_client_id_seq'::regclass);


--
-- Name: mcp_oauth_grant id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_grant ALTER COLUMN id SET DEFAULT nextval('public.mcp_oauth_grant_id_seq'::regclass);


--
-- Name: mcp_oauth_token id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_token ALTER COLUMN id SET DEFAULT nextval('public.mcp_oauth_token_id_seq'::regclass);


--
-- Name: media id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.media_id_seq'::regclass);


--
-- Name: mediasharetoken id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediasharetoken ALTER COLUMN id SET DEFAULT nextval('public.mediasharetoken_id_seq'::regclass);


--
-- Name: message id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message ALTER COLUMN id SET DEFAULT nextval('public.message_id_seq'::regclass);


--
-- Name: messagereaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereaction ALTER COLUMN id SET DEFAULT nextval('public.messagereaction_id_seq'::regclass);


--
-- Name: messagereminder id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereminder ALTER COLUMN id SET DEFAULT nextval('public.messagereminder_id_seq'::regclass);


--
-- Name: messagingprofile id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagingprofile ALTER COLUMN id SET DEFAULT nextval('public.messagingprofile_id_seq'::regclass);


--
-- Name: notification id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification ALTER COLUMN id SET DEFAULT nextval('public.notification_id_seq'::regclass);


--
-- Name: notification_preference id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preference ALTER COLUMN id SET DEFAULT nextval('public.notification_preference_id_seq'::regclass);


--
-- Name: nudge_send id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nudge_send ALTER COLUMN id SET DEFAULT nextval('public.nudge_send_id_seq'::regclass);


--
-- Name: org_downgrade id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_downgrade ALTER COLUMN id SET DEFAULT nextval('public.org_downgrade_id_seq'::regclass);


--
-- Name: org_invitation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation ALTER COLUMN id SET DEFAULT nextval('public.org_invitation_id_seq'::regclass);


--
-- Name: org_invite_code id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite_code ALTER COLUMN id SET DEFAULT nextval('public.org_invite_code_id_seq'::regclass);


--
-- Name: org_notification_setting id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_notification_setting ALTER COLUMN id SET DEFAULT nextval('public.org_notification_setting_id_seq'::regclass);


--
-- Name: org_onboarding id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_onboarding ALTER COLUMN id SET DEFAULT nextval('public.org_onboarding_id_seq'::regclass);


--
-- Name: organization id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization ALTER COLUMN id SET DEFAULT nextval('public.organization_id_seq'::regclass);


--
-- Name: organization_plan_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_plan_history ALTER COLUMN id SET DEFAULT nextval('public.organization_plan_history_id_seq'::regclass);


--
-- Name: organizationconfig id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizationconfig ALTER COLUMN id SET DEFAULT nextval('public.organizationconfig_id_seq'::regclass);


--
-- Name: orgpack id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgpack ALTER COLUMN id SET DEFAULT nextval('public.orgpack_id_seq'::regclass);


--
-- Name: path id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.path ALTER COLUMN id SET DEFAULT nextval('public.path_id_seq'::regclass);


--
-- Name: pathcertificate id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcertificate ALTER COLUMN id SET DEFAULT nextval('public.pathcertificate_id_seq'::regclass);


--
-- Name: pathcourse id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcourse ALTER COLUMN id SET DEFAULT nextval('public.pathcourse_id_seq'::regclass);


--
-- Name: pathenrollment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathenrollment ALTER COLUMN id SET DEFAULT nextval('public.pathenrollment_id_seq'::regclass);


--
-- Name: podcast id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast ALTER COLUMN id SET DEFAULT nextval('public.podcast_id_seq'::regclass);


--
-- Name: podcastepisode id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcastepisode ALTER COLUMN id SET DEFAULT nextval('public.podcastepisode_id_seq'::regclass);


--
-- Name: push_device id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_device ALTER COLUMN id SET DEFAULT nextval('public.push_device_id_seq'::regclass);


--
-- Name: resource_slug_redirect id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_slug_redirect ALTER COLUMN id SET DEFAULT nextval('public.resource_slug_redirect_id_seq'::regclass);


--
-- Name: resourceauthor id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resourceauthor ALTER COLUMN id SET DEFAULT nextval('public.resourceauthor_id_seq'::regclass);


--
-- Name: role id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role ALTER COLUMN id SET DEFAULT nextval('public.role_id_seq'::regclass);


--
-- Name: superadmin_apitoken id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.superadmin_apitoken ALTER COLUMN id SET DEFAULT nextval('public.superadmin_apitoken_id_seq'::regclass);


--
-- Name: trail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trail ALTER COLUMN id SET DEFAULT nextval('public.trail_id_seq'::regclass);


--
-- Name: trailrun id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailrun ALTER COLUMN id SET DEFAULT nextval('public.trailrun_id_seq'::regclass);


--
-- Name: trailstep id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep ALTER COLUMN id SET DEFAULT nextval('public.trailstep_id_seq'::regclass);


--
-- Name: usageevent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usageevent ALTER COLUMN id SET DEFAULT nextval('public.usageevent_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: user_activity_day id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_day ALTER COLUMN id SET DEFAULT nextval('public.user_activity_day_id_seq'::regclass);


--
-- Name: user_audit_event id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_audit_event ALTER COLUMN id SET DEFAULT nextval('public.user_audit_event_id_seq'::regclass);


--
-- Name: usergroup id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup ALTER COLUMN id SET DEFAULT nextval('public.usergroup_id_seq'::regclass);


--
-- Name: usergroup_announcement id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_announcement ALTER COLUMN id SET DEFAULT nextval('public.usergroup_announcement_id_seq'::regclass);


--
-- Name: usergroup_event id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_event ALTER COLUMN id SET DEFAULT nextval('public.usergroup_event_id_seq'::regclass);


--
-- Name: usergroup_join_code id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_join_code ALTER COLUMN id SET DEFAULT nextval('public.usergroup_join_code_id_seq'::regclass);


--
-- Name: usergroup_manager id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_manager ALTER COLUMN id SET DEFAULT nextval('public.usergroup_manager_id_seq'::regclass);


--
-- Name: usergroup_schedule id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_schedule ALTER COLUMN id SET DEFAULT nextval('public.usergroup_schedule_id_seq'::regclass);


--
-- Name: usergroupresource id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupresource ALTER COLUMN id SET DEFAULT nextval('public.usergroupresource_id_seq'::regclass);


--
-- Name: usergroupuser id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupuser ALTER COLUMN id SET DEFAULT nextval('public.usergroupuser_id_seq'::regclass);


--
-- Name: usermfa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usermfa ALTER COLUMN id SET DEFAULT nextval('public.usermfa_id_seq'::regclass);


--
-- Name: usermfabackupcode id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usermfabackupcode ALTER COLUMN id SET DEFAULT nextval('public.usermfabackupcode_id_seq'::regclass);


--
-- Name: userorganization id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userorganization ALTER COLUMN id SET DEFAULT nextval('public.userorganization_id_seq'::regclass);


--
-- Name: webhook_delivery_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_delivery_log ALTER COLUMN id SET DEFAULT nextval('public.webhook_delivery_log_id_seq'::regclass);


--
-- Name: webhook_endpoint id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoint ALTER COLUMN id SET DEFAULT nextval('public.webhook_endpoint_id_seq'::regclass);


--
-- Name: activity_comment activity_comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment
    ADD CONSTRAINT activity_comment_pkey PRIMARY KEY (id);


--
-- Name: activity_comment_thread activity_comment_thread_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment_thread
    ADD CONSTRAINT activity_comment_thread_pkey PRIMARY KEY (id);


--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- Name: activity_translation_collab activity_translation_collab_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation_collab
    ADD CONSTRAINT activity_translation_collab_pkey PRIMARY KEY (translation_id);


--
-- Name: activity_translation activity_translation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation
    ADD CONSTRAINT activity_translation_pkey PRIMARY KEY (id);


--
-- Name: activitycollabstate activitycollabstate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activitycollabstate
    ADD CONSTRAINT activitycollabstate_pkey PRIMARY KEY (activity_id);


--
-- Name: activityversion activityversion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activityversion
    ADD CONSTRAINT activityversion_pkey PRIMARY KEY (id);


--
-- Name: agent agent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_pkey PRIMARY KEY (id);


--
-- Name: ai_usage_event ai_usage_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_usage_event
    ADD CONSTRAINT ai_usage_event_pkey PRIMARY KEY (id);


--
-- Name: aigeneration aigeneration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aigeneration
    ADD CONSTRAINT aigeneration_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: apitoken apitoken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apitoken
    ADD CONSTRAINT apitoken_pkey PRIMARY KEY (id);


--
-- Name: assignment assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_pkey PRIMARY KEY (id);


--
-- Name: assignmentaigrade assignmentaigrade_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentaigrade
    ADD CONSTRAINT assignmentaigrade_pkey PRIMARY KEY (id);


--
-- Name: assignmenttask assignmenttask_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttask
    ADD CONSTRAINT assignmenttask_pkey PRIMARY KEY (id);


--
-- Name: assignmenttasksubmission assignmenttasksubmission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission
    ADD CONSTRAINT assignmenttasksubmission_pkey PRIMARY KEY (id);


--
-- Name: assignmentusersubmission assignmentusersubmission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentusersubmission
    ADD CONSTRAINT assignmentusersubmission_pkey PRIMARY KEY (id);


--
-- Name: block block_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block
    ADD CONSTRAINT block_pkey PRIMARY KEY (id);


--
-- Name: certificateuser certificateuser_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificateuser
    ADD CONSTRAINT certificateuser_pkey PRIMARY KEY (id);


--
-- Name: certifications certifications_certification_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT certifications_certification_uuid_key UNIQUE (certification_uuid);


--
-- Name: certifications certifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT certifications_pkey PRIMARY KEY (id);


--
-- Name: chapter chapter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (id);


--
-- Name: chapter_translation chapter_translation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter_translation
    ADD CONSTRAINT chapter_translation_pkey PRIMARY KEY (id);


--
-- Name: chapteractivity chapteractivity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapteractivity
    ADD CONSTRAINT chapteractivity_pkey PRIMARY KEY (id);


--
-- Name: code_submission code_submission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.code_submission
    ADD CONSTRAINT code_submission_pkey PRIMARY KEY (id);


--
-- Name: community community_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community
    ADD CONSTRAINT community_pkey PRIMARY KEY (id);


--
-- Name: conversation conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_pkey PRIMARY KEY (id);


--
-- Name: conversationmember conversationmember_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversationmember
    ADD CONSTRAINT conversationmember_pkey PRIMARY KEY (id);


--
-- Name: course_embedding course_embedding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_embedding
    ADD CONSTRAINT course_embedding_pkey PRIMARY KEY (id);


--
-- Name: course course_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_pkey PRIMARY KEY (id);


--
-- Name: course_translation course_translation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_translation
    ADD CONSTRAINT course_translation_pkey PRIMARY KEY (id);


--
-- Name: coursechapter coursechapter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coursechapter
    ADD CONSTRAINT coursechapter_pkey PRIMARY KEY (id);


--
-- Name: courseupdate courseupdate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courseupdate
    ADD CONSTRAINT courseupdate_pkey PRIMARY KEY (id);


--
-- Name: customdomain customdomain_domain_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customdomain
    ADD CONSTRAINT customdomain_domain_key UNIQUE (domain);


--
-- Name: customdomain customdomain_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customdomain
    ADD CONSTRAINT customdomain_pkey PRIMARY KEY (id);


--
-- Name: discussion discussion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion
    ADD CONSTRAINT discussion_pkey PRIMARY KEY (id);


--
-- Name: discussioncomment discussioncomment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncomment
    ADD CONSTRAINT discussioncomment_pkey PRIMARY KEY (id);


--
-- Name: discussioncommentvote discussioncommentvote_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncommentvote
    ADD CONSTRAINT discussioncommentvote_pkey PRIMARY KEY (id);


--
-- Name: discussionreaction discussionreaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionreaction
    ADD CONSTRAINT discussionreaction_pkey PRIMARY KEY (id);


--
-- Name: discussionvote discussionvote_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionvote
    ADD CONSTRAINT discussionvote_pkey PRIMARY KEY (id);


--
-- Name: drip_notification drip_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drip_notification
    ADD CONSTRAINT drip_notification_pkey PRIMARY KEY (id);


--
-- Name: editortemplate editortemplate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editortemplate
    ADD CONSTRAINT editortemplate_pkey PRIMARY KEY (id);


--
-- Name: editorvariable editorvariable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editorvariable
    ADD CONSTRAINT editorvariable_pkey PRIMARY KEY (id);


--
-- Name: email_preference email_preference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_preference
    ADD CONSTRAINT email_preference_pkey PRIMARY KEY (id);


--
-- Name: folder folder_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT folder_pkey PRIMARY KEY (id);


--
-- Name: foldercontent foldercontent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.foldercontent
    ADD CONSTRAINT foldercontent_pkey PRIMARY KEY (id);


--
-- Name: landing_form_submission landing_form_submission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_form_submission
    ADD CONSTRAINT landing_form_submission_pkey PRIMARY KEY (id);


--
-- Name: landing_legacy_backup landing_legacy_backup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_legacy_backup
    ADD CONSTRAINT landing_legacy_backup_pkey PRIMARY KEY (id);


--
-- Name: landing_page landing_page_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page
    ADD CONSTRAINT landing_page_pkey PRIMARY KEY (id);


--
-- Name: landing_page_version landing_page_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_version
    ADD CONSTRAINT landing_page_version_pkey PRIMARY KEY (id);


--
-- Name: landing_saved_section landing_saved_section_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_saved_section
    ADD CONSTRAINT landing_saved_section_pkey PRIMARY KEY (id);


--
-- Name: learner_note learner_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learner_note
    ADD CONSTRAINT learner_note_pkey PRIMARY KEY (id);


--
-- Name: mcp_oauth_client mcp_oauth_client_client_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_client
    ADD CONSTRAINT mcp_oauth_client_client_id_key UNIQUE (client_id);


--
-- Name: mcp_oauth_client mcp_oauth_client_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_client
    ADD CONSTRAINT mcp_oauth_client_pkey PRIMARY KEY (id);


--
-- Name: mcp_oauth_code mcp_oauth_code_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_code
    ADD CONSTRAINT mcp_oauth_code_pkey PRIMARY KEY (code_hash);


--
-- Name: mcp_oauth_grant mcp_oauth_grant_grant_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_grant
    ADD CONSTRAINT mcp_oauth_grant_grant_uuid_key UNIQUE (grant_uuid);


--
-- Name: mcp_oauth_grant mcp_oauth_grant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_grant
    ADD CONSTRAINT mcp_oauth_grant_pkey PRIMARY KEY (id);


--
-- Name: mcp_oauth_token mcp_oauth_token_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_token
    ADD CONSTRAINT mcp_oauth_token_pkey PRIMARY KEY (id);


--
-- Name: mcp_oauth_token mcp_oauth_token_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_token
    ADD CONSTRAINT mcp_oauth_token_token_hash_key UNIQUE (token_hash);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: mediasharetoken mediasharetoken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediasharetoken
    ADD CONSTRAINT mediasharetoken_pkey PRIMARY KEY (id);


--
-- Name: message message_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (id);


--
-- Name: messagereaction messagereaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereaction
    ADD CONSTRAINT messagereaction_pkey PRIMARY KEY (id);


--
-- Name: messagereminder messagereminder_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereminder
    ADD CONSTRAINT messagereminder_pkey PRIMARY KEY (id);


--
-- Name: messagingprofile messagingprofile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagingprofile
    ADD CONSTRAINT messagingprofile_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: notification_preference notification_preference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preference
    ADD CONSTRAINT notification_preference_pkey PRIMARY KEY (id);


--
-- Name: nudge_send nudge_send_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nudge_send
    ADD CONSTRAINT nudge_send_pkey PRIMARY KEY (id);


--
-- Name: org_downgrade org_downgrade_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_downgrade
    ADD CONSTRAINT org_downgrade_pkey PRIMARY KEY (id);


--
-- Name: org_invitation org_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT org_invitation_pkey PRIMARY KEY (id);


--
-- Name: org_invite_code org_invite_code_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite_code
    ADD CONSTRAINT org_invite_code_pkey PRIMARY KEY (id);


--
-- Name: org_member_profile org_member_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_member_profile
    ADD CONSTRAINT org_member_profile_pkey PRIMARY KEY (org_id, user_id);


--
-- Name: org_notification_setting org_notification_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_notification_setting
    ADD CONSTRAINT org_notification_setting_pkey PRIMARY KEY (id);


--
-- Name: org_onboarding org_onboarding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_onboarding
    ADD CONSTRAINT org_onboarding_pkey PRIMARY KEY (id);


--
-- Name: org_trial org_trial_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_trial
    ADD CONSTRAINT org_trial_pkey PRIMARY KEY (org_id);


--
-- Name: organization organization_org_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_org_uuid_key UNIQUE (org_uuid);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organization_plan_history organization_plan_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_plan_history
    ADD CONSTRAINT organization_plan_history_pkey PRIMARY KEY (id);


--
-- Name: organizationconfig organizationconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizationconfig
    ADD CONSTRAINT organizationconfig_pkey PRIMARY KEY (id);


--
-- Name: orgpack orgpack_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgpack
    ADD CONSTRAINT orgpack_pkey PRIMARY KEY (id);


--
-- Name: path path_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.path
    ADD CONSTRAINT path_pkey PRIMARY KEY (id);


--
-- Name: pathcertificate pathcertificate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcertificate
    ADD CONSTRAINT pathcertificate_pkey PRIMARY KEY (id);


--
-- Name: pathcourse pathcourse_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcourse
    ADD CONSTRAINT pathcourse_pkey PRIMARY KEY (id);


--
-- Name: pathenrollment pathenrollment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathenrollment
    ADD CONSTRAINT pathenrollment_pkey PRIMARY KEY (id);


--
-- Name: podcast podcast_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast
    ADD CONSTRAINT podcast_pkey PRIMARY KEY (id);


--
-- Name: podcastepisode podcastepisode_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcastepisode
    ADD CONSTRAINT podcastepisode_pkey PRIMARY KEY (id);


--
-- Name: push_device push_device_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_device
    ADD CONSTRAINT push_device_pkey PRIMARY KEY (id);


--
-- Name: resource_slug_redirect resource_slug_redirect_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_slug_redirect
    ADD CONSTRAINT resource_slug_redirect_pkey PRIMARY KEY (id);


--
-- Name: resourceauthor resourceauthor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resourceauthor
    ADD CONSTRAINT resourceauthor_pkey PRIMARY KEY (id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: superadmin_apitoken superadmin_apitoken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.superadmin_apitoken
    ADD CONSTRAINT superadmin_apitoken_pkey PRIMARY KEY (id);


--
-- Name: trail trail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trail
    ADD CONSTRAINT trail_pkey PRIMARY KEY (id);


--
-- Name: trailrun trailrun_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailrun
    ADD CONSTRAINT trailrun_pkey PRIMARY KEY (id);


--
-- Name: trailstep trailstep_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT trailstep_pkey PRIMARY KEY (id);


--
-- Name: discussioncommentvote unique_comment_user_vote; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncommentvote
    ADD CONSTRAINT unique_comment_user_vote UNIQUE (comment_id, user_id);


--
-- Name: discussionreaction unique_discussion_user_emoji; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionreaction
    ADD CONSTRAINT unique_discussion_user_emoji UNIQUE (discussion_id, user_id, emoji);


--
-- Name: discussionvote unique_discussion_user_vote; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionvote
    ADD CONSTRAINT unique_discussion_user_vote UNIQUE (discussion_id, user_id);


--
-- Name: activity_translation uq_activity_translation_locale; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation
    ADD CONSTRAINT uq_activity_translation_locale UNIQUE (activity_id, locale);


--
-- Name: assignmentaigrade uq_assignmentaigrade_assignment_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentaigrade
    ADD CONSTRAINT uq_assignmentaigrade_assignment_user UNIQUE (assignment_id, user_id);


--
-- Name: assignmenttasksubmission uq_assignmenttasksubmission_user_task; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission
    ADD CONSTRAINT uq_assignmenttasksubmission_user_task UNIQUE (user_id, assignment_task_id);


--
-- Name: assignmentusersubmission uq_assignmentusersubmission_user_assignment; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentusersubmission
    ADD CONSTRAINT uq_assignmentusersubmission_user_assignment UNIQUE (user_id, assignment_id);


--
-- Name: certificateuser uq_certificateuser_user_certification; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificateuser
    ADD CONSTRAINT uq_certificateuser_user_certification UNIQUE (user_id, certification_id);


--
-- Name: chapter_translation uq_chapter_translation_locale; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter_translation
    ADD CONSTRAINT uq_chapter_translation_locale UNIQUE (chapter_id, locale);


--
-- Name: chapteractivity uq_chapteractivity_chapter_activity; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapteractivity
    ADD CONSTRAINT uq_chapteractivity_chapter_activity UNIQUE (chapter_id, activity_id);


--
-- Name: conversationmember uq_conversationmember_conv_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversationmember
    ADD CONSTRAINT uq_conversationmember_conv_user UNIQUE (conversation_id, user_id);


--
-- Name: course_translation uq_course_translation_locale; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_translation
    ADD CONSTRAINT uq_course_translation_locale UNIQUE (course_id, locale);


--
-- Name: drip_notification uq_drip_notification_chapter_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drip_notification
    ADD CONSTRAINT uq_drip_notification_chapter_user UNIQUE (chapter_id, user_id);


--
-- Name: editorvariable uq_editorvariable_org_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editorvariable
    ADD CONSTRAINT uq_editorvariable_org_key UNIQUE (org_id, key);


--
-- Name: email_preference uq_email_preference_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_preference
    ADD CONSTRAINT uq_email_preference_user UNIQUE (user_id);


--
-- Name: foldercontent uq_foldercontent_folder_resource; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.foldercontent
    ADD CONSTRAINT uq_foldercontent_folder_resource UNIQUE (folder_id, resource_uuid);


--
-- Name: landing_legacy_backup uq_landing_legacy_backup_org; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_legacy_backup
    ADD CONSTRAINT uq_landing_legacy_backup_org UNIQUE (org_id);


--
-- Name: landing_page uq_landing_page_org_slug; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page
    ADD CONSTRAINT uq_landing_page_org_slug UNIQUE (org_id, slug);


--
-- Name: messagereaction uq_messagereaction_msg_user_emoji; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereaction
    ADD CONSTRAINT uq_messagereaction_msg_user_emoji UNIQUE (message_id, user_id, emoji);


--
-- Name: messagingprofile uq_messagingprofile_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagingprofile
    ADD CONSTRAINT uq_messagingprofile_user UNIQUE (user_id);


--
-- Name: notification_preference uq_notification_preference_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preference
    ADD CONSTRAINT uq_notification_preference_user UNIQUE (user_id);


--
-- Name: notification uq_notification_user_dedupe; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT uq_notification_user_dedupe UNIQUE (user_id, dedupe_key);


--
-- Name: nudge_send uq_nudge_send_dedupe; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nudge_send
    ADD CONSTRAINT uq_nudge_send_dedupe UNIQUE (dedupe_key);


--
-- Name: org_invitation uq_org_invitation_copy_token_hash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT uq_org_invitation_copy_token_hash UNIQUE (copy_token_hash);


--
-- Name: org_invitation uq_org_invitation_token_hash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT uq_org_invitation_token_hash UNIQUE (token_hash);


--
-- Name: org_notification_setting uq_org_notification_setting_org; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_notification_setting
    ADD CONSTRAINT uq_org_notification_setting_org UNIQUE (org_id);


--
-- Name: pathcertificate uq_pathcertificate_path_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcertificate
    ADD CONSTRAINT uq_pathcertificate_path_user UNIQUE (path_id, user_id);


--
-- Name: pathcourse uq_pathcourse_path_course; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcourse
    ADD CONSTRAINT uq_pathcourse_path_course UNIQUE (path_id, course_id);


--
-- Name: pathenrollment uq_pathenrollment_path_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathenrollment
    ADD CONSTRAINT uq_pathenrollment_path_user UNIQUE (path_id, user_id);


--
-- Name: push_device uq_push_device_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_device
    ADD CONSTRAINT uq_push_device_token UNIQUE (token);


--
-- Name: resource_slug_redirect uq_slug_redirect_org_type_slug; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_slug_redirect
    ADD CONSTRAINT uq_slug_redirect_org_type_slug UNIQUE (org_id, resource_type, slug);


--
-- Name: trailrun uq_trailrun_trail_course_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailrun
    ADD CONSTRAINT uq_trailrun_trail_course_user UNIQUE (trail_id, course_id, user_id);


--
-- Name: trailstep uq_trailstep_run_activity_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT uq_trailstep_run_activity_user UNIQUE (trailrun_id, activity_id, user_id);


--
-- Name: user_activity_day uq_user_activity_org_user_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_day
    ADD CONSTRAINT uq_user_activity_org_user_date UNIQUE (org_id, user_id, activity_date);


--
-- Name: usergroup_manager uq_usergroup_manager; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_manager
    ADD CONSTRAINT uq_usergroup_manager UNIQUE (usergroup_id, user_id);


--
-- Name: usageevent usageevent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usageevent
    ADD CONSTRAINT usageevent_pkey PRIMARY KEY (id);


--
-- Name: used_link_token used_link_token_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.used_link_token
    ADD CONSTRAINT used_link_token_pkey PRIMARY KEY (jti);


--
-- Name: user_activity_day user_activity_day_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_day
    ADD CONSTRAINT user_activity_day_pkey PRIMARY KEY (id);


--
-- Name: user_audit_event user_audit_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_audit_event
    ADD CONSTRAINT user_audit_event_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: usergroup_announcement usergroup_announcement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_announcement
    ADD CONSTRAINT usergroup_announcement_pkey PRIMARY KEY (id);


--
-- Name: usergroup_event usergroup_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_event
    ADD CONSTRAINT usergroup_event_pkey PRIMARY KEY (id);


--
-- Name: usergroup_join_code usergroup_join_code_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_join_code
    ADD CONSTRAINT usergroup_join_code_pkey PRIMARY KEY (id);


--
-- Name: usergroup_manager usergroup_manager_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_manager
    ADD CONSTRAINT usergroup_manager_pkey PRIMARY KEY (id);


--
-- Name: usergroup usergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup
    ADD CONSTRAINT usergroup_pkey PRIMARY KEY (id);


--
-- Name: usergroup_schedule usergroup_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_schedule
    ADD CONSTRAINT usergroup_schedule_pkey PRIMARY KEY (id);


--
-- Name: usergroupresource usergroupresource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupresource
    ADD CONSTRAINT usergroupresource_pkey PRIMARY KEY (id);


--
-- Name: usergroupuser usergroupuser_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupuser
    ADD CONSTRAINT usergroupuser_pkey PRIMARY KEY (id);


--
-- Name: usermfa usermfa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usermfa
    ADD CONSTRAINT usermfa_pkey PRIMARY KEY (id);


--
-- Name: usermfabackupcode usermfabackupcode_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usermfabackupcode
    ADD CONSTRAINT usermfabackupcode_pkey PRIMARY KEY (id);


--
-- Name: userorganization userorganization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userorganization
    ADD CONSTRAINT userorganization_pkey PRIMARY KEY (id);


--
-- Name: webhook_delivery_log webhook_delivery_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_delivery_log
    ADD CONSTRAINT webhook_delivery_log_pkey PRIMARY KEY (id);


--
-- Name: webhook_endpoint webhook_endpoint_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoint
    ADD CONSTRAINT webhook_endpoint_pkey PRIMARY KEY (id);


--
-- Name: ix_activity_activity_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_activity_uuid ON public.activity USING btree (activity_uuid);


--
-- Name: ix_activity_comment_comment_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_activity_comment_comment_uuid ON public.activity_comment USING btree (comment_uuid);


--
-- Name: ix_activity_comment_thread_activity_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_comment_thread_activity_status ON public.activity_comment_thread USING btree (activity_id, status);


--
-- Name: ix_activity_comment_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_comment_thread_id ON public.activity_comment USING btree (thread_id);


--
-- Name: ix_activity_comment_thread_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_comment_thread_org_id ON public.activity_comment_thread USING btree (org_id);


--
-- Name: ix_activity_comment_thread_thread_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_activity_comment_thread_thread_uuid ON public.activity_comment_thread USING btree (thread_uuid);


--
-- Name: ix_activity_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_course_id ON public.activity USING btree (course_id);


--
-- Name: ix_activity_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_org_id ON public.activity USING btree (org_id);


--
-- Name: ix_activity_translation_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_translation_activity_id ON public.activity_translation USING btree (activity_id);


--
-- Name: ix_activity_translation_collab_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_translation_collab_org_id ON public.activity_translation_collab USING btree (org_id);


--
-- Name: ix_activity_translation_course_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_translation_course_locale ON public.activity_translation USING btree (course_id, locale);


--
-- Name: ix_activity_translation_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_translation_org_id ON public.activity_translation USING btree (org_id);


--
-- Name: ix_activitycollabstate_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activitycollabstate_org_id ON public.activitycollabstate USING btree (org_id);


--
-- Name: ix_agent_agent_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_agent_uuid ON public.agent USING btree (agent_uuid);


--
-- Name: ix_agent_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_org_id ON public.agent USING btree (org_id);


--
-- Name: ix_agent_owner_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_owner_user_id ON public.agent USING btree (owner_user_id);


--
-- Name: ix_ai_usage_event_charge_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_ai_usage_event_charge_key ON public.ai_usage_event USING btree (charge_key);


--
-- Name: ix_ai_usage_event_feature_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ai_usage_event_feature_created ON public.ai_usage_event USING btree (feature, created_at);


--
-- Name: ix_ai_usage_event_org_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ai_usage_event_org_created ON public.ai_usage_event USING btree (org_id, created_at);


--
-- Name: ix_aigeneration_ai_generation_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_aigeneration_ai_generation_uuid ON public.aigeneration USING btree (ai_generation_uuid);


--
-- Name: ix_aigeneration_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_aigeneration_kind ON public.aigeneration USING btree (kind);


--
-- Name: ix_aigeneration_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_aigeneration_org_id ON public.aigeneration USING btree (org_id);


--
-- Name: ix_aigeneration_session_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_aigeneration_session_uuid ON public.aigeneration USING btree (session_uuid);


--
-- Name: ix_aigeneration_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_aigeneration_user_id ON public.aigeneration USING btree (user_id);


--
-- Name: ix_apitoken_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_apitoken_org_id ON public.apitoken USING btree (org_id);


--
-- Name: ix_apitoken_token_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_apitoken_token_prefix ON public.apitoken USING btree (token_prefix);


--
-- Name: ix_assignment_assignment_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_assignment_assignment_uuid ON public.assignment USING btree (assignment_uuid);


--
-- Name: ix_assignment_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_assignment_course_id ON public.assignment USING btree (course_id);


--
-- Name: ix_assignment_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_assignment_org_id ON public.assignment USING btree (org_id);


--
-- Name: ix_assignmentaigrade_assignment_ai_grade_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_assignmentaigrade_assignment_ai_grade_uuid ON public.assignmentaigrade USING btree (assignment_ai_grade_uuid);


--
-- Name: ix_assignmentaigrade_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_assignmentaigrade_assignment_id ON public.assignmentaigrade USING btree (assignment_id);


--
-- Name: ix_certificateuser_user_certification_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_certificateuser_user_certification_uuid ON public.certificateuser USING btree (user_certification_uuid);


--
-- Name: ix_chapter_chapter_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapter_chapter_uuid ON public.chapter USING btree (chapter_uuid);


--
-- Name: ix_chapter_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapter_course_id ON public.chapter USING btree (course_id);


--
-- Name: ix_chapter_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapter_org_id ON public.chapter USING btree (org_id);


--
-- Name: ix_chapter_translation_chapter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapter_translation_chapter_id ON public.chapter_translation USING btree (chapter_id);


--
-- Name: ix_chapter_translation_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapter_translation_course_id ON public.chapter_translation USING btree (course_id);


--
-- Name: ix_chapter_translation_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapter_translation_org_id ON public.chapter_translation USING btree (org_id);


--
-- Name: ix_chapteractivity_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapteractivity_activity_id ON public.chapteractivity USING btree (activity_id);


--
-- Name: ix_chapteractivity_chapter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapteractivity_chapter_id ON public.chapteractivity USING btree (chapter_id);


--
-- Name: ix_chapteractivity_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapteractivity_course_id ON public.chapteractivity USING btree (course_id);


--
-- Name: ix_chapteractivity_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_chapteractivity_org_id ON public.chapteractivity USING btree (org_id);


--
-- Name: ix_code_submission_activity_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_code_submission_activity_uuid ON public.code_submission USING btree (activity_uuid);


--
-- Name: ix_code_submission_block_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_code_submission_block_id ON public.code_submission USING btree (block_id);


--
-- Name: ix_code_submission_submission_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_code_submission_submission_uuid ON public.code_submission USING btree (submission_uuid);


--
-- Name: ix_code_submission_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_code_submission_user_id ON public.code_submission USING btree (user_id);


--
-- Name: ix_community_community_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_community_community_uuid ON public.community USING btree (community_uuid);


--
-- Name: ix_community_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_community_course_id ON public.community USING btree (course_id);


--
-- Name: ix_community_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_community_org_id ON public.community USING btree (org_id);


--
-- Name: ix_conversation_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversation_agent_id ON public.conversation USING btree (agent_id);


--
-- Name: ix_conversation_conversation_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversation_conversation_uuid ON public.conversation USING btree (conversation_uuid);


--
-- Name: ix_conversation_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversation_course_id ON public.conversation USING btree (course_id);


--
-- Name: ix_conversation_dm_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversation_dm_key ON public.conversation USING btree (dm_key);


--
-- Name: ix_conversation_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversation_org_id ON public.conversation USING btree (org_id);


--
-- Name: ix_conversation_org_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversation_org_kind ON public.conversation USING btree (org_id, kind);


--
-- Name: ix_conversationmember_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversationmember_conversation_id ON public.conversationmember USING btree (conversation_id);


--
-- Name: ix_conversationmember_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversationmember_user_id ON public.conversationmember USING btree (user_id);


--
-- Name: ix_course_course_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_course_uuid ON public.course USING btree (course_uuid);


--
-- Name: ix_course_embedding_course_activity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_embedding_course_activity ON public.course_embedding USING btree (course_id, activity_id);


--
-- Name: ix_course_embedding_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_embedding_course_id ON public.course_embedding USING btree (course_id);


--
-- Name: ix_course_embedding_embedding_hnsw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_embedding_embedding_hnsw ON public.course_embedding USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: ix_course_embedding_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_embedding_org_id ON public.course_embedding USING btree (org_id);


--
-- Name: ix_course_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_org_id ON public.course USING btree (org_id);


--
-- Name: ix_course_org_public_published_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_org_public_published_created ON public.course USING btree (org_id, public, published, creation_date);


--
-- Name: ix_course_translation_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_translation_course_id ON public.course_translation USING btree (course_id);


--
-- Name: ix_course_translation_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_translation_org_id ON public.course_translation USING btree (org_id);


--
-- Name: ix_course_translation_org_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_course_translation_org_slug ON public.course_translation USING btree (org_id, slug);


--
-- Name: ix_coursechapter_chapter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_coursechapter_chapter_id ON public.coursechapter USING btree (chapter_id);


--
-- Name: ix_coursechapter_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_coursechapter_course_id ON public.coursechapter USING btree (course_id);


--
-- Name: ix_courseupdate_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_courseupdate_course_id ON public.courseupdate USING btree (course_id);


--
-- Name: ix_courseupdate_courseupdate_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_courseupdate_courseupdate_uuid ON public.courseupdate USING btree (courseupdate_uuid);


--
-- Name: ix_courseupdate_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_courseupdate_org_id ON public.courseupdate USING btree (org_id);


--
-- Name: ix_customdomain_domain_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_customdomain_domain_uuid ON public.customdomain USING btree (domain_uuid);


--
-- Name: ix_customdomain_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_customdomain_org_id ON public.customdomain USING btree (org_id);


--
-- Name: ix_discussion_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_discussion_community_id ON public.discussion USING btree (community_id);


--
-- Name: ix_discussion_discussion_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_discussion_discussion_uuid ON public.discussion USING btree (discussion_uuid);


--
-- Name: ix_discussioncomment_comment_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_discussioncomment_comment_uuid ON public.discussioncomment USING btree (comment_uuid);


--
-- Name: ix_discussioncomment_discussion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_discussioncomment_discussion_id ON public.discussioncomment USING btree (discussion_id);


--
-- Name: ix_drip_notification_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_drip_notification_course_id ON public.drip_notification USING btree (course_id);


--
-- Name: ix_drip_notification_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_drip_notification_user_id ON public.drip_notification USING btree (user_id);


--
-- Name: ix_editortemplate_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_editortemplate_org_id ON public.editortemplate USING btree (org_id);


--
-- Name: ix_editortemplate_template_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_editortemplate_template_uuid ON public.editortemplate USING btree (template_uuid);


--
-- Name: ix_editorvariable_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_editorvariable_org_id ON public.editorvariable USING btree (org_id);


--
-- Name: ix_editorvariable_variable_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_editorvariable_variable_uuid ON public.editorvariable USING btree (variable_uuid);


--
-- Name: ix_folder_folder_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_folder_folder_uuid ON public.folder USING btree (folder_uuid);


--
-- Name: ix_folder_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_folder_org_id ON public.folder USING btree (org_id);


--
-- Name: ix_folder_parent_folder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_folder_parent_folder_id ON public.folder USING btree (parent_folder_id);


--
-- Name: ix_foldercontent_folder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_foldercontent_folder_id ON public.foldercontent USING btree (folder_id);


--
-- Name: ix_foldercontent_resource_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_foldercontent_resource_uuid ON public.foldercontent USING btree (resource_uuid);


--
-- Name: ix_landing_form_submission_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_landing_form_submission_org_id ON public.landing_form_submission USING btree (org_id);


--
-- Name: ix_landing_page_page_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_landing_page_page_uuid ON public.landing_page USING btree (page_uuid);


--
-- Name: ix_landing_page_version_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_landing_page_version_page_id ON public.landing_page_version USING btree (page_id);


--
-- Name: ix_landing_saved_section_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_landing_saved_section_org_id ON public.landing_saved_section USING btree (org_id);


--
-- Name: ix_learner_note_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_learner_note_activity_id ON public.learner_note USING btree (activity_id);


--
-- Name: ix_learner_note_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_learner_note_course_id ON public.learner_note USING btree (course_id);


--
-- Name: ix_learner_note_note_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_learner_note_note_uuid ON public.learner_note USING btree (note_uuid);


--
-- Name: ix_learner_note_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_learner_note_org_id ON public.learner_note USING btree (org_id);


--
-- Name: ix_learner_note_user_activity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_learner_note_user_activity ON public.learner_note USING btree (user_id, activity_id);


--
-- Name: ix_learner_note_user_org_course; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_learner_note_user_org_course ON public.learner_note USING btree (user_id, org_id, course_id);


--
-- Name: ix_mcp_oauth_code_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mcp_oauth_code_expires_at ON public.mcp_oauth_code USING btree (expires_at);


--
-- Name: ix_mcp_oauth_grant_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mcp_oauth_grant_org_id ON public.mcp_oauth_grant USING btree (org_id);


--
-- Name: ix_mcp_oauth_grant_user_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mcp_oauth_grant_user_org ON public.mcp_oauth_grant USING btree (user_id, org_id);


--
-- Name: ix_mcp_oauth_token_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mcp_oauth_token_expires_at ON public.mcp_oauth_token USING btree (expires_at);


--
-- Name: ix_mcp_oauth_token_grant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mcp_oauth_token_grant_id ON public.mcp_oauth_token USING btree (grant_id);


--
-- Name: ix_media_media_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_media_media_uuid ON public.media USING btree (media_uuid);


--
-- Name: ix_media_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_media_org_id ON public.media USING btree (org_id);


--
-- Name: ix_mediasharetoken_media_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mediasharetoken_media_uuid ON public.mediasharetoken USING btree (media_uuid);


--
-- Name: ix_mediasharetoken_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mediasharetoken_org_id ON public.mediasharetoken USING btree (org_id);


--
-- Name: ix_mediasharetoken_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mediasharetoken_token ON public.mediasharetoken USING btree (token);


--
-- Name: ix_message_conversation_id_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_message_conversation_id_id ON public.message USING btree (conversation_id, id);


--
-- Name: ix_message_message_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_message_message_uuid ON public.message USING btree (message_uuid);


--
-- Name: ix_message_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_message_org_id ON public.message USING btree (org_id);


--
-- Name: ix_message_sender_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_message_sender_user_id ON public.message USING btree (sender_user_id);


--
-- Name: ix_messagereaction_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messagereaction_message_id ON public.messagereaction USING btree (message_id);


--
-- Name: ix_messagereminder_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messagereminder_due ON public.messagereminder USING btree (sent_at, cancelled_at, due_at);


--
-- Name: ix_messagereminder_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messagereminder_org_id ON public.messagereminder USING btree (org_id);


--
-- Name: ix_messagereminder_reminder_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messagereminder_reminder_uuid ON public.messagereminder USING btree (reminder_uuid);


--
-- Name: ix_messagereminder_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messagereminder_user_id ON public.messagereminder USING btree (user_id);


--
-- Name: ix_notification_notification_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notification_notification_uuid ON public.notification USING btree (notification_uuid);


--
-- Name: ix_notification_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notification_read_at ON public.notification USING btree (read_at);


--
-- Name: ix_notification_user_audience_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notification_user_audience_id ON public.notification USING btree (user_id, audience, id);


--
-- Name: ix_notification_user_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notification_user_group ON public.notification USING btree (user_id, group_key);


--
-- Name: ix_notification_user_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notification_user_org_id ON public.notification USING btree (user_id, org_id, id);


--
-- Name: ix_nudge_send_nudge_sent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nudge_send_nudge_sent ON public.nudge_send USING btree (nudge_id, sent_at);


--
-- Name: ix_nudge_send_org_nudge; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nudge_send_org_nudge ON public.nudge_send USING btree (org_id, nudge_id);


--
-- Name: ix_nudge_send_unchecked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nudge_send_unchecked ON public.nudge_send USING btree (delivery_checked, sent_at);


--
-- Name: ix_nudge_send_user_sent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nudge_send_user_sent ON public.nudge_send USING btree (user_id, sent_at);


--
-- Name: ix_org_downgrade_org_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_downgrade_org_created ON public.org_downgrade USING btree (org_id, created_at);


--
-- Name: ix_org_invitation_email_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_invitation_email_status ON public.org_invitation USING btree (email, status);


--
-- Name: ix_org_invitation_invitation_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_org_invitation_invitation_uuid ON public.org_invitation USING btree (invitation_uuid);


--
-- Name: ix_org_invitation_org_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_invitation_org_status ON public.org_invitation USING btree (org_id, status);


--
-- Name: ix_org_invite_code_code_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_org_invite_code_code_uuid ON public.org_invite_code USING btree (code_uuid);


--
-- Name: ix_org_invite_code_org_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_org_invite_code_org_code ON public.org_invite_code USING btree (org_id, code);


--
-- Name: ix_org_member_profile_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_member_profile_department ON public.org_member_profile USING btree (org_id, department);


--
-- Name: ix_org_member_profile_external; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_member_profile_external ON public.org_member_profile USING btree (org_id, external_id);


--
-- Name: ix_org_member_profile_manager; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_member_profile_manager ON public.org_member_profile USING btree (org_id, manager_user_id);


--
-- Name: ix_org_onboarding_goal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_onboarding_goal ON public.org_onboarding USING btree (goal);


--
-- Name: ix_org_onboarding_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_org_onboarding_org_id ON public.org_onboarding USING btree (org_id);


--
-- Name: ix_org_plan_history_org_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_plan_history_org_from ON public.organization_plan_history USING btree (org_id, effective_from);


--
-- Name: ix_org_trial_status_ends; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_org_trial_status_ends ON public.org_trial USING btree (status, ends_at);


--
-- Name: ix_organization_explore; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_organization_explore ON public.organization USING btree (explore);


--
-- Name: ix_organization_is_demo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_organization_is_demo ON public.organization USING btree (is_demo);


--
-- Name: ix_organization_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_organization_slug ON public.organization USING btree (slug);


--
-- Name: ix_organizationconfig_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_organizationconfig_org_id ON public.organizationconfig USING btree (org_id);


--
-- Name: ix_orgpack_org_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_orgpack_org_status ON public.orgpack USING btree (org_id, status);


--
-- Name: ix_orgpack_platform_sub; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_orgpack_platform_sub ON public.orgpack USING btree (platform_subscription_id);


--
-- Name: ix_path_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_path_org_id ON public.path USING btree (org_id);


--
-- Name: ix_path_path_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_path_path_uuid ON public.path USING btree (path_uuid);


--
-- Name: ix_pathcertificate_certificate_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_pathcertificate_certificate_uuid ON public.pathcertificate USING btree (certificate_uuid);


--
-- Name: ix_pathcertificate_path_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pathcertificate_path_id ON public.pathcertificate USING btree (path_id);


--
-- Name: ix_pathcertificate_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pathcertificate_user_id ON public.pathcertificate USING btree (user_id);


--
-- Name: ix_pathcourse_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pathcourse_course_id ON public.pathcourse USING btree (course_id);


--
-- Name: ix_pathcourse_path_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pathcourse_path_id ON public.pathcourse USING btree (path_id);


--
-- Name: ix_pathenrollment_path_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pathenrollment_path_id ON public.pathenrollment USING btree (path_id);


--
-- Name: ix_pathenrollment_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pathenrollment_user_id ON public.pathenrollment USING btree (user_id);


--
-- Name: ix_push_device_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_push_device_user_id ON public.push_device USING btree (user_id);


--
-- Name: ix_resourceauthor_resource_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_resourceauthor_resource_uuid ON public.resourceauthor USING btree (resource_uuid);


--
-- Name: ix_resourceauthor_resource_uuid_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_resourceauthor_resource_uuid_user_id ON public.resourceauthor USING btree (resource_uuid, user_id);


--
-- Name: ix_resourceauthor_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_resourceauthor_user_id ON public.resourceauthor USING btree (user_id);


--
-- Name: ix_role_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_role_org_id ON public.role USING btree (org_id);


--
-- Name: ix_role_org_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_role_org_type ON public.role USING btree (org_id, role_type);


--
-- Name: ix_slug_redirect_resource_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_slug_redirect_resource_uuid ON public.resource_slug_redirect USING btree (resource_uuid);


--
-- Name: ix_superadmin_apitoken_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_superadmin_apitoken_created_by ON public.superadmin_apitoken USING btree (created_by_user_id);


--
-- Name: ix_superadmin_apitoken_token_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_superadmin_apitoken_token_prefix ON public.superadmin_apitoken USING btree (token_prefix);


--
-- Name: ix_trail_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trail_org_id ON public.trail USING btree (org_id);


--
-- Name: ix_trail_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trail_user_id ON public.trail USING btree (user_id);


--
-- Name: ix_trail_user_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trail_user_org ON public.trail USING btree (user_id, org_id);


--
-- Name: ix_trailrun_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trailrun_course_id ON public.trailrun USING btree (course_id);


--
-- Name: ix_trailrun_trail_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trailrun_trail_id ON public.trailrun USING btree (trail_id);


--
-- Name: ix_trailrun_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trailrun_user_id ON public.trailrun USING btree (user_id);


--
-- Name: ix_trailstep_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trailstep_course_id ON public.trailstep USING btree (course_id);


--
-- Name: ix_trailstep_trailrun_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trailstep_trailrun_id ON public.trailstep USING btree (trailrun_id);


--
-- Name: ix_trailstep_trailrun_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trailstep_trailrun_user ON public.trailstep USING btree (trailrun_id, user_id);


--
-- Name: ix_trailstep_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trailstep_user_id ON public.trailstep USING btree (user_id);


--
-- Name: ix_usage_event_org_feature_ts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usage_event_org_feature_ts ON public.usageevent USING btree (org_id, feature, "timestamp");


--
-- Name: ix_used_link_token_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_used_link_token_expires_at ON public.used_link_token USING btree (expires_at);


--
-- Name: ix_user_activity_org_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_activity_org_date ON public.user_activity_day USING btree (org_id, activity_date);


--
-- Name: ix_user_activity_org_user_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_activity_org_user_date ON public.user_activity_day USING btree (org_id, user_id, activity_date);


--
-- Name: ix_user_audit_event_org_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_audit_event_org_user_created ON public.user_audit_event USING btree (org_id, user_id, created_at);


--
-- Name: ix_user_audit_event_target_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_audit_event_target_uuid ON public.user_audit_event USING btree (target_uuid);


--
-- Name: ix_user_audit_event_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_audit_event_user_id ON public.user_audit_event USING btree (user_id);


--
-- Name: ix_user_audit_event_user_type_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_audit_event_user_type_created ON public.user_audit_event USING btree (user_id, event_type, created_at);


--
-- Name: ix_user_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_email ON public."user" USING btree (email);


--
-- Name: ix_user_mfa_backup_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_mfa_backup_user ON public.usermfabackupcode USING btree (user_id);


--
-- Name: ix_user_mfa_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_user_mfa_user ON public.usermfa USING btree (user_id);


--
-- Name: ix_user_user_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_user_uuid ON public."user" USING btree (user_uuid);


--
-- Name: ix_usergroup_announcement_announcement_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_announcement_announcement_uuid ON public.usergroup_announcement USING btree (announcement_uuid);


--
-- Name: ix_usergroup_announcement_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_announcement_org_id ON public.usergroup_announcement USING btree (org_id);


--
-- Name: ix_usergroup_announcement_usergroup_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_announcement_usergroup_id ON public.usergroup_announcement USING btree (usergroup_id);


--
-- Name: ix_usergroup_event_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_event_group_id ON public.usergroup_event USING btree (usergroup_id, id);


--
-- Name: ix_usergroup_event_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_event_org_id ON public.usergroup_event USING btree (org_id);


--
-- Name: ix_usergroup_join_code_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_usergroup_join_code_code ON public.usergroup_join_code USING btree (code);


--
-- Name: ix_usergroup_join_code_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_join_code_org_id ON public.usergroup_join_code USING btree (org_id);


--
-- Name: ix_usergroup_join_code_usergroup_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_join_code_usergroup_id ON public.usergroup_join_code USING btree (usergroup_id);


--
-- Name: ix_usergroup_manager_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_manager_org_id ON public.usergroup_manager USING btree (org_id);


--
-- Name: ix_usergroup_manager_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_manager_user_id ON public.usergroup_manager USING btree (user_id);


--
-- Name: ix_usergroup_manager_usergroup_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_manager_usergroup_id ON public.usergroup_manager USING btree (usergroup_id);


--
-- Name: ix_usergroup_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_parent_id ON public.usergroup USING btree (parent_id);


--
-- Name: ix_usergroup_schedule_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_schedule_due ON public.usergroup_schedule USING btree (status, starts_at);


--
-- Name: ix_usergroup_schedule_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_schedule_org_id ON public.usergroup_schedule USING btree (org_id);


--
-- Name: ix_usergroup_schedule_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_schedule_user_id ON public.usergroup_schedule USING btree (user_id);


--
-- Name: ix_usergroup_schedule_usergroup_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroup_schedule_usergroup_id ON public.usergroup_schedule USING btree (usergroup_id);


--
-- Name: ix_usergroupuser_group_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usergroupuser_group_user ON public.usergroupuser USING btree (usergroup_id, user_id);


--
-- Name: ix_usermfa_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_usermfa_user_id ON public.usermfa USING btree (user_id);


--
-- Name: ix_usermfabackupcode_code_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usermfabackupcode_code_hash ON public.usermfabackupcode USING btree (code_hash);


--
-- Name: ix_usermfabackupcode_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usermfabackupcode_user_id ON public.usermfabackupcode USING btree (user_id);


--
-- Name: ix_userorg_org_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_userorg_org_role ON public.userorganization USING btree (org_id, role_id);


--
-- Name: ix_userorg_user_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_userorg_user_org ON public.userorganization USING btree (user_id, org_id);


--
-- Name: ix_userorganization_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_userorganization_org_id ON public.userorganization USING btree (org_id);


--
-- Name: ix_userorganization_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_userorganization_role_id ON public.userorganization USING btree (role_id);


--
-- Name: ix_userorganization_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_userorganization_user_id ON public.userorganization USING btree (user_id);


--
-- Name: ix_webhook_delivery_log_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_webhook_delivery_log_created_at ON public.webhook_delivery_log USING btree (created_at);


--
-- Name: ix_webhook_delivery_log_webhook_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_webhook_delivery_log_webhook_id ON public.webhook_delivery_log USING btree (webhook_id);


--
-- Name: ix_webhook_endpoint_org_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_webhook_endpoint_org_active ON public.webhook_endpoint USING btree (org_id, is_active);


--
-- Name: ix_webhook_endpoint_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_webhook_endpoint_org_id ON public.webhook_endpoint USING btree (org_id);


--
-- Name: ix_webhook_endpoint_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_webhook_endpoint_source ON public.webhook_endpoint USING btree (org_id, source);


--
-- Name: ix_webhook_endpoint_webhook_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_webhook_endpoint_webhook_uuid ON public.webhook_endpoint USING btree (webhook_uuid);


--
-- Name: uq_org_invitation_pending_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_org_invitation_pending_email ON public.org_invitation USING btree (org_id, email) WHERE ((status)::text = 'pending'::text);


--
-- Name: uq_userorganization_user_org; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_userorganization_user_org ON public.userorganization USING btree (user_id, org_id);


--
-- Name: activity_comment activity_comment_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment
    ADD CONSTRAINT activity_comment_author_id_fkey FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: activity_comment_thread activity_comment_thread_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment_thread
    ADD CONSTRAINT activity_comment_thread_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity_comment_thread activity_comment_thread_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment_thread
    ADD CONSTRAINT activity_comment_thread_created_by_fkey FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: activity_comment activity_comment_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment
    ADD CONSTRAINT activity_comment_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.activity_comment_thread(id) ON DELETE CASCADE;


--
-- Name: activity_comment_thread activity_comment_thread_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment_thread
    ADD CONSTRAINT activity_comment_thread_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: activity_comment_thread activity_comment_thread_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_comment_thread
    ADD CONSTRAINT activity_comment_thread_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: activity activity_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: activity activity_last_modified_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_last_modified_by_id_fkey FOREIGN KEY (last_modified_by_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: activity activity_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: activity_translation activity_translation_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation
    ADD CONSTRAINT activity_translation_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity_translation_collab activity_translation_collab_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation_collab
    ADD CONSTRAINT activity_translation_collab_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: activity_translation_collab activity_translation_collab_translation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation_collab
    ADD CONSTRAINT activity_translation_collab_translation_id_fkey FOREIGN KEY (translation_id) REFERENCES public.activity_translation(id) ON DELETE CASCADE;


--
-- Name: activity_translation activity_translation_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation
    ADD CONSTRAINT activity_translation_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: activity_translation activity_translation_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation
    ADD CONSTRAINT activity_translation_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: activity_translation activity_translation_updated_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_translation
    ADD CONSTRAINT activity_translation_updated_by_id_fkey FOREIGN KEY (updated_by_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: activitycollabstate activitycollabstate_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activitycollabstate
    ADD CONSTRAINT activitycollabstate_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activitycollabstate activitycollabstate_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activitycollabstate
    ADD CONSTRAINT activitycollabstate_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: activityversion activityversion_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activityversion
    ADD CONSTRAINT activityversion_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activityversion activityversion_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activityversion
    ADD CONSTRAINT activityversion_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: activityversion activityversion_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activityversion
    ADD CONSTRAINT activityversion_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: agent agent_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: agent agent_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: ai_usage_event ai_usage_event_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_usage_event
    ADD CONSTRAINT ai_usage_event_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: aigeneration aigeneration_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aigeneration
    ADD CONSTRAINT aigeneration_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: aigeneration aigeneration_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aigeneration
    ADD CONSTRAINT aigeneration_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignment(id) ON DELETE CASCADE;


--
-- Name: aigeneration aigeneration_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aigeneration
    ADD CONSTRAINT aigeneration_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: aigeneration aigeneration_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aigeneration
    ADD CONSTRAINT aigeneration_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: aigeneration aigeneration_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aigeneration
    ADD CONSTRAINT aigeneration_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: apitoken apitoken_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apitoken
    ADD CONSTRAINT apitoken_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: apitoken apitoken_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apitoken
    ADD CONSTRAINT apitoken_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: assignment assignment_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: assignment assignment_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: assignment assignment_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: assignment assignment_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: assignmentaigrade assignmentaigrade_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentaigrade
    ADD CONSTRAINT assignmentaigrade_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignment(id) ON DELETE CASCADE;


--
-- Name: assignmentaigrade assignmentaigrade_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentaigrade
    ADD CONSTRAINT assignmentaigrade_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: assignmentaigrade assignmentaigrade_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentaigrade
    ADD CONSTRAINT assignmentaigrade_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: assignmenttask assignmenttask_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttask
    ADD CONSTRAINT assignmenttask_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: assignmenttask assignmenttask_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttask
    ADD CONSTRAINT assignmenttask_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignment(id) ON DELETE CASCADE;


--
-- Name: assignmenttask assignmenttask_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttask
    ADD CONSTRAINT assignmenttask_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: assignmenttask assignmenttask_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttask
    ADD CONSTRAINT assignmenttask_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: assignmenttask assignmenttask_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttask
    ADD CONSTRAINT assignmenttask_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: assignmenttasksubmission assignmenttasksubmission_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission
    ADD CONSTRAINT assignmenttasksubmission_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: assignmenttasksubmission assignmenttasksubmission_assignment_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission
    ADD CONSTRAINT assignmenttasksubmission_assignment_task_id_fkey FOREIGN KEY (assignment_task_id) REFERENCES public.assignmenttask(id) ON DELETE CASCADE;


--
-- Name: assignmenttasksubmission assignmenttasksubmission_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission
    ADD CONSTRAINT assignmenttasksubmission_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: assignmenttasksubmission assignmenttasksubmission_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission
    ADD CONSTRAINT assignmenttasksubmission_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: assignmenttasksubmission assignmenttasksubmission_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmenttasksubmission
    ADD CONSTRAINT assignmenttasksubmission_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: assignmentusersubmission assignmentusersubmission_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentusersubmission
    ADD CONSTRAINT assignmentusersubmission_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignment(id) ON DELETE CASCADE;


--
-- Name: assignmentusersubmission assignmentusersubmission_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignmentusersubmission
    ADD CONSTRAINT assignmentusersubmission_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: block block_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block
    ADD CONSTRAINT block_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: block block_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block
    ADD CONSTRAINT block_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: block block_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block
    ADD CONSTRAINT block_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: block block_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block
    ADD CONSTRAINT block_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: certificateuser certificateuser_certification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificateuser
    ADD CONSTRAINT certificateuser_certification_id_fkey FOREIGN KEY (certification_id) REFERENCES public.certifications(id) ON DELETE CASCADE;


--
-- Name: certificateuser certificateuser_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificateuser
    ADD CONSTRAINT certificateuser_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: certifications certifications_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT certifications_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: chapter chapter_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter
    ADD CONSTRAINT chapter_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: chapter chapter_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter
    ADD CONSTRAINT chapter_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: chapter_translation chapter_translation_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter_translation
    ADD CONSTRAINT chapter_translation_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: chapter_translation chapter_translation_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter_translation
    ADD CONSTRAINT chapter_translation_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: chapter_translation chapter_translation_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapter_translation
    ADD CONSTRAINT chapter_translation_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: chapteractivity chapteractivity_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapteractivity
    ADD CONSTRAINT chapteractivity_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: chapteractivity chapteractivity_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapteractivity
    ADD CONSTRAINT chapteractivity_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: chapteractivity chapteractivity_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapteractivity
    ADD CONSTRAINT chapteractivity_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: chapteractivity chapteractivity_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapteractivity
    ADD CONSTRAINT chapteractivity_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: community community_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community
    ADD CONSTRAINT community_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE SET NULL;


--
-- Name: community community_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community
    ADD CONSTRAINT community_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: conversation conversation_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: conversation conversation_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: conversation conversation_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_created_by_fkey FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: conversation conversation_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: conversationmember conversationmember_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversationmember
    ADD CONSTRAINT conversationmember_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversation(id) ON DELETE CASCADE;


--
-- Name: conversationmember conversationmember_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversationmember
    ADD CONSTRAINT conversationmember_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: course_embedding course_embedding_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_embedding
    ADD CONSTRAINT course_embedding_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: course_embedding course_embedding_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_embedding
    ADD CONSTRAINT course_embedding_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: course_embedding course_embedding_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_embedding
    ADD CONSTRAINT course_embedding_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: course course_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: course_translation course_translation_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_translation
    ADD CONSTRAINT course_translation_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: course_translation course_translation_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_translation
    ADD CONSTRAINT course_translation_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: course_translation course_translation_updated_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_translation
    ADD CONSTRAINT course_translation_updated_by_id_fkey FOREIGN KEY (updated_by_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: coursechapter coursechapter_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coursechapter
    ADD CONSTRAINT coursechapter_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: coursechapter coursechapter_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coursechapter
    ADD CONSTRAINT coursechapter_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: coursechapter coursechapter_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coursechapter
    ADD CONSTRAINT coursechapter_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: courseupdate courseupdate_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courseupdate
    ADD CONSTRAINT courseupdate_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: courseupdate courseupdate_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courseupdate
    ADD CONSTRAINT courseupdate_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: customdomain customdomain_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customdomain
    ADD CONSTRAINT customdomain_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: discussion discussion_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion
    ADD CONSTRAINT discussion_author_id_fkey FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: discussion discussion_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion
    ADD CONSTRAINT discussion_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.community(id) ON DELETE CASCADE;


--
-- Name: discussion discussion_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion
    ADD CONSTRAINT discussion_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: discussioncomment discussioncomment_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncomment
    ADD CONSTRAINT discussioncomment_author_id_fkey FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: discussioncomment discussioncomment_discussion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncomment
    ADD CONSTRAINT discussioncomment_discussion_id_fkey FOREIGN KEY (discussion_id) REFERENCES public.discussion(id) ON DELETE CASCADE;


--
-- Name: discussioncommentvote discussioncommentvote_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncommentvote
    ADD CONSTRAINT discussioncommentvote_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.discussioncomment(id) ON DELETE CASCADE;


--
-- Name: discussioncommentvote discussioncommentvote_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussioncommentvote
    ADD CONSTRAINT discussioncommentvote_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: discussionreaction discussionreaction_discussion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionreaction
    ADD CONSTRAINT discussionreaction_discussion_id_fkey FOREIGN KEY (discussion_id) REFERENCES public.discussion(id) ON DELETE CASCADE;


--
-- Name: discussionreaction discussionreaction_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionreaction
    ADD CONSTRAINT discussionreaction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: discussionvote discussionvote_discussion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionvote
    ADD CONSTRAINT discussionvote_discussion_id_fkey FOREIGN KEY (discussion_id) REFERENCES public.discussion(id) ON DELETE CASCADE;


--
-- Name: discussionvote discussionvote_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussionvote
    ADD CONSTRAINT discussionvote_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: drip_notification drip_notification_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drip_notification
    ADD CONSTRAINT drip_notification_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapter(id) ON DELETE CASCADE;


--
-- Name: drip_notification drip_notification_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drip_notification
    ADD CONSTRAINT drip_notification_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: drip_notification drip_notification_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drip_notification
    ADD CONSTRAINT drip_notification_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: drip_notification drip_notification_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drip_notification
    ADD CONSTRAINT drip_notification_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: editortemplate editortemplate_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editortemplate
    ADD CONSTRAINT editortemplate_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: editortemplate editortemplate_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editortemplate
    ADD CONSTRAINT editortemplate_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: editorvariable editorvariable_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editorvariable
    ADD CONSTRAINT editorvariable_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: editorvariable editorvariable_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editorvariable
    ADD CONSTRAINT editorvariable_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: email_preference email_preference_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_preference
    ADD CONSTRAINT email_preference_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: folder folder_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT folder_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: folder folder_parent_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT folder_parent_folder_id_fkey FOREIGN KEY (parent_folder_id) REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: foldercontent foldercontent_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.foldercontent
    ADD CONSTRAINT foldercontent_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: foldercontent foldercontent_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.foldercontent
    ADD CONSTRAINT foldercontent_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: landing_form_submission landing_form_submission_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_form_submission
    ADD CONSTRAINT landing_form_submission_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: landing_form_submission landing_form_submission_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_form_submission
    ADD CONSTRAINT landing_form_submission_page_id_fkey FOREIGN KEY (page_id) REFERENCES public.landing_page(id) ON DELETE CASCADE;


--
-- Name: landing_legacy_backup landing_legacy_backup_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_legacy_backup
    ADD CONSTRAINT landing_legacy_backup_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: landing_page landing_page_draft_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page
    ADD CONSTRAINT landing_page_draft_updated_by_fkey FOREIGN KEY (draft_updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: landing_page landing_page_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page
    ADD CONSTRAINT landing_page_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: landing_page landing_page_published_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page
    ADD CONSTRAINT landing_page_published_by_fkey FOREIGN KEY (published_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: landing_page_version landing_page_version_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_version
    ADD CONSTRAINT landing_page_version_created_by_fkey FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: landing_page_version landing_page_version_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_version
    ADD CONSTRAINT landing_page_version_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: landing_page_version landing_page_version_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_version
    ADD CONSTRAINT landing_page_version_page_id_fkey FOREIGN KEY (page_id) REFERENCES public.landing_page(id) ON DELETE CASCADE;


--
-- Name: landing_saved_section landing_saved_section_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_saved_section
    ADD CONSTRAINT landing_saved_section_created_by_fkey FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: landing_saved_section landing_saved_section_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_saved_section
    ADD CONSTRAINT landing_saved_section_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: learner_note learner_note_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learner_note
    ADD CONSTRAINT learner_note_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: learner_note learner_note_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learner_note
    ADD CONSTRAINT learner_note_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: learner_note learner_note_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learner_note
    ADD CONSTRAINT learner_note_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: learner_note learner_note_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learner_note
    ADD CONSTRAINT learner_note_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: mcp_oauth_code mcp_oauth_code_grant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_code
    ADD CONSTRAINT mcp_oauth_code_grant_id_fkey FOREIGN KEY (grant_id) REFERENCES public.mcp_oauth_grant(id) ON DELETE CASCADE;


--
-- Name: mcp_oauth_grant mcp_oauth_grant_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_grant
    ADD CONSTRAINT mcp_oauth_grant_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.mcp_oauth_client(client_id) ON DELETE CASCADE;


--
-- Name: mcp_oauth_grant mcp_oauth_grant_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_grant
    ADD CONSTRAINT mcp_oauth_grant_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: mcp_oauth_grant mcp_oauth_grant_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_grant
    ADD CONSTRAINT mcp_oauth_grant_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: mcp_oauth_token mcp_oauth_token_grant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_token
    ADD CONSTRAINT mcp_oauth_token_grant_id_fkey FOREIGN KEY (grant_id) REFERENCES public.mcp_oauth_grant(id) ON DELETE CASCADE;


--
-- Name: media media_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: mediasharetoken mediasharetoken_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mediasharetoken
    ADD CONSTRAINT mediasharetoken_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: message message_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversation(id) ON DELETE CASCADE;


--
-- Name: message message_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: message message_reply_to_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES public.message(id) ON DELETE SET NULL;


--
-- Name: message message_sender_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_sender_agent_id_fkey FOREIGN KEY (sender_agent_id) REFERENCES public.agent(id) ON DELETE SET NULL;


--
-- Name: message message_sender_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_sender_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: messagereaction messagereaction_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereaction
    ADD CONSTRAINT messagereaction_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.message(id) ON DELETE CASCADE;


--
-- Name: messagereaction messagereaction_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereaction
    ADD CONSTRAINT messagereaction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: messagereminder messagereminder_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereminder
    ADD CONSTRAINT messagereminder_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE SET NULL;


--
-- Name: messagereminder messagereminder_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereminder
    ADD CONSTRAINT messagereminder_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversation(id) ON DELETE CASCADE;


--
-- Name: messagereminder messagereminder_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereminder
    ADD CONSTRAINT messagereminder_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: messagereminder messagereminder_source_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereminder
    ADD CONSTRAINT messagereminder_source_message_id_fkey FOREIGN KEY (source_message_id) REFERENCES public.message(id) ON DELETE SET NULL;


--
-- Name: messagereminder messagereminder_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagereminder
    ADD CONSTRAINT messagereminder_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: messagingprofile messagingprofile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messagingprofile
    ADD CONSTRAINT messagingprofile_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: notification notification_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: notification notification_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: notification_preference notification_preference_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preference
    ADD CONSTRAINT notification_preference_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: notification notification_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: nudge_send nudge_send_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nudge_send
    ADD CONSTRAINT nudge_send_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: nudge_send nudge_send_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nudge_send
    ADD CONSTRAINT nudge_send_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_downgrade org_downgrade_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_downgrade
    ADD CONSTRAINT org_downgrade_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_invitation org_invitation_accepted_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT org_invitation_accepted_user_id_fkey FOREIGN KEY (accepted_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_invitation org_invitation_invited_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT org_invitation_invited_by_user_id_fkey FOREIGN KEY (invited_by_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_invitation org_invitation_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT org_invitation_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_invitation org_invitation_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT org_invitation_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(id) ON DELETE SET NULL;


--
-- Name: org_invite_code org_invite_code_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite_code
    ADD CONSTRAINT org_invite_code_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_invite_code org_invite_code_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite_code
    ADD CONSTRAINT org_invite_code_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_invite_code org_invite_code_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite_code
    ADD CONSTRAINT org_invite_code_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(id) ON DELETE SET NULL;


--
-- Name: org_member_profile org_member_profile_manager_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_member_profile
    ADD CONSTRAINT org_member_profile_manager_user_id_fkey FOREIGN KEY (manager_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_member_profile org_member_profile_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_member_profile
    ADD CONSTRAINT org_member_profile_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_member_profile org_member_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_member_profile
    ADD CONSTRAINT org_member_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_notification_setting org_notification_setting_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_notification_setting
    ADD CONSTRAINT org_notification_setting_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_onboarding org_onboarding_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_onboarding
    ADD CONSTRAINT org_onboarding_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_trial org_trial_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_trial
    ADD CONSTRAINT org_trial_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: organization_plan_history organization_plan_history_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_plan_history
    ADD CONSTRAINT organization_plan_history_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: organizationconfig organizationconfig_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizationconfig
    ADD CONSTRAINT organizationconfig_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: orgpack orgpack_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orgpack
    ADD CONSTRAINT orgpack_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: path path_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.path
    ADD CONSTRAINT path_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: pathcertificate pathcertificate_path_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcertificate
    ADD CONSTRAINT pathcertificate_path_id_fkey FOREIGN KEY (path_id) REFERENCES public.path(id) ON DELETE CASCADE;


--
-- Name: pathcertificate pathcertificate_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcertificate
    ADD CONSTRAINT pathcertificate_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: pathcourse pathcourse_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcourse
    ADD CONSTRAINT pathcourse_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: pathcourse pathcourse_path_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathcourse
    ADD CONSTRAINT pathcourse_path_id_fkey FOREIGN KEY (path_id) REFERENCES public.path(id) ON DELETE CASCADE;


--
-- Name: pathenrollment pathenrollment_path_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathenrollment
    ADD CONSTRAINT pathenrollment_path_id_fkey FOREIGN KEY (path_id) REFERENCES public.path(id) ON DELETE CASCADE;


--
-- Name: pathenrollment pathenrollment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pathenrollment
    ADD CONSTRAINT pathenrollment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: podcast podcast_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast
    ADD CONSTRAINT podcast_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: podcastepisode podcastepisode_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcastepisode
    ADD CONSTRAINT podcastepisode_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: podcastepisode podcastepisode_podcast_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcastepisode
    ADD CONSTRAINT podcastepisode_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES public.podcast(id) ON DELETE CASCADE;


--
-- Name: push_device push_device_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_device
    ADD CONSTRAINT push_device_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: push_device push_device_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_device
    ADD CONSTRAINT push_device_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: resource_slug_redirect resource_slug_redirect_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_slug_redirect
    ADD CONSTRAINT resource_slug_redirect_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: resourceauthor resourceauthor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resourceauthor
    ADD CONSTRAINT resourceauthor_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: role role_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: superadmin_apitoken superadmin_apitoken_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.superadmin_apitoken
    ADD CONSTRAINT superadmin_apitoken_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: trail trail_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trail
    ADD CONSTRAINT trail_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: trail trail_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trail
    ADD CONSTRAINT trail_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: trailrun trailrun_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailrun
    ADD CONSTRAINT trailrun_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: trailrun trailrun_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailrun
    ADD CONSTRAINT trailrun_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: trailrun trailrun_trail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailrun
    ADD CONSTRAINT trailrun_trail_id_fkey FOREIGN KEY (trail_id) REFERENCES public.trail(id) ON DELETE CASCADE;


--
-- Name: trailrun trailrun_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailrun
    ADD CONSTRAINT trailrun_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: trailstep trailstep_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT trailstep_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: trailstep trailstep_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT trailstep_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: trailstep trailstep_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT trailstep_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: trailstep trailstep_trail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT trailstep_trail_id_fkey FOREIGN KEY (trail_id) REFERENCES public.trail(id) ON DELETE CASCADE;


--
-- Name: trailstep trailstep_trailrun_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT trailstep_trailrun_id_fkey FOREIGN KEY (trailrun_id) REFERENCES public.trailrun(id) ON DELETE CASCADE;


--
-- Name: trailstep trailstep_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trailstep
    ADD CONSTRAINT trailstep_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: usageevent usageevent_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usageevent
    ADD CONSTRAINT usageevent_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: user_activity_day user_activity_day_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_day
    ADD CONSTRAINT user_activity_day_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: user_activity_day user_activity_day_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_day
    ADD CONSTRAINT user_activity_day_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_audit_event user_audit_event_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_audit_event
    ADD CONSTRAINT user_audit_event_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: user_audit_event user_audit_event_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_audit_event
    ADD CONSTRAINT user_audit_event_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: usergroup_announcement usergroup_announcement_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_announcement
    ADD CONSTRAINT usergroup_announcement_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroup_announcement usergroup_announcement_usergroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_announcement
    ADD CONSTRAINT usergroup_announcement_usergroup_id_fkey FOREIGN KEY (usergroup_id) REFERENCES public.usergroup(id) ON DELETE CASCADE;


--
-- Name: usergroup_event usergroup_event_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_event
    ADD CONSTRAINT usergroup_event_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroup_event usergroup_event_usergroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_event
    ADD CONSTRAINT usergroup_event_usergroup_id_fkey FOREIGN KEY (usergroup_id) REFERENCES public.usergroup(id) ON DELETE CASCADE;


--
-- Name: usergroup_join_code usergroup_join_code_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_join_code
    ADD CONSTRAINT usergroup_join_code_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroup_join_code usergroup_join_code_usergroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_join_code
    ADD CONSTRAINT usergroup_join_code_usergroup_id_fkey FOREIGN KEY (usergroup_id) REFERENCES public.usergroup(id) ON DELETE CASCADE;


--
-- Name: usergroup_manager usergroup_manager_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_manager
    ADD CONSTRAINT usergroup_manager_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroup_manager usergroup_manager_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_manager
    ADD CONSTRAINT usergroup_manager_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: usergroup_manager usergroup_manager_usergroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_manager
    ADD CONSTRAINT usergroup_manager_usergroup_id_fkey FOREIGN KEY (usergroup_id) REFERENCES public.usergroup(id) ON DELETE CASCADE;


--
-- Name: usergroup usergroup_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup
    ADD CONSTRAINT usergroup_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroup usergroup_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup
    ADD CONSTRAINT usergroup_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.usergroup(id) ON DELETE SET NULL;


--
-- Name: usergroup_schedule usergroup_schedule_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_schedule
    ADD CONSTRAINT usergroup_schedule_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroup_schedule usergroup_schedule_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_schedule
    ADD CONSTRAINT usergroup_schedule_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: usergroup_schedule usergroup_schedule_usergroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_schedule
    ADD CONSTRAINT usergroup_schedule_usergroup_id_fkey FOREIGN KEY (usergroup_id) REFERENCES public.usergroup(id) ON DELETE CASCADE;


--
-- Name: usergroupresource usergroupresource_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupresource
    ADD CONSTRAINT usergroupresource_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroupresource usergroupresource_usergroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupresource
    ADD CONSTRAINT usergroupresource_usergroup_id_fkey FOREIGN KEY (usergroup_id) REFERENCES public.usergroup(id) ON DELETE CASCADE;


--
-- Name: usergroupuser usergroupuser_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupuser
    ADD CONSTRAINT usergroupuser_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: usergroupuser usergroupuser_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupuser
    ADD CONSTRAINT usergroupuser_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: usergroupuser usergroupuser_usergroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroupuser
    ADD CONSTRAINT usergroupuser_usergroup_id_fkey FOREIGN KEY (usergroup_id) REFERENCES public.usergroup(id) ON DELETE CASCADE;


--
-- Name: usermfa usermfa_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usermfa
    ADD CONSTRAINT usermfa_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: usermfabackupcode usermfabackupcode_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usermfabackupcode
    ADD CONSTRAINT usermfabackupcode_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: userorganization userorganization_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userorganization
    ADD CONSTRAINT userorganization_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: userorganization userorganization_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userorganization
    ADD CONSTRAINT userorganization_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(id);


--
-- Name: userorganization userorganization_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userorganization
    ADD CONSTRAINT userorganization_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: webhook_delivery_log webhook_delivery_log_webhook_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_delivery_log
    ADD CONSTRAINT webhook_delivery_log_webhook_id_fkey FOREIGN KEY (webhook_id) REFERENCES public.webhook_endpoint(id) ON DELETE CASCADE;


--
-- Name: webhook_endpoint webhook_endpoint_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoint
    ADD CONSTRAINT webhook_endpoint_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: webhook_endpoint webhook_endpoint_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoint
    ADD CONSTRAINT webhook_endpoint_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 1xbKTkor8DegkHthD6dokucKz0qtcZoreGJJEaf4O3BBH2Z9khTvEPocZMC4wxY

