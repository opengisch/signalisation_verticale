

-- https://fr.wikipedia.org/wiki/Repr%C3%A9sentation_de_la_signalisation_routi%C3%A8re_en_Suisse_et_au_Liechtenstein
--https://www.astra.admin.ch/astra/fr/home/documentation/regles-de-la-circulation/signaux.html

-- to create inserts statment: pg_dump --data-only -t siro_vl.official_sign --column-inserts | gsort | gsed '/^INSERT/!d' > data_model/value_lists/offical_sign_content.sql

CREATE TABLE siro_vl.official_sign
(
  id text primary key,
  active boolean default true,
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
  img_height int default 100,
  img_width int default 100
);
