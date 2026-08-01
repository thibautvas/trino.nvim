import csv
import json
import sys

import trino


def build_auth(cfg):
    auth_cfg = cfg.get("auth", {})
    auth_type = auth_cfg.get("type", "none")

    if auth_type == "none":
        return None

    if auth_type == "basic":
        try:
            return trino.auth.BasicAuthentication(
                username=auth_cfg["username"],
                password=auth_cfg["password"],
            )
        except KeyError as exc:
            raise Exception(f"auth.basic requires field: {exc}") from exc

    if auth_type == "jwt":
        try:
            return trino.auth.JWTAuthentication(auth_cfg["jwt_token"])
        except KeyError as exc:
            raise Exception(f"auth.jwt requires field: {exc}") from exc

    if auth_type == "oauth2":
        return trino.auth.OAuth2Authentication()

    raise Exception(f"unsupported auth.type: {auth_type!r}")


def normalize_http_headers(cfg):
    headers = cfg.get("http_headers")
    if not isinstance(headers, dict):
        return {}
    return {k: v for k, v in headers.items() if v is not None}


def get_connection(cfg):
    required = ["host", "port", "catalog"]
    missing = [k for k in required if k not in cfg]
    if missing:
        raise Exception(f"missing config field(s): {', '.join(missing)}")

    return trino.dbapi.connect(
        host=cfg["host"],
        port=cfg["port"],
        catalog=cfg["catalog"],
        http_headers=normalize_http_headers(cfg),
        http_scheme=cfg.get("http_scheme", "https"),
        auth=build_auth(cfg),
        verify=cfg.get("verify", False),
    )


def stream_csv(curs, out):
    """
    Write the header as soon as it's known, then stream rows in
    batches so the caller starts seeing output before the full
    result set has landed, and memory use stays bounded.
    """
    columns = [d[0] for d in curs.description]
    out.reconfigure(newline="")
    writer = csv.writer(out, lineterminator="\n")
    writer.writerow(columns)

    while True:
        batch = curs.fetchmany(1000)
        if not batch:
            break
        writer.writerows(batch)
        out.flush()


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read())
    except json.JSONDecodeError as exc:
        print(f"invalid JSON payload: {exc}", file=sys.stderr)
        return 2

    sql = payload.get("sql", "")
    cfg = payload.get("config", {})

    if not sql.strip():
        print("no SQL provided", file=sys.stderr)
        return 1

    try:
        conn = get_connection(cfg)
    except Exception as exc:
        print(f"config error: {exc}", file=sys.stderr)
        return 2

    try:
        with conn:
            with conn.cursor() as curs:
                curs.execute(sql)
                stream_csv(curs, sys.stdout)
        return 0
    except trino.exceptions.TrinoUserError as exc:
        print(f"query error: {exc}", file=sys.stderr)
        return 3
    except trino.exceptions.TrinoConnectionError as exc:
        print(f"connection error: {exc}", file=sys.stderr)
        return 4
    except Exception as exc:
        print(f"unexpected error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
