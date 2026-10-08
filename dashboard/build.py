"""Build dashboard/index.html from the Gold ad-hoc views.

Run from the project root after a dbt build:
    python -m dashboard.build
"""
import json
from decimal import Decimal
from pathlib import Path

from ingestion.database import get_connection

HERE = Path(__file__).parent

QUERIES = {
    "lgas": """
        select l.lga_code as code, a.lga_name as lga, a.median_age_persons as age,
               round(a.revenue_per_active_listing) as rev,
               m.pct_covering as cover, m.single_listing_hosts as hosts
        from gold.adhoc_median_age_vs_revenue a
        join gold.adhoc_mortgage_coverage m using (lga_name)
        join gold.dim_lga l on l.lga_name = a.lga_name and l.is_current
        order by rev desc""",
    "monthly": """
        select to_char(listing_month, 'YYYY-MM') as m,
               count(*) filter (where has_availability) as active,
               round(sum(estimated_revenue) / 1e6, 1) as revenue_m,
               round(sum(estimated_revenue) / count(*) filter (where has_availability)) as rev_per_active,
               percentile_cont(0.5) within group (order by price) filter (where has_availability) as median_price
        from gold.fact_listings
        group by 1
        order by 1""",
    "lga_monthly": """
        select lga_code as code, to_char(listing_month, 'YYYY-MM') as m,
               count(*) filter (where has_availability) as active,
               round(sum(estimated_revenue) / nullif(count(*) filter (where has_availability), 0)) as rpa
        from gold.fact_listings
        group by 1, 2""",
    "groups": "select performance_group as g, lga_name as lga from gold.adhoc_lga_demographics",
    "age": """
        select performance_group as g,
               round(avg(pct_age_0_14), 1) as a0, round(avg(pct_age_15_24), 1) as a15,
               round(avg(pct_age_25_44), 1) as a25, round(avg(pct_age_45_64), 1) as a45,
               round(avg(pct_age_65_plus), 1) as a65, round(avg(revenue_per_active_listing)) as rev
        from gold.adhoc_lga_demographics
        group by 1""",
    "best": """
        select lga_name as lga, accommodates as guests, total_stays as stays, listings
        from gold.adhoc_best_listing_type""",
    "spread": """
        select case when lgas >= 5 then '5+' else lgas::text end as k,
               count(*) as n, round(avg(listings), 1) as avg_listings
        from gold.adhoc_host_lga_spread
        group by 1
        order by 1""",
    "r": "select correlation as r from gold.adhoc_median_age_vs_revenue limit 1",
    "cover_total": """
        select round(100.0 * sum(hosts_covering) / sum(single_listing_hosts), 1) as p,
               sum(single_listing_hosts) as n
        from gold.adhoc_mortgage_coverage""",
}


def fetch(cur, sql):
    cur.execute(sql)
    cols = [c.name for c in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def main():
    conn = get_connection()
    try:
        cur = conn.cursor()
        data = {name: fetch(cur, sql) for name, sql in QUERIES.items()}
    finally:
        conn.close()

    # single-row results become scalars / objects
    data["r"] = data["r"][0]["r"]
    data["cover_total"] = data["cover_total"][0]
    # simplified ABS ASGS 2016 LGA boundaries (Bayside = Botany Bay + Rockdale)
    data["geo"] = json.loads((HERE / "lga_boundaries.geojson").read_text())

    payload = json.dumps(data, default=lambda v: float(v) if isinstance(v, Decimal) else str(v))
    html = (HERE / "template.html").read_text().replace("__DATA__", payload)
    (HERE / "index.html").write_text(html)
    print(f"Wrote {HERE / 'index.html'} ({len(data['lgas'])} LGAs)")


if __name__ == "__main__":
    main()
