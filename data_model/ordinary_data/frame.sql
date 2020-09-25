-- Table: siro_od.frame

-- DROP TABLE siro_od.frame;

CREATE TABLE siro_od.frame
(
    id uuid PRIMARY KEY default uuid_generate_v1(),
    fk_frame_type int,
    fk_fixing_type int,
    double-sided boolean,
    fk_status int,
    rank int,
    comment text,
    picture text,
    CONSTRAINT fkey_vl_frame_type FOREIGN KEY (fk_frame_type) REFERENCES siro_vl.frame_type (id) MATCH SIMPLE,
    CONSTRAINT fkey_vl_fixing_type FOREIGN KEY (fk_fixing_type) REFERENCES siro_vl.fixing_type (id) MATCH SIMPLE
);