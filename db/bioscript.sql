--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: celery_tasksetmeta; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE celery_tasksetmeta (
    id integer NOT NULL,
    taskset_id character varying(255),
    result bytea,
    date_done timestamp without time zone
);


ALTER TABLE public.celery_tasksetmeta OWNER TO rvmuser;

--
-- Name: connections; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE connections (
    id integer NOT NULL,
    user_id integer NOT NULL,
    ip text,
    user_agent text,
    url text,
    referer text,
    method text,
    body text,
    content_length text,
    content_type text,
    query_string text,
    date_done timestamp without time zone
);


ALTER TABLE public.connections OWNER TO rvmuser;

--
-- Name: connections_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE connections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.connections_id_seq OWNER TO rvmuser;

--
-- Name: connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE connections_id_seq OWNED BY connections.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE jobs (
    id integer NOT NULL,
    request_id integer NOT NULL,
    task_id integer
);


ALTER TABLE public.jobs OWNER TO rvmuser;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jobs_id_seq OWNER TO rvmuser;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- Name: plugin_requests; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE plugin_requests (
    id integer NOT NULL,
    plugin_id integer NOT NULL,
    user_id integer NOT NULL,
    parameters character varying,
    created_at timestamp without time zone,
    error text,
    status_id integer
);


ALTER TABLE public.plugin_requests OWNER TO rvmuser;

--
-- Name: plugin_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE plugin_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.plugin_requests_id_seq OWNER TO rvmuser;

--
-- Name: plugin_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE plugin_requests_id_seq OWNED BY plugin_requests.id;


--
-- Name: plugins; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE plugins (
    id integer NOT NULL,
    key text,
    deprecated boolean,
    info character varying
);


ALTER TABLE public.plugins OWNER TO rvmuser;

--
-- Name: plugins_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE plugins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.plugins_id_seq OWNER TO rvmuser;

--
-- Name: plugins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE plugins_id_seq OWNED BY plugins.id;


--
-- Name: result_types; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE result_types (
    id integer NOT NULL,
    result_type character varying(40) NOT NULL,
    CONSTRAINT result_types_result_type_check CHECK (((result_type)::text <> ''::text))
);


ALTER TABLE public.result_types OWNER TO rvmuser;

--
-- Name: result_types_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE result_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.result_types_id_seq OWNER TO rvmuser;

--
-- Name: result_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE result_types_id_seq OWNED BY result_types.id;


--
-- Name: results; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE results (
    id integer NOT NULL,
    job_id integer NOT NULL,
    result text,
    is_file boolean,
    path text,
    fname text,
    result_type_id integer
);


ALTER TABLE public.results OWNER TO rvmuser;

--
-- Name: results_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.results_id_seq OWNER TO rvmuser;

--
-- Name: results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE results_id_seq OWNED BY results.id;


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE statuses (
    id integer NOT NULL,
    status character varying(40) NOT NULL,
    CONSTRAINT statuses_status_check CHECK (((status)::text <> ''::text))
);


ALTER TABLE public.statuses OWNER TO rvmuser;

--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.statuses_id_seq OWNER TO rvmuser;

--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE statuses_id_seq OWNED BY statuses.id;


--
-- Name: task_id_sequence; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE task_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.task_id_sequence OWNER TO rvmuser;

--
-- Name: tasks; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE tasks (
    id integer NOT NULL,
    result bytea,
    created_at timestamp without time zone,
    traceback text,
    status_id integer
);


ALTER TABLE public.tasks OWNER TO rvmuser;

--
-- Name: taskset_id_sequence; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE taskset_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.taskset_id_sequence OWNER TO rvmuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: rvmuser; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(255),
    email character varying(255),
    created_at timestamp without time zone,
    key character varying(255),
    is_service boolean,
    remote character varying(255)
);


ALTER TABLE public.users OWNER TO rvmuser;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: rvmuser
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO rvmuser;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rvmuser
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY connections ALTER COLUMN id SET DEFAULT nextval('connections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY plugin_requests ALTER COLUMN id SET DEFAULT nextval('plugin_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY plugins ALTER COLUMN id SET DEFAULT nextval('plugins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY result_types ALTER COLUMN id SET DEFAULT nextval('result_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY results ALTER COLUMN id SET DEFAULT nextval('results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY statuses ALTER COLUMN id SET DEFAULT nextval('statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: celery_tasksetmeta_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY celery_tasksetmeta
    ADD CONSTRAINT celery_tasksetmeta_pkey PRIMARY KEY (id);


--
-- Name: celery_tasksetmeta_taskset_id_key; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY celery_tasksetmeta
    ADD CONSTRAINT celery_tasksetmeta_taskset_id_key UNIQUE (taskset_id);


--
-- Name: connections_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: email_key; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT email_key UNIQUE (email);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: plugin_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY plugin_requests
    ADD CONSTRAINT plugin_requests_pkey PRIMARY KEY (id);


--
-- Name: plugins_key_key; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY plugins
    ADD CONSTRAINT plugins_key_key UNIQUE (key);


--
-- Name: plugins_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY plugins
    ADD CONSTRAINT plugins_pkey PRIMARY KEY (id);


--
-- Name: result_types_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY result_types
    ADD CONSTRAINT result_types_pkey PRIMARY KEY (id);


--
-- Name: results_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: users_key_key; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_key_key UNIQUE (key);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_remote_key; Type: CONSTRAINT; Schema: public; Owner: rvmuser; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_remote_key UNIQUE (remote);


--
-- Name: jl_connection_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY connections
    ADD CONSTRAINT jl_connection_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: jl_job_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jl_job_request_id_fkey FOREIGN KEY (request_id) REFERENCES plugin_requests(id) ON DELETE CASCADE;


--
-- Name: jl_plugin_request_plugin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY plugin_requests
    ADD CONSTRAINT jl_plugin_request_plugin_id_fkey FOREIGN KEY (plugin_id) REFERENCES plugins(id) ON DELETE CASCADE;


--
-- Name: jl_plugin_request_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY plugin_requests
    ADD CONSTRAINT jl_plugin_request_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: jl_result_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY results
    ADD CONSTRAINT jl_result_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;


--
-- Name: jobs_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_task_id_fkey FOREIGN KEY (task_id) REFERENCES tasks(id);


--
-- Name: plugin_requests_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY plugin_requests
    ADD CONSTRAINT plugin_requests_status_id_fkey FOREIGN KEY (status_id) REFERENCES statuses(id);


--
-- Name: results_result_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY results
    ADD CONSTRAINT results_result_type_id_fkey FOREIGN KEY (result_type_id) REFERENCES result_types(id);


--
-- Name: tasks_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rvmuser
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_status_id_fkey FOREIGN KEY (status_id) REFERENCES statuses(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

