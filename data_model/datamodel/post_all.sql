
CREATE OR REPLACE VIEW siro_od.vw_sign_symbol AS

WITH joined_tables AS (      
    SELECT
        -- NOTE : for now, hardcoded {sign_columns} select_columns(table_name='sign', skip_columns=['rank', 'fk_frame'], ...)
        sign.id, sign.verso, sign.fk_sign_type, sign.fk_official_sign, sign.fk_parent, sign.fk_owner, sign.fk_durability, sign.fk_status, sign.installation_date, sign.manufacturing_date, sign.case_id, sign.case_decision, sign.fk_coating, sign.fk_lighting, sign.destination, sign.comment, sign.photo
        , azimut.azimut
        -- NOTE : for now, hardcoded {frame_columns} select_columns(table_name='frame', prefix='frame_', ...)
        , frame.id as frame_id, frame.fk_azimut as frame_fk_azimut, frame.rank as frame_rank, frame.fk_frame_type as frame_fk_frame_type, frame.fk_frame_fixing_type as frame_fk_frame_fixing_type, frame.double_sided as frame_double_sided, frame.fk_status as frame_fk_status, frame.comment as frame_comment, frame.picture as frame_picture
        , sign.rank AS sign_rank
        , support.id AS support_id
        , support.geometry::geometry(Point,$SRID) AS support_geometry
        , official_sign.img_de as _img_de
        , official_sign.img_fr as _img_fr
        , official_sign.img_it as _img_it
        , official_sign.img_ro as _img_ro
        , official_sign.img_height as _symbol_height
        , official_sign.img_width as _symbol_width
    FROM siro_od.sign
        LEFT JOIN siro_od.frame ON frame.id = sign.fk_frame
        LEFT JOIN siro_od.azimut ON azimut.id = frame.fk_azimut
        LEFT JOIN siro_od.support ON support.id = azimut.fk_support
        LEFT JOIN siro_vl.official_sign ON official_sign.id = sign.fk_official_sign
),
ordered_recto_signs AS (
    SELECT
        joined_tables.*
        , ROW_NUMBER () OVER ( PARTITION BY support_id, azimut ORDER BY frame_rank, sign_rank ) AS _final_rank
    FROM joined_tables
    WHERE verso IS FALSE
    ORDER BY support_id, azimut, _final_rank
),
ordered_shifted_recto_signs AS (
    SELECT
        ordered_recto_signs.*
        , SUM( _symbol_height ) OVER ( PARTITION BY support_id, azimut ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS _symbol_shift
        , NULLIF(FIRST_VALUE(id) OVER (PARTITION BY support_id, azimut, frame_rank ROWS BETWEEN 1 PRECEDING AND CURRENT ROW ), id) AS _previous_sign_in_frame
        , NULLIF(LAST_VALUE(id) OVER ( PARTITION BY support_id, azimut, frame_rank ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING ), id) AS _next_sign_in_frame
        , NULLIF(FIRST_VALUE(frame_id) OVER ( PARTITION BY support_id, azimut ROWS BETWEEN 1 PRECEDING AND CURRENT ROW ), frame_id) AS _previous_frame
        , NULLIF(LAST_VALUE(frame_id) OVER ( PARTITION BY support_id, azimut ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING ), frame_id) AS _next_frame
    FROM
        ordered_recto_signs
    ORDER BY 
        support_id, azimut, _final_rank
)
    SELECT * FROM ordered_shifted_recto_signs
UNION 
    SELECT jt.*, osrs._final_rank, osrs._symbol_shift, NULL::uuid AS previous_sign_in_frame, NULL::uuid AS next_sign_in_frame, NULL::uuid AS previous_frame, NULL::uuid AS next_frame
    FROM joined_tables jt
    LEFT JOIN ordered_shifted_recto_signs osrs ON osrs.support_id = jt.support_id AND osrs.frame_id = jt.frame_id AND jt.sign_rank = osrs.sign_rank 
    WHERE jt.verso IS TRUE   
;

ALTER VIEW siro_od.vw_sign_symbol ALTER verso SET DEFAULT false;


CREATE OR REPLACE FUNCTION siro_od.ft_vw_sign_symbol_INSERT()
    RETURNS trigger AS
$BODY$
BEGIN

IF NEW.frame_id IS NULL THEN
    -- TODO : 
    /*
    replace this by plain SQL
    insert_frame=insert_command(
            pg_cur=cursor, table_schema='siro_od', table_name='frame', remove_pkey=True, indent=4,
            skip_columns=[], returning='id INTO NEW.frame_id', prefix='frame_'
        ),
    */
END IF;

-- TODO : 
/*
replace this by plain SQL
insert_sign=insert_command(
            pg_cur=cursor, table_schema='siro_od', table_name='sign', remove_pkey=True, indent=4,
            skip_columns=[], remap_columns={'fk_frame': 'frame_id', 'rank': 'sign_rank'}, returning='id INTO NEW.id'
        )
*/

    RETURN NEW;
END; $BODY$ LANGUAGE plpgsql VOLATILE;

DROP TRIGGER IF EXISTS vw_sign_symbol_INSERT ON siro_od.vw_sign_symbol;

CREATE TRIGGER vw_sign_symbol_INSERT INSTEAD OF INSERT ON siro_od.vw_sign_symbol
    FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_vw_sign_symbol_INSERT();
    
CREATE OR REPLACE FUNCTION siro_od.ft_vw_siro_sign_symbol_UPDATE()
    RETURNS trigger AS
$BODY$
DECLARE
BEGIN

--TODO
/*
replace this by plain SQL
update_sign=update_command(
    pg_cur=cursor, table_schema='siro_od', table_name='sign',
    indent=4, skip_columns=[], remap_columns={'fk_frame': 'frame_id', 'rank': 'sign_rank'}
)
update_frame=update_command(
    pg_cur=cursor, table_schema='siro_od', table_name='frame', prefix='frame_',
    indent=4, skip_columns=[], remap_columns={}
)
*/
RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ft_vw_siro_sign_symbol_UPDATE ON siro_od.vw_sign_symbol;

CREATE TRIGGER vw_sign_symbol_UPDATE INSTEAD OF UPDATE ON siro_od.vw_sign_symbol
    FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_vw_siro_sign_symbol_UPDATE();
    
CREATE OR REPLACE FUNCTION siro_od.ft_vw_sign_symbol_DELETE()
    RETURNS trigger AS
$BODY$
DECLARE
    _sign_count integer;
BEGIN
    DELETE FROM siro_od.sign WHERE id = OLD.id;
    SELECT count(id) INTO _sign_count FROM siro_od.sign WHERE fk_frame = OLD.frame_id;
    IF _sign_count = 0 THEN
    DELETE FROM siro_od.frame WHERE id = OLD.frame_id;
    END IF;   
RETURN OLD;
END; $BODY$ LANGUAGE plpgsql VOLATILE;

DROP TRIGGER IF EXISTS vw_sign_symbol_DELETE ON siro_od.vw_sign_symbol;

CREATE TRIGGER vw_sign_symbol_DELETE INSTEAD OF DELETE ON siro_od.vw_sign_symbol
    FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_vw_sign_symbol_DELETE();
