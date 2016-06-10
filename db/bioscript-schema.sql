
CREATE TABLE plugins (
    id serial,
    key text,
    name text,
    info_path text,
    filename text,
    info text,
    created_at timestamp,
    updated_at timestamp,
    primary key (id)
);
