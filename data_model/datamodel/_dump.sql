--
-- PostgreSQL database dump
--

-- Dumped from database version 10.14
-- Dumped by pg_dump version 12.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: siro_od; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA siro_od;


ALTER SCHEMA siro_od OWNER TO postgres;

--
-- Name: siro_sys; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA siro_sys;


ALTER SCHEMA siro_sys OWNER TO postgres;

--
-- Name: siro_vl; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA siro_vl;


ALTER SCHEMA siro_vl OWNER TO postgres;

--
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger;


ALTER SCHEMA tiger OWNER TO postgres;

--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger_data;


ALTER SCHEMA tiger_data OWNER TO postgres;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: ft_reorder_frames_on_support(); Type: FUNCTION; Schema: siro_od; Owner: postgres
--

CREATE FUNCTION siro_od.ft_reorder_frames_on_support() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
	$$;


ALTER FUNCTION siro_od.ft_reorder_frames_on_support() OWNER TO postgres;

--
-- Name: ft_reorder_frames_on_support_put_last(); Type: FUNCTION; Schema: siro_od; Owner: postgres
--

CREATE FUNCTION siro_od.ft_reorder_frames_on_support_put_last() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    NEW.rank := (SELECT MAX(rank)+1 FROM siro_od.frame WHERE fk_azimut = NEW.fk_azimut);
		RETURN NEW;
	END;
	$$;


ALTER FUNCTION siro_od.ft_reorder_frames_on_support_put_last() OWNER TO postgres;

--
-- Name: ft_reorder_signs_in_frame(); Type: FUNCTION; Schema: siro_od; Owner: postgres
--

CREATE FUNCTION siro_od.ft_reorder_signs_in_frame() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
	$$;


ALTER FUNCTION siro_od.ft_reorder_signs_in_frame() OWNER TO postgres;

--
-- Name: ft_sign_prevent_fk_frame_update(); Type: FUNCTION; Schema: siro_od; Owner: postgres
--

CREATE FUNCTION siro_od.ft_sign_prevent_fk_frame_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RAISE EXCEPTION 'A sign cannot be reassigned to another frame.';
    END;
    $$;


ALTER FUNCTION siro_od.ft_sign_prevent_fk_frame_update() OWNER TO postgres;

--
-- Name: ft_vw_sign_symbol_delete(); Type: FUNCTION; Schema: siro_od; Owner: postgres
--

CREATE FUNCTION siro_od.ft_vw_sign_symbol_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    _sign_count integer;
BEGIN
    DELETE FROM siro_od.sign WHERE id = OLD.id;
    SELECT count(id) INTO _sign_count FROM siro_od.sign WHERE fk_frame = OLD.frame_id;
    IF _sign_count = 0 THEN
    DELETE FROM siro_od.frame WHERE id = OLD.frame_id;
    END IF;   
RETURN OLD;
END; $$;


ALTER FUNCTION siro_od.ft_vw_sign_symbol_delete() OWNER TO postgres;

--
-- Name: ft_vw_sign_symbol_insert(); Type: FUNCTION; Schema: siro_od; Owner: postgres
--

CREATE FUNCTION siro_od.ft_vw_sign_symbol_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
END; $$;


ALTER FUNCTION siro_od.ft_vw_sign_symbol_insert() OWNER TO postgres;

--
-- Name: ft_vw_siro_sign_symbol_update(); Type: FUNCTION; Schema: siro_od; Owner: postgres
--

CREATE FUNCTION siro_od.ft_vw_siro_sign_symbol_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION siro_od.ft_vw_siro_sign_symbol_update() OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    migration character varying NOT NULL,
    applied timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- Name: azimut; Type: TABLE; Schema: siro_od; Owner: postgres
--

CREATE TABLE siro_od.azimut (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    fk_support uuid NOT NULL,
    azimut smallint DEFAULT 0
);


ALTER TABLE siro_od.azimut OWNER TO postgres;

--
-- Name: frame; Type: TABLE; Schema: siro_od; Owner: postgres
--

CREATE TABLE siro_od.frame (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    fk_azimut uuid NOT NULL,
    rank integer DEFAULT 1,
    fk_frame_type integer,
    fk_frame_fixing_type integer,
    double_sided boolean DEFAULT true,
    fk_status integer,
    comment text,
    picture text
);


ALTER TABLE siro_od.frame OWNER TO postgres;

--
-- Name: owner; Type: TABLE; Schema: siro_od; Owner: postgres
--

CREATE TABLE siro_od.owner (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    name text
);


ALTER TABLE siro_od.owner OWNER TO postgres;

--
-- Name: sign; Type: TABLE; Schema: siro_od; Owner: postgres
--

CREATE TABLE siro_od.sign (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    fk_frame uuid NOT NULL,
    rank integer DEFAULT 1,
    verso boolean DEFAULT false NOT NULL,
    fk_sign_type integer NOT NULL,
    fk_official_sign text,
    fk_parent uuid,
    fk_owner uuid,
    fk_durability integer,
    fk_status integer,
    installation_date date,
    manufacturing_date date,
    case_id text,
    case_decision text,
    fk_coating integer,
    fk_lighting integer,
    destination text,
    comment text,
    photo text
);


ALTER TABLE siro_od.sign OWNER TO postgres;

--
-- Name: support; Type: TABLE; Schema: siro_od; Owner: postgres
--

CREATE TABLE siro_od.support (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    adress text,
    fk_support_type integer,
    fk_owner uuid,
    fk_support_base_type integer,
    height numeric(8,3),
    height_free_under_signal numeric(8,3),
    date_install date,
    date_last_stability_check date,
    fk_status integer,
    comment text,
    picture text,
    geometry public.geometry(Point,2056) NOT NULL
);


ALTER TABLE siro_od.support OWNER TO postgres;

--
-- Name: official_sign; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.official_sign (
    id text NOT NULL,
    active boolean DEFAULT true,
    value_de text,
    value_fr text,
    value_it text,
    value_ro text,
    description_de text,
    description_fr text,
    description_it text,
    description_ro text,
    img_de text,
    img_fr text,
    img_it text,
    img_ro text,
    img_height integer DEFAULT 100,
    img_width integer DEFAULT 100
);


ALTER TABLE siro_vl.official_sign OWNER TO postgres;

--
-- Name: vw_sign_symbol; Type: VIEW; Schema: siro_od; Owner: postgres
--

CREATE VIEW siro_od.vw_sign_symbol AS
 WITH joined_tables AS (
         SELECT sign.id,
            sign.verso,
            sign.fk_sign_type,
            sign.fk_official_sign,
            sign.fk_parent,
            sign.fk_owner,
            sign.fk_durability,
            sign.fk_status,
            sign.installation_date,
            sign.manufacturing_date,
            sign.case_id,
            sign.case_decision,
            sign.fk_coating,
            sign.fk_lighting,
            sign.destination,
            sign.comment,
            sign.photo,
            azimut.azimut,
            frame.id AS frame_id,
            frame.fk_azimut AS frame_fk_azimut,
            frame.rank AS frame_rank,
            frame.fk_frame_type AS frame_fk_frame_type,
            frame.fk_frame_fixing_type AS frame_fk_frame_fixing_type,
            frame.double_sided AS frame_double_sided,
            frame.fk_status AS frame_fk_status,
            frame.comment AS frame_comment,
            frame.picture AS frame_picture,
            sign.rank AS sign_rank,
            support.id AS support_id,
            support.geometry AS support_geometry,
            official_sign.img_de AS _img_de,
            official_sign.img_fr AS _img_fr,
            official_sign.img_it AS _img_it,
            official_sign.img_ro AS _img_ro,
            official_sign.img_height AS _symbol_height,
            official_sign.img_width AS _symbol_width
           FROM ((((siro_od.sign
             LEFT JOIN siro_od.frame ON ((frame.id = sign.fk_frame)))
             LEFT JOIN siro_od.azimut ON ((azimut.id = frame.fk_azimut)))
             LEFT JOIN siro_od.support ON ((support.id = azimut.fk_support)))
             LEFT JOIN siro_vl.official_sign ON ((official_sign.id = sign.fk_official_sign)))
        ), ordered_recto_signs AS (
         SELECT joined_tables.id,
            joined_tables.verso,
            joined_tables.fk_sign_type,
            joined_tables.fk_official_sign,
            joined_tables.fk_parent,
            joined_tables.fk_owner,
            joined_tables.fk_durability,
            joined_tables.fk_status,
            joined_tables.installation_date,
            joined_tables.manufacturing_date,
            joined_tables.case_id,
            joined_tables.case_decision,
            joined_tables.fk_coating,
            joined_tables.fk_lighting,
            joined_tables.destination,
            joined_tables.comment,
            joined_tables.photo,
            joined_tables.azimut,
            joined_tables.frame_id,
            joined_tables.frame_fk_azimut,
            joined_tables.frame_rank,
            joined_tables.frame_fk_frame_type,
            joined_tables.frame_fk_frame_fixing_type,
            joined_tables.frame_double_sided,
            joined_tables.frame_fk_status,
            joined_tables.frame_comment,
            joined_tables.frame_picture,
            joined_tables.sign_rank,
            joined_tables.support_id,
            joined_tables.support_geometry,
            joined_tables._img_de,
            joined_tables._img_fr,
            joined_tables._img_it,
            joined_tables._img_ro,
            joined_tables._symbol_height,
            joined_tables._symbol_width,
            row_number() OVER (PARTITION BY joined_tables.support_id, joined_tables.azimut ORDER BY joined_tables.frame_rank, joined_tables.sign_rank) AS _final_rank
           FROM joined_tables
          WHERE (joined_tables.verso IS FALSE)
          ORDER BY joined_tables.support_id, joined_tables.azimut, (row_number() OVER (PARTITION BY joined_tables.support_id, joined_tables.azimut ORDER BY joined_tables.frame_rank, joined_tables.sign_rank))
        ), ordered_shifted_recto_signs AS (
         SELECT ordered_recto_signs.id,
            ordered_recto_signs.verso,
            ordered_recto_signs.fk_sign_type,
            ordered_recto_signs.fk_official_sign,
            ordered_recto_signs.fk_parent,
            ordered_recto_signs.fk_owner,
            ordered_recto_signs.fk_durability,
            ordered_recto_signs.fk_status,
            ordered_recto_signs.installation_date,
            ordered_recto_signs.manufacturing_date,
            ordered_recto_signs.case_id,
            ordered_recto_signs.case_decision,
            ordered_recto_signs.fk_coating,
            ordered_recto_signs.fk_lighting,
            ordered_recto_signs.destination,
            ordered_recto_signs.comment,
            ordered_recto_signs.photo,
            ordered_recto_signs.azimut,
            ordered_recto_signs.frame_id,
            ordered_recto_signs.frame_fk_azimut,
            ordered_recto_signs.frame_rank,
            ordered_recto_signs.frame_fk_frame_type,
            ordered_recto_signs.frame_fk_frame_fixing_type,
            ordered_recto_signs.frame_double_sided,
            ordered_recto_signs.frame_fk_status,
            ordered_recto_signs.frame_comment,
            ordered_recto_signs.frame_picture,
            ordered_recto_signs.sign_rank,
            ordered_recto_signs.support_id,
            ordered_recto_signs.support_geometry,
            ordered_recto_signs._img_de,
            ordered_recto_signs._img_fr,
            ordered_recto_signs._img_it,
            ordered_recto_signs._img_ro,
            ordered_recto_signs._symbol_height,
            ordered_recto_signs._symbol_width,
            ordered_recto_signs._final_rank,
            sum(ordered_recto_signs._symbol_height) OVER (PARTITION BY ordered_recto_signs.support_id, ordered_recto_signs.azimut ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS _symbol_shift,
            NULLIF(first_value(ordered_recto_signs.id) OVER (PARTITION BY ordered_recto_signs.support_id, ordered_recto_signs.azimut, ordered_recto_signs.frame_rank ROWS BETWEEN 1 PRECEDING AND CURRENT ROW), ordered_recto_signs.id) AS _previous_sign_in_frame,
            NULLIF(last_value(ordered_recto_signs.id) OVER (PARTITION BY ordered_recto_signs.support_id, ordered_recto_signs.azimut, ordered_recto_signs.frame_rank ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING), ordered_recto_signs.id) AS _next_sign_in_frame,
            NULLIF(first_value(ordered_recto_signs.frame_id) OVER (PARTITION BY ordered_recto_signs.support_id, ordered_recto_signs.azimut ROWS BETWEEN 1 PRECEDING AND CURRENT ROW), ordered_recto_signs.frame_id) AS _previous_frame,
            NULLIF(last_value(ordered_recto_signs.frame_id) OVER (PARTITION BY ordered_recto_signs.support_id, ordered_recto_signs.azimut ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING), ordered_recto_signs.frame_id) AS _next_frame
           FROM ordered_recto_signs
          ORDER BY ordered_recto_signs.support_id, ordered_recto_signs.azimut, ordered_recto_signs._final_rank
        )
 SELECT ordered_shifted_recto_signs.id,
    ordered_shifted_recto_signs.verso,
    ordered_shifted_recto_signs.fk_sign_type,
    ordered_shifted_recto_signs.fk_official_sign,
    ordered_shifted_recto_signs.fk_parent,
    ordered_shifted_recto_signs.fk_owner,
    ordered_shifted_recto_signs.fk_durability,
    ordered_shifted_recto_signs.fk_status,
    ordered_shifted_recto_signs.installation_date,
    ordered_shifted_recto_signs.manufacturing_date,
    ordered_shifted_recto_signs.case_id,
    ordered_shifted_recto_signs.case_decision,
    ordered_shifted_recto_signs.fk_coating,
    ordered_shifted_recto_signs.fk_lighting,
    ordered_shifted_recto_signs.destination,
    ordered_shifted_recto_signs.comment,
    ordered_shifted_recto_signs.photo,
    ordered_shifted_recto_signs.azimut,
    ordered_shifted_recto_signs.frame_id,
    ordered_shifted_recto_signs.frame_fk_azimut,
    ordered_shifted_recto_signs.frame_rank,
    ordered_shifted_recto_signs.frame_fk_frame_type,
    ordered_shifted_recto_signs.frame_fk_frame_fixing_type,
    ordered_shifted_recto_signs.frame_double_sided,
    ordered_shifted_recto_signs.frame_fk_status,
    ordered_shifted_recto_signs.frame_comment,
    ordered_shifted_recto_signs.frame_picture,
    ordered_shifted_recto_signs.sign_rank,
    ordered_shifted_recto_signs.support_id,
    ordered_shifted_recto_signs.support_geometry,
    ordered_shifted_recto_signs._img_de,
    ordered_shifted_recto_signs._img_fr,
    ordered_shifted_recto_signs._img_it,
    ordered_shifted_recto_signs._img_ro,
    ordered_shifted_recto_signs._symbol_height,
    ordered_shifted_recto_signs._symbol_width,
    ordered_shifted_recto_signs._final_rank,
    ordered_shifted_recto_signs._symbol_shift,
    ordered_shifted_recto_signs._previous_sign_in_frame,
    ordered_shifted_recto_signs._next_sign_in_frame,
    ordered_shifted_recto_signs._previous_frame,
    ordered_shifted_recto_signs._next_frame
   FROM ordered_shifted_recto_signs
UNION
 SELECT jt.id,
    jt.verso,
    jt.fk_sign_type,
    jt.fk_official_sign,
    jt.fk_parent,
    jt.fk_owner,
    jt.fk_durability,
    jt.fk_status,
    jt.installation_date,
    jt.manufacturing_date,
    jt.case_id,
    jt.case_decision,
    jt.fk_coating,
    jt.fk_lighting,
    jt.destination,
    jt.comment,
    jt.photo,
    jt.azimut,
    jt.frame_id,
    jt.frame_fk_azimut,
    jt.frame_rank,
    jt.frame_fk_frame_type,
    jt.frame_fk_frame_fixing_type,
    jt.frame_double_sided,
    jt.frame_fk_status,
    jt.frame_comment,
    jt.frame_picture,
    jt.sign_rank,
    jt.support_id,
    jt.support_geometry,
    jt._img_de,
    jt._img_fr,
    jt._img_it,
    jt._img_ro,
    jt._symbol_height,
    jt._symbol_width,
    osrs._final_rank,
    osrs._symbol_shift,
    NULL::uuid AS _previous_sign_in_frame,
    NULL::uuid AS _next_sign_in_frame,
    NULL::uuid AS _previous_frame,
    NULL::uuid AS _next_frame
   FROM (joined_tables jt
     LEFT JOIN ordered_shifted_recto_signs osrs ON (((osrs.support_id = jt.support_id) AND (osrs.frame_id = jt.frame_id) AND (jt.sign_rank = osrs.sign_rank))))
  WHERE (jt.verso IS TRUE);


ALTER TABLE siro_od.vw_sign_symbol OWNER TO postgres;

--
-- Name: coating; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.coating (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text,
    description_en text,
    description_fr text,
    description_de text
);


ALTER TABLE siro_vl.coating OWNER TO postgres;

--
-- Name: coating_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.coating ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.coating_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: durability; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.durability (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.durability OWNER TO postgres;

--
-- Name: durability_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.durability ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.durability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: frame_fixing_type; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.frame_fixing_type (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.frame_fixing_type OWNER TO postgres;

--
-- Name: frame_fixing_type_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.frame_fixing_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.frame_fixing_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: frame_type; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.frame_type (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.frame_type OWNER TO postgres;

--
-- Name: frame_type_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.frame_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.frame_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: lighting; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.lighting (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.lighting OWNER TO postgres;

--
-- Name: lighting_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.lighting ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.lighting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sign_type; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.sign_type (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.sign_type OWNER TO postgres;

--
-- Name: sign_type_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.sign_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.sign_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: status; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.status (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.status OWNER TO postgres;

--
-- Name: status_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.status ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: support_base_type; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.support_base_type (
    id integer NOT NULL,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.support_base_type OWNER TO postgres;

--
-- Name: support_base_type_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.support_base_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.support_base_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: support_type; Type: TABLE; Schema: siro_vl; Owner: postgres
--

CREATE TABLE siro_vl.support_type (
    id integer NOT NULL,
    active boolean DEFAULT true,
    value_en text,
    value_fr text,
    value_de text
);


ALTER TABLE siro_vl.support_type OWNER TO postgres;

--
-- Name: support_type_id_seq; Type: SEQUENCE; Schema: siro_vl; Owner: postgres
--

ALTER TABLE siro_vl.support_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME siro_vl.support_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: vw_sign_symbol verso; Type: DEFAULT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.vw_sign_symbol ALTER COLUMN verso SET DEFAULT false;


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (migration);


--
-- Name: azimut azimut_fk_support_azimut_key; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.azimut
    ADD CONSTRAINT azimut_fk_support_azimut_key UNIQUE (fk_support, azimut);


--
-- Name: azimut azimut_pkey; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.azimut
    ADD CONSTRAINT azimut_pkey PRIMARY KEY (id);


--
-- Name: frame frame_fk_azimut_rank_key; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.frame
    ADD CONSTRAINT frame_fk_azimut_rank_key UNIQUE (fk_azimut, rank);


--
-- Name: frame frame_pkey; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.frame
    ADD CONSTRAINT frame_pkey PRIMARY KEY (id);


--
-- Name: owner owner_pkey; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.owner
    ADD CONSTRAINT owner_pkey PRIMARY KEY (id);


--
-- Name: sign sign_fk_frame_rank_verso_key; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT sign_fk_frame_rank_verso_key UNIQUE (fk_frame, rank, verso);


--
-- Name: sign sign_pkey; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT sign_pkey PRIMARY KEY (id);


--
-- Name: support support_pkey; Type: CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.support
    ADD CONSTRAINT support_pkey PRIMARY KEY (id);


--
-- Name: coating coating_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.coating
    ADD CONSTRAINT coating_pkey PRIMARY KEY (id);


--
-- Name: durability durability_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.durability
    ADD CONSTRAINT durability_pkey PRIMARY KEY (id);


--
-- Name: frame_fixing_type frame_fixing_type_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.frame_fixing_type
    ADD CONSTRAINT frame_fixing_type_pkey PRIMARY KEY (id);


--
-- Name: frame_type frame_type_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.frame_type
    ADD CONSTRAINT frame_type_pkey PRIMARY KEY (id);


--
-- Name: lighting lighting_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.lighting
    ADD CONSTRAINT lighting_pkey PRIMARY KEY (id);


--
-- Name: official_sign official_sign_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.official_sign
    ADD CONSTRAINT official_sign_pkey PRIMARY KEY (id);


--
-- Name: sign_type sign_type_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.sign_type
    ADD CONSTRAINT sign_type_pkey PRIMARY KEY (id);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- Name: support_base_type support_base_type_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.support_base_type
    ADD CONSTRAINT support_base_type_pkey PRIMARY KEY (id);


--
-- Name: support_type support_type_pkey; Type: CONSTRAINT; Schema: siro_vl; Owner: postgres
--

ALTER TABLE ONLY siro_vl.support_type
    ADD CONSTRAINT support_type_pkey PRIMARY KEY (id);


--
-- Name: frame tr_frame_on_delete_reorder; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER tr_frame_on_delete_reorder AFTER DELETE ON siro_od.frame FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_reorder_frames_on_support();


--
-- Name: TRIGGER tr_frame_on_delete_reorder ON frame; Type: COMMENT; Schema: siro_od; Owner: postgres
--

COMMENT ON TRIGGER tr_frame_on_delete_reorder ON siro_od.frame IS 'Trigger: update frames order after deleting one.';


--
-- Name: frame tr_frame_on_update_azimut_reorder; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER tr_frame_on_update_azimut_reorder AFTER UPDATE OF fk_azimut ON siro_od.frame FOR EACH ROW WHEN ((old.fk_azimut <> new.fk_azimut)) EXECUTE PROCEDURE siro_od.ft_reorder_frames_on_support();


--
-- Name: TRIGGER tr_frame_on_update_azimut_reorder ON frame; Type: COMMENT; Schema: siro_od; Owner: postgres
--

COMMENT ON TRIGGER tr_frame_on_update_azimut_reorder ON siro_od.frame IS 'Trigger: update frames order after changing azimut.';


--
-- Name: frame tr_frame_on_update_azimut_reorder_prepare; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER tr_frame_on_update_azimut_reorder_prepare BEFORE UPDATE OF fk_azimut ON siro_od.frame FOR EACH ROW WHEN ((old.fk_azimut <> new.fk_azimut)) EXECUTE PROCEDURE siro_od.ft_reorder_frames_on_support_put_last();


--
-- Name: TRIGGER tr_frame_on_update_azimut_reorder_prepare ON frame; Type: COMMENT; Schema: siro_od; Owner: postgres
--

COMMENT ON TRIGGER tr_frame_on_update_azimut_reorder_prepare ON siro_od.frame IS 'Trigger: after changing azimut, adapt rank be last on new azimut';


--
-- Name: sign tr_sign_on_delete_reorder; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER tr_sign_on_delete_reorder AFTER DELETE ON siro_od.sign FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_reorder_signs_in_frame();


--
-- Name: TRIGGER tr_sign_on_delete_reorder ON sign; Type: COMMENT; Schema: siro_od; Owner: postgres
--

COMMENT ON TRIGGER tr_sign_on_delete_reorder ON siro_od.sign IS 'Trigger: update signs order after deleting one.';


--
-- Name: sign tr_sign_on_update_prevent_fk_frame; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER tr_sign_on_update_prevent_fk_frame BEFORE UPDATE OF fk_frame ON siro_od.sign FOR EACH ROW WHEN ((new.fk_frame <> old.fk_frame)) EXECUTE PROCEDURE siro_od.ft_sign_prevent_fk_frame_update();


--
-- Name: vw_sign_symbol vw_sign_symbol_delete; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER vw_sign_symbol_delete INSTEAD OF DELETE ON siro_od.vw_sign_symbol FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_vw_sign_symbol_delete();


--
-- Name: vw_sign_symbol vw_sign_symbol_insert; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER vw_sign_symbol_insert INSTEAD OF INSERT ON siro_od.vw_sign_symbol FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_vw_sign_symbol_insert();


--
-- Name: vw_sign_symbol vw_sign_symbol_update; Type: TRIGGER; Schema: siro_od; Owner: postgres
--

CREATE TRIGGER vw_sign_symbol_update INSTEAD OF UPDATE ON siro_od.vw_sign_symbol FOR EACH ROW EXECUTE PROCEDURE siro_od.ft_vw_siro_sign_symbol_update();


--
-- Name: frame fkey_od_azimut; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.frame
    ADD CONSTRAINT fkey_od_azimut FOREIGN KEY (fk_azimut) REFERENCES siro_od.azimut(id) MATCH FULL;


--
-- Name: sign fkey_od_frame; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_od_frame FOREIGN KEY (fk_frame) REFERENCES siro_od.frame(id) MATCH FULL;


--
-- Name: support fkey_od_owner; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.support
    ADD CONSTRAINT fkey_od_owner FOREIGN KEY (fk_owner) REFERENCES siro_od.owner(id) MATCH FULL;


--
-- Name: sign fkey_od_owner; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_od_owner FOREIGN KEY (fk_owner) REFERENCES siro_od.owner(id) MATCH FULL;


--
-- Name: sign fkey_od_sign; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_od_sign FOREIGN KEY (fk_parent) REFERENCES siro_od.sign(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: azimut fkey_od_support; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.azimut
    ADD CONSTRAINT fkey_od_support FOREIGN KEY (fk_support) REFERENCES siro_od.support(id) MATCH FULL;


--
-- Name: sign fkey_vl_coating; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_vl_coating FOREIGN KEY (fk_coating) REFERENCES siro_vl.coating(id) MATCH FULL;


--
-- Name: sign fkey_vl_durability; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_vl_durability FOREIGN KEY (fk_durability) REFERENCES siro_vl.durability(id) MATCH FULL;


--
-- Name: frame fkey_vl_frame_fixing_type; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.frame
    ADD CONSTRAINT fkey_vl_frame_fixing_type FOREIGN KEY (fk_frame_fixing_type) REFERENCES siro_vl.frame_fixing_type(id) MATCH FULL;


--
-- Name: frame fkey_vl_frame_type; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.frame
    ADD CONSTRAINT fkey_vl_frame_type FOREIGN KEY (fk_frame_type) REFERENCES siro_vl.frame_type(id) MATCH FULL;


--
-- Name: sign fkey_vl_lighting; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_vl_lighting FOREIGN KEY (fk_lighting) REFERENCES siro_vl.lighting(id) MATCH FULL;


--
-- Name: sign fkey_vl_official_sign; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_vl_official_sign FOREIGN KEY (fk_official_sign) REFERENCES siro_vl.official_sign(id) MATCH FULL;


--
-- Name: sign fkey_vl_sign_type; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_vl_sign_type FOREIGN KEY (fk_sign_type) REFERENCES siro_vl.sign_type(id) MATCH FULL;


--
-- Name: support fkey_vl_status; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.support
    ADD CONSTRAINT fkey_vl_status FOREIGN KEY (fk_status) REFERENCES siro_vl.status(id) MATCH FULL;


--
-- Name: frame fkey_vl_status; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.frame
    ADD CONSTRAINT fkey_vl_status FOREIGN KEY (fk_status) REFERENCES siro_vl.status(id) MATCH FULL;


--
-- Name: sign fkey_vl_status; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.sign
    ADD CONSTRAINT fkey_vl_status FOREIGN KEY (fk_status) REFERENCES siro_vl.status(id) MATCH FULL;


--
-- Name: support fkey_vl_support_base_type; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.support
    ADD CONSTRAINT fkey_vl_support_base_type FOREIGN KEY (fk_support_base_type) REFERENCES siro_vl.support_base_type(id) MATCH FULL;


--
-- Name: support fkey_vl_support_type; Type: FK CONSTRAINT; Schema: siro_od; Owner: postgres
--

ALTER TABLE ONLY siro_od.support
    ADD CONSTRAINT fkey_vl_support_type FOREIGN KEY (fk_support_type) REFERENCES siro_vl.support_type(id) MATCH FULL;


--
-- PostgreSQL database dump complete
--

