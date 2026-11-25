"""Load the raw retail CSV files into PostgreSQL.

Every CSV in the data directory becomes a table, named after the file, in the raw schema
that the dbt `source` points at (`public` in dev, `source` in prod).

Connection details come from the standard libpq environment variables, so no credentials
are stored in the repository:

    export PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=... PGDATABASE=source
    uv run python scripts/load_raw_data.py --data-dir ~/Desktop/source-data --schema public

`fact_returns.csv` has no last-modified column, so the loader adds `updated_at` (the load
time). The `snap_returns` snapshot uses it with the timestamp strategy.

Tables are replaced on each run. Run it before the first `dbt build`: Postgres will refuse
to drop a raw table while bronze views still depend on it.
"""

import argparse
import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


def build_engine():
    url = URL.create(
        "postgresql+psycopg2",
        username=os.getenv("PGUSER", "postgres"),
        password=os.environ["PGPASSWORD"],
        host=os.getenv("PGHOST", "localhost"),
        port=int(os.getenv("PGPORT", "5432")),
        database=os.getenv("PGDATABASE", "source"),
    )
    return create_engine(url)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--data-dir", type=Path, default=Path(os.getenv("DATA_DIR", "data")))
    parser.add_argument("--schema", default=os.getenv("RAW_SCHEMA", "public"))
    args = parser.parse_args()

    files = sorted(args.data_dir.expanduser().glob("*.csv"))
    if not files:
        raise SystemExit(f"No CSV files found in {args.data_dir}")

    engine = build_engine()
    with engine.begin() as conn:
        conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{args.schema}"'))

    loaded_at = pd.Timestamp.now()
    for file in files:
        df = pd.read_csv(file)
        if file.stem == "fact_returns" and "updated_at" not in df.columns:
            df["updated_at"] = loaded_at
        df.to_sql(file.stem, engine, schema=args.schema, if_exists="replace", index=False)
        print(f"Loaded {args.schema}.{file.stem}: {len(df)} rows")


if __name__ == "__main__":
    main()
