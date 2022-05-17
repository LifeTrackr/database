CREATE DOMAIN email AS citext
  CHECK ( value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' );



create table if not exists "User"
(
  user_id         serial
    constraint "User_pk"
      primary key,
  username        email                not null
    unique,
  hashed_password varchar(64)          not null,
  is_active       boolean default true not null
);

create table if not exists "Event_Logs"
(
  id           serial
    constraint "Event_Logs_pk"
      primary key,
  event_id     serial,
  user_id      serial
    constraint "Event_Logs_fk1"
      references "User",
  completed_at timestamp(1) with time zone not null
);

create table if not exists companion_types
(
  id        serial
    primary key,
  companion text
);
INSERT INTO companion_types (companion) VALUES
    ('dog'), ('cat'), ('reptile'), ('plant'), ('bird');

create table if not exists "Companion"
(
  companion      serial
    constraint "Companion_pk"
      primary key,
  name           varchar(10)  not null
    unique,
  companion_type integer
    references companion_types,
  notes          varchar(255) not null,
  image          varchar(255)
    unique,
  user_id        serial
    constraint "Companion_fk0"
      references "User"
      on delete cascade
);

create table if not exists "Event"
(
  event_id     serial
    constraint "Event_pk"
      primary key,
  name         varchar(10)           not null,
  qr_code      integer               not null,
  notes        varchar(255)          not null,
  priority     varchar(1)            not null,
  frequency    interval(1)           not null,
  last_trigger timestamp(1) with time zone,
  next_trigger timestamp(1) with time zone,
  action       varchar(10)           not null,
  companion_id serial
    constraint "Event_fk1"
      references "Companion"
      on delete cascade,
  user_id      serial
    constraint "Event_fk0"
      references "User"
      on delete cascade,
  update       boolean default false not null
);

create table if not exists "QR_Range"
(
  id             serial
    primary key,
  assigned_range integer not null,
  user_id        serial
    constraint "QR_Range_fk0"
      references "User"
      on delete cascade
);

create table if not exists "QR_Codes"
(
  id       serial
    primary key,
  value    integer not null,
  qr_id    serial
    constraint "QR_Codes_fk0"
      references "QR_Range"
      on delete cascade,
  event_id serial
    constraint "QR_Codes_fk1"
      references "Event"
      on delete cascade
);

create function update_next_trigger() returns trigger
  language plpgsql
as
$$
BEGIN
	IF NEW.update != FALSE THEN
	    UPDATE "Event" set next_trigger = frequency + now(), last_trigger = now(), update = false
	        where update = True;
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
