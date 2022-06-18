CREATE EXTENSION citext;

CREATE DOMAIN email AS citext CHECK (value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');

CREATE TABLE IF NOT EXISTS "User" (
    user_id serial CONSTRAINT "User_pk" PRIMARY KEY,
    username email NOT NULL UNIQUE,
    first_name varchar(15) NOT NULL,
    last_name varchar(25),
    hashed_password varchar(64) NOT NULL,
    is_active boolean DEFAULT TRUE NOT NULL
);

CREATE TABLE IF NOT EXISTS "Event_Logs" (
    id serial CONSTRAINT "Event_Logs_pk" PRIMARY KEY,
    event_id serial,
    user_id serial CONSTRAINT "Event_Logs_fk1" REFERENCES "User",
    completed_at timestamp(1) WITH time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS companion_types (
    id serial PRIMARY KEY,
    companion text
);

INSERT INTO companion_types (companion)
    VALUES ('dog'), ('cat'), ('reptile'), ('plant'), ('bird');

CREATE TABLE IF NOT EXISTS "Companion" (
    companion serial CONSTRAINT "Companion_pk" PRIMARY KEY,
    name varchar(10) NOT NULL,
    companion_type integer REFERENCES companion_types,
    notes varchar(255) NOT NULL,
    image varchar(255) UNIQUE,
    user_id serial CONSTRAINT "Companion_fk0" REFERENCES "User" ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "Event" (
    event_id serial CONSTRAINT "Event_pk" PRIMARY KEY,
    name varchar(10) NOT NULL,
    qr_code integer NOT NULL,
    notes varchar(255) NOT NULL,
    priority varchar(1) NOT NULL,
    frequency interval(1) NOT NULL,
    last_trigger timestamp(1) WITH time zone,
    next_trigger timestamp(1) WITH time zone,
    action varchar(10) NOT NULL,
    companion_id serial CONSTRAINT "Event_fk1" REFERENCES "Companion" ON DELETE CASCADE,
    user_id serial CONSTRAINT "Event_fk0" REFERENCES "User" ON DELETE CASCADE,
    UPDATE boolean DEFAULT FALSE NOT NULL
);

CREATE TABLE IF NOT EXISTS "QR_Range" (
    id serial PRIMARY KEY,
    assigned_range integer NOT NULL,
    user_id serial CONSTRAINT "QR_Range_fk0" REFERENCES "User" ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "QR_Codes" (
    id serial PRIMARY KEY,
    value integer NOT NULL,
    qr_id serial CONSTRAINT "QR_Codes_fk0" REFERENCES "QR_Range" ON DELETE CASCADE,
    event_id serial CONSTRAINT "QR_Codes_fk1" REFERENCES "Event" ON DELETE CASCADE
);

CREATE FUNCTION update_next_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.update != FALSE THEN
        UPDATE
            "Event"
        SET
            next_trigger = frequency + now(),
            last_trigger = now(),
            UPDATE
                = FALSE
            WHERE
                UPDATE
                    = TRUE;
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION event_completed_log ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.update != FALSE THEN
        INSERT INTO "Event_Logs" ("event_id", "user_id", "completed_at")
            VALUES (NEW.event_id, NEW.user_id, now());
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_triggers
    AFTER UPDATE ON "Event" FOR EACH ROW
    EXECUTE PROCEDURE update_next_trigger ();

CREATE TRIGGER create_trigger
    AFTER INSERT ON "Event" FOR EACH ROW
    EXECUTE PROCEDURE update_next_trigger ();

CREATE TRIGGER event_completed_log
    BEFORE UPDATE ON "Event" FOR EACH ROW
    EXECUTE PROCEDURE event_completed_log ();

