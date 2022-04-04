CREATE TABLE "Companion" (
	"companion" serial NOT NULL UNIQUE,
	"name" varchar(10) NOT NULL,
	"companion_type" varchar(10) NOT NULL,
	"notes" varchar(255) NOT NULL,
	"image" varchar(255) NOT NULL,
	"username_id" varchar(10) NOT NULL,
	CONSTRAINT "Companion_pk" PRIMARY KEY ("companion")
) WITH (
  OIDS=FALSE
);

CREATE TABLE "Event" (
	"event_id" serial NOT NULL,
	"name" varchar(10) NOT NULL,
	"qr_code" integer NOT NULL,
	"notes" varchar(255) NOT NULL,
	"priority" varchar(1) NOT NULL,
	"frequency" interval(1) NOT NULL,
	"last_trigger" timestamp(1) with time zone,
	"next_trigger" timestamp(1) with time zone,
	"action" varchar(10) NOT NULL,
	"companion_id" integer NOT NULL,
	"username_id" varchar(10) NOT NULL,
	"update" bool default false NOT NULL,
	CONSTRAINT "Event_pk" PRIMARY KEY ("event_id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "User" (
	"username" varchar(10) NOT NULL,
	"hashed_password" varchar(64) NOT NULL,
	"is_active" boolean NOT NULL DEFAULT 'true',
	CONSTRAINT "User_pk" PRIMARY KEY ("username")
) WITH (
  OIDS=FALSE
);



ALTER TABLE "Companion" ADD CONSTRAINT "Companion_fk0" FOREIGN KEY ("username_id") REFERENCES "User"("username");
ALTER TABLE "Event" ADD CONSTRAINT "Event_fk0" FOREIGN KEY (companion_id) REFERENCES "Companion"("companion");
ALTER TABLE "Event" ADD CONSTRAINT "Event_fk1" FOREIGN KEY ("username_id") REFERENCES "User"("username");

CREATE OR REPLACE FUNCTION update_next_trigger()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	IF NEW.frequency != OLD.frequency or NEW.update != FALSE THEN
	    UPDATE "Event" set next_trigger = frequency + now(), last_trigger = now(), update = false
	        where OLD.event_id = NEW.event_id;
	END if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER update_triggers
  AFTER UPDATE
  ON "Event"
  FOR EACH ROW
  EXECUTE PROCEDURE update_next_trigger();
  
  

