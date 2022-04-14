CREATE EXTENSION if not exists citext;
CREATE DOMAIN email AS citext
  CHECK ( value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' );
create table if not exists "User"
(
  user_id         serial,
  username        email                not null,
  hashed_password varchar(64)          not null,
  is_active       boolean default true not null,
  constraint "User_pk"
    primary key (user_id),
  unique (username)
);

CREATE TABLE companion_types (
    id SERIAL PRIMARY KEY NOT NULL,
    companion TEXT
);
INSERT INTO companion_types (companion) VALUES
    ('dog'), ('cat'), ('reptile'), ('plant'), ('bird');

create table if not exists "Companion"
(
  companion      serial,
  "name"         varchar(10)  not null UNIQUE,
  companion_type INTEGER REFERENCES companion_types (id),
  notes          varchar(255) not null,
  image          varchar(255) UNIQUE,
  user_id        serial,
  constraint "Companion_pk"
    primary key (companion),
  constraint "Companion_fk0"
    foreign key (user_id) references "User"
      on delete cascade
);

create table if not exists "Event"
(
  event_id       serial,
  "name"           varchar(10)           not null,
  qr_code        integer               not null,
  notes          varchar(255)          not null,
  priority       varchar(1)            not null,
  frequency      interval(1)           not null,
  last_trigger   timestamp(1) with time zone,
  next_trigger   timestamp(1) with time zone,
  action         varchar(10)           not null,
  companion_id   serial               ,
  user_id        serial                not null,

  companion_name varchar(10)           not null,
  companion_type varchar(10)           not null,
  image          varchar(255)          not null,
  update         boolean default false not null,
  constraint "Event_pk"
    primary key (event_id),
  constraint "Event_fk0"
    foreign key (user_id) references "User"(user_id)
      on delete cascade,
  constraint "Event_fk1"
    foreign key (companion_id) references "Companion"("companion")
      on delete cascade,
  constraint "Event_fk2"
    foreign key (companion_name) references "Companion"("name"),
  constraint "Event_fk3" foreign key (image) references "Companion"(image)
    on delete cascade
);
create function update_next_trigger() returns trigger
    language plpgsql
as
$$
BEGIN
	IF NEW.frequency != OLD.frequency or NEW.update != FALSE THEN
	    UPDATE "Event" set next_trigger = frequency + now(), last_trigger = now(), update = false
	        where true;
	END if;
	RETURN NEW;
END;
$$;

create function event_completed_log() returns trigger
    language plpgsql
as
$$
BEGIN
	IF NEW.update != FALSE THEN
	    INSERT INTO "Event_Logs"("event_id", "user_id", "completed_at")
           VALUES (NEW.event_id, NEW.user_id, now());
	END if;
	RETURN NEW;
END;
$$;
create trigger update_triggers
  after update
  on "Event"
  for each row
execute procedure update_next_trigger();

create trigger create_trigger
  after insert
  on "Event"
  for each row
execute procedure update_next_trigger();

create trigger event_completed_log
  before update
  on "Event"
  for each row
execute procedure event_completed_log();

create table if not exists "Event_Logs"
(
  id           serial,
  event_id     serial,
  user_id      serial,
  completed_at timestamp(1) with time zone not null,
  constraint "Event_Logs_pk"
    primary key (id),
  constraint "Event_Logs_fk1"
    foreign key (user_id) references "User"
);


