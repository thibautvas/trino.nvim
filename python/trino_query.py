import sys
import csv


def write_csv(file, columns, rows):
    writer = csv.writer(file)
    writer.writerow(columns)
    writer.writerows(rows)


def main() -> int:
    sql = sys.stdin.read()

    if not sql.strip():
        print("No SQL provided.", file=sys.stderr)
        return 1

    try:
        columns, rows = (
            ["id", "name", "email"],
            [
                (1, "Alice", "alice@placeholder.com"),
                (2, "Bob", "bob@placeholder.com"),
            ],
        )  # dummy output for testing
        write_csv(sys.stdout, columns, rows)
        return 0

    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
