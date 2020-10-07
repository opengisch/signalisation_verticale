


CREATE TABLE siro_vl.coating
(
  id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  active boolean default true,
  value_en text,
  value_fr text,
  value_de text
);

INSERT INTO siro_vl.coating (id, value_en, value_fr, value_de) VALUES (1, 'unknown', 'inconnu', 'unknown');
INSERT INTO siro_vl.coating (id, value_en, value_fr, value_de) VALUES (2, 'other', 'autre', 'other');
INSERT INTO siro_vl.coating (id, value_en, value_fr, value_de) VALUES (3, 'to be determined', 'à déterminer', 'to be determined');

INSERT INTO siro_vl.coating (id, value_en, value_fr, value_de, description_en, description_fr, description_de)  VALUES (10, 'coating type 1', 'revêtement type 1', 'coating type 1', 'Engineer Grade (EG) Sign Guarantees 10 years', 'Engineer Grade (EG) Signal garanti 10 ans', 'Engineer Grade (EG) Sign Guarantees 10 years');
INSERT INTO siro_vl.coating (id, value_en, value_fr, value_de, description_en, description_fr, description_de)  VALUES (10, 'coating type 2', 'revêtement type 2', 'coating type 2', 'High Intensity Prismatic (HIP) Sign Guarantees 13 years', 'High Intensity Prismatic (HIP) Signal garanti 13 ans', 'High Intensity Prismatic (HIP) Sign Guarantees 13 years');
INSERT INTO siro_vl.coating (id, value_en, value_fr, value_de, description_en, description_fr, description_de)  VALUES (10, 'coating type 3', 'revêtement type 3', 'coating type 3', 'Diamond Grade (DG3) Sign Guarantees 15 years', 'Diamond Grade (DG3) Signal garanti 15 ans', 'Diamond Grade (DG3) Sign Guarantees 15 years');
INSERT INTO siro_vl.coating (id, value_en, value_fr, value_de, description_en, description_fr, description_de)  VALUES (10, 'coating type I', 'revêtement type I', 'coating type I', 'Interior lighted panels', 'Panneaux éclairés intérieurement', 'Interior lighted panels');
