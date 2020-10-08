CREATE SCHEMA IF NOT EXISTS "public";

CREATE TABLE IF NOT EXISTS "migrations"(
    "migration" VARCHAR NOT NULL,
    "applied" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY ("migration")
);
