--rename tables according to ruby naming convention;
alter table "User" rename to users;
alter table "jl_connection" rename to connections;
alter table "jl_plugin_request" rename to plugin_requests;
alter table "jl_job" rename to jobs;
alter table "jl_plugin" rename to plugins ;
alter table "jl_result" rename to results;
alter table "celery_taskmeta" rename to tasks;

--rename sequences??;
alter sequence "User_id_seq" rename to "users_id_seq";
alter sequence "jl_connection_id_seq" rename to connections_id_seq;
alter sequence "jl_plugin_request_id_seq" rename to plugin_requests_id_seq;
alter sequence "jl_job_id_seq" rename to jobs_id_seq;
alter sequence "jl_plugin_id_seq" rename to plugins_id_seq;
alter sequence "jl_result_id_seq" rename to results_id_seq;
--alter sequence "task_id_sequence" rename to tasks_id_seq;


--rename indices;
alter index "User_pkey" rename to users_pkey;
alter index "jl_connection_pkey" rename to connections_pkey;
alter index "jl_plugin_request_pkey" rename to plugin_requests_pkey;
alter index "jl_job_pkey" rename to jobs_pkey;
alter index "jl_plugin_pkey" rename to plugins_pkey;
alter index "jl_result_pkey" rename to results_pkey;
alter index "celery_taskmeta_pkey" rename to tasks_pkey;

--not sure about next keys;
alter index "jl_plugin_generated_id_key" rename to plugins_key_key;
alter index "User__email_key" rename to email_key;
alter index "User_key_key" rename to users_key_key;
alter index "User_remote_key" rename to users_remote_key;
alter index "celery_taskmeta_task_id_key" rename to tasks_key_key;
---------------------------------------------------------------------------------------------------------------;
--rename some columns;
alter table users rename _email to email;
alter table users rename _created to created_at;
alter table plugin_requests rename date_done to created_at;
alter table plugins rename generated_id to key;
alter table tasks rename date_done to created_at;
alter table tasks rename task_id to key; 


alter table jobs rename task_id to task_key;
alter table jobs add column task_id int references tasks (id);
update jobs set task_id = (select id from tasks where jobs.task_key = tasks.key);
alter table jobs drop column task_key;
alter table tasks drop column key;
--alter table jobs add foreign key (task_id) references tasks (task_id);
---------------------------------------------------------------------------------------------------------------;

--create new tables result_types and statuses;
--fill them with data from corresponding tables:;
--plugin_requests.status, tasks.status, results._type ;
--add new columns to that tables and fill with corresponding ids;
--delete text columns from that tables;
---------------------------------------------------------------------------------------------------------------;
create table statuses (
	id serial not null primary key, --integer PRIMARY KEY DEFAULT nextval('serial'),
	status varchar(40) NOT NULL CHECK (status <> '')
);

insert into statuses (status)
values 
	('started'),
	('pending'),
	('stopped'),
	('success'),
	('failure');

--not good to change column type as text is not convertible;
--alter table plugin_requests rename status to status_id;
alter table plugin_requests add column status_id integer;
alter table plugin_requests add foreign key (status_id) references statuses;
--before rename statuses;
update plugin_requests set status = 'pending' where status = 'PENDING';
update plugin_requests set status = 'failure' where status = 'FAILED';

update plugin_requests
	set status_id = (select statuses.id from statuses where plugin_requests.status = statuses.status);

alter table plugin_requests drop column status;
---------------------------------------------------------------------------------------------------------------

--tasks.status_id same as plugin_requests.status_id
alter table tasks add column status_id integer;
alter table tasks add foreign key (status_id) references statuses;
--before rename statuses
update tasks set status = 'started' where status = 'STARTED';
update tasks set status = 'failure' where status = 'FAILURE';
update tasks set status = 'success' where status = 'SUCCESS';

update tasks
	set status_id = (select statuses.id from statuses where tasks.status = statuses.status);
alter table tasks drop column status;
--------------------------------------------------------------------------------------------------------------
create table result_types (
	id serial not null primary key, --integer PRIMARY KEY DEFAULT nextval('serial'),
	result_type varchar(40) NOT NULL CHECK (result_type <> '')
);

insert into result_types (result_type)
	select distinct _type from results where _type is not null;
--track txt file pdf png

alter table results add column result_type_id integer;
alter table results add foreign key (result_type_id) references result_types;
update results
	set result_type_id = (select result_types.id from result_types where _type = result_types.result_type);

alter table results drop column _type;

