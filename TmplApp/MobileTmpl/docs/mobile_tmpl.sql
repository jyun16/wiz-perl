CREATE TABLE admin (
    id                      INTEGER UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    userid                  VARCHAR(32)         UNIQUE,
    email                   VARCHAR(255),
    password                VARCHAR(86),
    delete_flag             BOOL                DEFAULT 0,
    created_time            DATETIME            NOT NULL,
    last_modified           TIMESTAMP
) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
CREATE INDEX admin_userid_password ON admin (userid, password);

CREATE TABLE member (
    id                      INTEGER UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    userid                  VARCHAR(32)         UNIQUE,
    email                   VARCHAR(255),
    password                VARCHAR(86),
    delete_flag             BOOL                DEFAULT 0,
    created_time            DATETIME            NOT NULL,
    last_modified           TIMESTAMP
) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
CREATE INDEX member_userid_password ON member (userid, password);

CREATE TABLE all_form (
    id                      INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    member_id               INTEGER UNSIGNED,
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
    datetime1               DATETIME,
    created_time            DATETIME        NOT NULL,
    last_modified           TIMESTAMP
) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE token (
    id                      INTEGER UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
    member_id               INTEGER UNSIGNED,
    token                   VARCHAR(32)        UNIQUE,
    type                    TINYINT,
    data                    TEXT,
    delete_flag             BOOL               DEFAULT 0,
    created_time            DATETIME,
    last_modified           TIMESTAMP
) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE session (
    id                      VARCHAR(72) PRIMARY KEY,
    session_data            TEXT,
    expires                 INTEGER
) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
