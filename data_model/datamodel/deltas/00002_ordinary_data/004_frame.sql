-- Table: siro_od.frame

-- DROP TABLE siro_od.frame;

CREATE TABLE siro_od.frame
(
    id uuid PRIMARY KEY default uuid_generate_v1(),
    fk_azimut uuid not null,
    rank int default 1, -- TODO: get default
    fk_frame_type int,
    fk_frame_fixing_type int,
    double_sided boolean default true,
    fk_status int,
    comment text,
    picture text,
    CONSTRAINT fkey_od_azimut FOREIGN KEY (fk_azimut) REFERENCES siro_od.azimut (id) MATCH FULL,
    CONSTRAINT fkey_vl_frame_type FOREIGN KEY (fk_frame_type) REFERENCES siro_vl.frame_type (id) MATCH FULL,
    CONSTRAINT fkey_vl_status FOREIGN KEY (fk_status) REFERENCES siro_vl.status (id) MATCH FULL,
    CONSTRAINT fkey_vl_frame_fixing_type FOREIGN KEY (fk_frame_fixing_type) REFERENCES siro_vl.frame_fixing_type (id) MATCH FULL,
    UNIQUE (fk_azimut, rank)
);

-- reorder frames after deletion or azimut change
CREATE OR REPLACE FUNCTION siro_od.ft_reorder_frames_on_support() RETURNS TRIGGER AS
	$BODY$
	DECLARE
	    _rank integer := 1;
	    _frame record;
	BEGIN
        FOR _frame IN (SELECT * FROM siro_od.frame WHERE fk_azimut = OLD.fk_azimut ORDER BY rank ASC)
        LOOP
            UPDATE siro_od.frame SET rank = _rank WHERE id = _frame.id;
            _rank = _rank + 1;
        END LOOP;
		RETURN OLD;
	END;
	$BODY$
	LANGUAGE plpgsql;

-- on delete
CREATE TRIGGER tr_frame_on_delete_reorder
	AFTER DELETE ON siro_od.frame
	FOR EACH ROW
	EXECUTE PROCEDURE siro_od.ft_reorder_frames_on_support();
COMMENT ON TRIGGER tr_frame_on_delete_reorder ON siro_od.frame IS 'Trigger: update frames order after deleting one.';

-- before changing azimut, update rank to be the last on the new azimut
CREATE OR REPLACE FUNCTION siro_od.ft_reorder_frames_on_support_put_last() RETURNS TRIGGER AS
	$BODY$
	BEGIN
	    NEW.rank := (SELECT MAX(rank)+1 FROM siro_od.frame WHERE fk_azimut = NEW.fk_azimut);
		RETURN NEW;
	END;
	$BODY$
	LANGUAGE plpgsql;

CREATE TRIGGER tr_frame_on_update_azimut_reorder_prepare
	BEFORE UPDATE OF fk_azimut ON siro_od.frame
	FOR EACH ROW
	WHEN (OLD.fk_azimut <> NEW.fk_azimut)
	EXECUTE PROCEDURE siro_od.ft_reorder_frames_on_support_put_last();
COMMENT ON TRIGGER tr_frame_on_update_azimut_reorder_prepare ON siro_od.frame IS 'Trigger: after changing azimut, adapt rank be last on new azimut';

-- after changing azimut, update frame ranks on old azimut
CREATE TRIGGER tr_frame_on_update_azimut_reorder
	AFTER UPDATE OF fk_azimut ON siro_od.frame
	FOR EACH ROW
	WHEN (OLD.fk_azimut <> NEW.fk_azimut)
	EXECUTE PROCEDURE siro_od.ft_reorder_frames_on_support();
COMMENT ON TRIGGER tr_frame_on_update_azimut_reorder ON siro_od.frame IS 'Trigger: update frames order after changing azimut.';

