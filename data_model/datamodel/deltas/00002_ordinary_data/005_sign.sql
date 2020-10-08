
CREATE TABLE siro_od.sign
(
    id uuid PRIMARY KEY default uuid_generate_v1(),
    fk_frame uuid not null,
    rank int default 1,
    verso boolean not null default false,
    fk_sign_type int NOT NULL,
    fk_official_sign text,
    fk_parent uuid, --self-reference
    fk_owner uuid,
    fk_durability int,
    fk_status int,
    installation_date date,
    manufacturing_date date, -- to manage the the guarantee
    case_id text,
    case_decision text,
    -- date_repose
    fk_coating int,
    fk_lighting int,
    destination text,
    comment text,
    photo text,
    CONSTRAINT fkey_od_frame FOREIGN KEY (fk_frame) REFERENCES siro_od.frame (id) MATCH FULL,
    CONSTRAINT fkey_vl_sign_type FOREIGN KEY (fk_sign_type) REFERENCES siro_vl.sign_type (id) MATCH FULL,
    CONSTRAINT fkey_vl_official_sign FOREIGN KEY (fk_official_sign) REFERENCES siro_vl.official_sign (id) MATCH FULL,
    CONSTRAINT fkey_od_sign FOREIGN KEY (fk_parent) REFERENCES siro_od.sign (id)  MATCH FULL ON DELETE SET NULL,
    CONSTRAINT fkey_od_owner FOREIGN KEY (fk_owner) REFERENCES siro_od.owner (id) MATCH FULL,
    CONSTRAINT fkey_vl_durability FOREIGN KEY (fk_durability) REFERENCES siro_vl.durability (id) MATCH FULL,
    CONSTRAINT fkey_vl_coating FOREIGN KEY (fk_coating) REFERENCES siro_vl.coating (id) MATCH FULL,
    CONSTRAINT fkey_vl_lighting FOREIGN KEY (fk_lighting) REFERENCES siro_vl.lighting (id) MATCH FULL,
    CONSTRAINT fkey_vl_status FOREIGN KEY (fk_status) REFERENCES siro_vl.status (id) MATCH FULL,
    unique(fk_frame, rank, verso)
);

-- reorder sign after deletion
CREATE OR REPLACE FUNCTION siro_od.ft_reorder_signs_in_frame() RETURNS TRIGGER AS
	$BODY$
	DECLARE
	    _rank integer := 1;
	    _sign record;
	BEGIN
        FOR _sign IN (SELECT * FROM siro_od.sign WHERE fk_frame = OLD.fk_frame ORDER BY rank ASC)
        LOOP
            UPDATE siro_od.sign SET rank = _rank WHERE id = _sign.id;
            _rank = _rank + 1;
        END LOOP;
		RETURN OLD;
	END;
	$BODY$
	LANGUAGE plpgsql;

CREATE TRIGGER tr_sign_on_delete_reorder
	AFTER DELETE ON siro_od.sign
	FOR EACH ROW
	EXECUTE PROCEDURE siro_od.ft_reorder_signs_in_frame();
COMMENT ON TRIGGER tr_sign_on_delete_reorder ON siro_od.sign IS 'Trigger: update signs order after deleting one.';

-- prevent reassigning to different frame
CREATE OR REPLACE FUNCTION siro_od.ft_sign_prevent_fk_frame_update() RETURNS TRIGGER AS
    $BODY$
    BEGIN
      RAISE EXCEPTION 'A sign cannot be reassigned to another frame.';
    END;
    $BODY$ LANGUAGE PLPGSQL;

CREATE TRIGGER tr_sign_on_update_prevent_fk_frame
    BEFORE UPDATE OF fk_frame ON siro_od.sign
    FOR EACH ROW
    WHEN (NEW.fk_frame <> OLD.fk_frame)
    EXECUTE PROCEDURE siro_od.ft_sign_prevent_fk_frame_update();