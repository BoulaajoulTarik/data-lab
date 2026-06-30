import io
import os
from datetime import datetime, timezone

import boto3
import pandas as pd
from botocore.client import Config

BUCKET = os.environ.get("S3_BUCKET", "demo-data")
PREFIX = "readings/"


def _client():
    return boto3.client(
        "s3",
        endpoint_url=os.environ["AWS_ENDPOINT_URL"],
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
        region_name=os.environ.get("AWS_DEFAULT_REGION", "us-east-1"),
        config=Config(signature_version="s3v4"),
    )


def run_ingest(rows: int = 1000) -> dict:
    now = datetime.now(timezone.utc)
    df = pd.DataFrame({
        "ts": pd.date_range(end=now, periods=rows, freq="1min"),
        "sensor_id": [f"sensor-{i % 10:02d}" for i in range(rows)],
        "temperature_c": [round(20 + (i % 15) * 0.5, 1) for i in range(rows)],
        "humidity_pct": [round(45 + (i % 30), 1) for i in range(rows)],
    })

    buf = io.BytesIO()
    df.to_parquet(buf, index=False, engine="pyarrow")
    buf.seek(0)

    key = PREFIX + now.strftime("%Y/%m/%d/%H-%M-%S.parquet")
    _client().put_object(Bucket=BUCKET, Key=key, Body=buf.getvalue())

    return {"file": key, "rows": rows, "written_at": now.isoformat()}


def get_summary() -> dict:
    try:
        s3 = _client()
        paginator = s3.get_paginator("list_objects_v2")
        objects = [
            obj
            for page in paginator.paginate(Bucket=BUCKET, Prefix=PREFIX)
            for obj in page.get("Contents", [])
        ]
        latest = max((o["LastModified"] for o in objects), default=None)
        return {
            "bucket": BUCKET,
            "files": len(objects),
            "total_bytes": sum(o["Size"] for o in objects),
            "latest_upload": latest.isoformat() if latest else None,
        }
    except Exception as e:
        return {"bucket": BUCKET, "files": 0, "total_bytes": 0, "error": str(e)}
