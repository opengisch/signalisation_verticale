
CREATE TABLE siro_od.sign
(
    id uuid PRIMARY KEY default uuid_generate_v1(),
    rank int default 1,
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
    fk_frame uuid,
    fk_coating int,
    fk_lighting int,
    destination text,
    azimut smallint,
    comment text,
    photo text,
    CONSTRAINT fkey_vl_sign_type FOREIGN KEY (fk_sign_type) REFERENCES siro_vl.sign_type (id) MATCH SIMPLE,
    CONSTRAINT fkey_vl_official_sign FOREIGN KEY (fk_official_sign) REFERENCES siro_vl.official_sign (id) MATCH SIMPLE,
    CONSTRAINT fkey_od_sign FOREIGN KEY (fk_parent) REFERENCES siro_od.sign (id) MATCH SIMPLE,
    CONSTRAINT fkey_od_owner FOREIGN KEY (fk_owner) REFERENCES siro_od.owner (id) MATCH SIMPLE,
    CONSTRAINT fkey_vl_durability FOREIGN KEY (fk_durability) REFERENCES siro_vl.durability (id) MATCH SIMPLE,
    CONSTRAINT fkey_frame FOREIGN KEY (fk_frame) REFERENCES siro_od.frame (id) MATCH SIMPLE,
    CONSTRAINT fkey_vl_coating FOREIGN KEY (fk_coating) REFERENCES siro_vl.coating (id) MATCH SIMPLE,
    CONSTRAINT fkey_vl_lighting FOREIGN KEY (fk_lighting) REFERENCES siro_vl.lighting (id) MATCH SIMPLE,
    CONSTRAINT fkey_vl_status FOREIGN KEY (fk_status) REFERENCES siro_vl.status (id) MATCH SIMPLE
);