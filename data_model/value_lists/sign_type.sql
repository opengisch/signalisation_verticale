


CREATE TABLE siro_vl.sign_type
(
  id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  active boolean default true,
  value_en text,
  value_fr text,
  value_de text
);

INSERT INTO siro_vl.sign_type (id, value_de, value_fr, value_it, value_ro) VALUES (1, 'TBD', 'inconnu', 'TBD', 'TBD');
INSERT INTO siro_vl.sign_type (id, value_de, value_fr, value_it, value_ro) VALUES (2, 'TBD', 'autre', 'TBD', 'TBD');
INSERT INTO siro_vl.sign_type (id, value_de, value_fr, value_it, value_ro) VALUES (3, 'to be determined', 'à déterminer', 'to be determined', 'TBD');

INSERT INTO siro_vl.sign_type (id, value_de, value_fr, value_it, value_ro) VALUES (11, 'TBD', 'official', 'TBD', 'TBD');
INSERT INTO siro_vl.sign_type (id, value_de, value_fr, value_it, value_ro) VALUES (12, 'TBD', 'balise', 'TBD', 'TBD');
INSERT INTO siro_vl.sign_type (id, value_de, value_fr, value_it, value_ro) VALUES (13, 'TBD', 'miroir', 'TBD', 'TBD');
INSERT INTO siro_vl.sign_type (id, value_de, value_fr, value_it, value_ro) VALUES (14, 'TBD', 'plaque de rue', 'TBD', 'TBD');
