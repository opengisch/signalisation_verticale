-- Table: siro_od.support

-- DROP TABLE siro_od.support;

CREATE TABLE siro_od.support
(
    id uuid PRIMARY KEY default uuid_generate_v1(),
    adress text,
    fk_support_type int,
    fk_owner uuid,
    fk_support_base_type int,
    height numeric(8,3),
    height_free_under_signal numeric(8,3),
    date_install date,
    date_last_stability_check date,
    fk_status int,
    comment text,
    picture text,
    geometry geometry(Point,$SRID) NOT NULL,
    CONSTRAINT fkey_vl_support_type FOREIGN KEY (fk_support_type) REFERENCES siro_vl.support_type (id) MATCH FULL,
    CONSTRAINT fkey_od_owner FOREIGN KEY (fk_owner) REFERENCES siro_od.owner (id) MATCH FULL,
    CONSTRAINT fkey_vl_status FOREIGN KEY (fk_status) REFERENCES siro_vl.status (id) MATCH FULL,
    CONSTRAINT fkey_vl_support_base_type FOREIGN KEY (fk_support_base_type) REFERENCES siro_vl.support_base_type (id) MATCH FULL
);