-- TRIGGER TO UPDATE last_modified
CREATE LANGUAGE 'plpgsql';
CREATE FUNCTION func_update_last_modified() RETURNS TRIGGER AS '
BEGIN
    NEW.last_modified := ''now'';
    return NEW;
END;
' LANGUAGE 'plpgsql' VOLATILE;

CREATE TABLE admin (
    id                      SERIAL              PRIMARY KEY,
    userid                  VARCHAR(32)         UNIQUE,
    email                   VARCHAR(255),
    password                VARCHAR(86),
    delete_flag             BOOL                DEFAULT FALSE,
    created_time            TIMESTAMP           DEFAULT 'now',
    last_modified           TIMESTAMP           DEFAULT 'now'
);
CREATE TRIGGER trg_update_last_modifled_admin BEFORE UPDATE ON admin FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified();
CREATE INDEX admin_userid_password ON admin (userid, password);

CREATE TABLE member (
    id                      SERIAL              PRIMARY KEY,
    userid                  VARCHAR(32)         UNIQUE,
    email                   VARCHAR(255),
    password                VARCHAR(86),
    delete_flag             BOOL                DEFAULT FALSE,
    created_time            TIMESTAMP           DEFAULT 'now',
    last_modified           TIMESTAMP           DEFAULT 'now'
);
CREATE TRIGGER trg_update_last_modifled_member BEFORE UPDATE ON member FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified();
CREATE INDEX member_userid_password ON member (userid, password);

CREATE TABLE all_form (
    id                      SERIAL              PRIMARY KEY,
    member_id               INTEGER,
    text                    TEXT,
    password                VARCHAR(128),
    textarea                TEXT,
    select1                 INTEGER,
    multi_select            VARCHAR(255),
    radio1                  INTEGER,
    radio2                  INTEGER,
    checkbox                VARCHAR(255),
    email                   VARCHAR(255),
    first_name              VARCHAR(64),
    last_name               VARCHAR(64),
    date1                   DATE,
    date2                   DATE,
    time1                   TIME,
    datetime1               TIMESTAMP,
    delete_flag             BOOL                DEFAULT FALSE,
    created_time            TIMESTAMP           DEFAULT 'now',
    last_modified           TIMESTAMP           DEFAULT 'now'
);
CREATE TRIGGER trg_update_last_modifled_all_form BEFORE UPDATE ON all_form FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified();

CREATE TABLE token (
    id                      SERIAL              PRIMARY KEY,
    member_id               INTEGER,
    token                   VARCHAR(32)         UNIQUE,
    type                    SMALLINT,
    data                    TEXT,
    delete_flag             BOOL                DEFAULT FALSE,
    created_time            TIMESTAMP           DEFAULT 'now',
    last_modified           TIMESTAMP           DEFAULT 'now'
);
CREATE TRIGGER trg_update_last_modifled_token BEFORE UPDATE ON token FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified();

CREATE TABLE sample_job (
    id                      SERIAL              PRIMARY KEY,
    args                    TEXT,
    status                  SMALLINT            DEFAULT 0,
    try_count               INTEGER             DEFAULT 0,
    result                  TEXT,
    error_message           VARCHAR(2048),
    created_time            TIMESTAMP           DEFAULT 'now',
    last_modified           TIMESTAMP           DEFAULT 'now'
);
CREATE TRIGGER trg_update_last_modifled_sample_job BEFORE UPDATE ON sample_job FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified();

CREATE TABLE session (
    id                      SERIAL              PRIMARY KEY,
    session_data            TEXT,
    expires                 INTEGER
);
CREATE TRIGGER trg_update_last_modifled_session BEFORE UPDATE ON session FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified();
