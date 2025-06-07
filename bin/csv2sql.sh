#!/usr/bin/env bash

# Script to load CSV result files from SR-500 orders and items into sqlite3 DB.

# --- Функція для виводу інструкції з використання ---
usage() {
  echo "Usage: $0 [OPTIONS] orders_file.csv items_file.csv"
  echo
  echo "Correct syntax requires options (like -d) to be placed before file arguments."
  echo
  echo "Arguments:"
  echo "  orders_file.csv    CSV file containing order data."
  echo "  items_file.csv     CSV file containing item data."
  echo
  echo "Options:"
  echo "  -d DATABASE_FILE   Specify the SQLite database file (default: casio-sr500.db)."
  echo "  -h                 Display this help message."
  exit 1
}

# --- Значення за замовчуванням для файлу БД ---
DB_FILE="casio-sr500.db"

# --- Обробка опцій командного рядка ---
while getopts ":d:h" opt; do
  case ${opt} in
    d)
      DB_FILE="$OPTARG"
      ;;
    h)
      usage
      ;;
    \?)
      echo "Error: Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

# --- ПЕРЕВІРКА КІЛЬКОСТІ АРГУМЕНТІВ (НОВА ЧАСТИНА) ---
# Після обробки опцій має залишитися рівно два аргументи.
if [ "$#" -ne 2 ]; then
    echo "Error: Incorrect number of arguments." >&2
    echo "Please provide exactly two CSV file paths after all options." >&2
    echo
    usage
fi

# --- Призначення та перевірка файлів CSV ---
order_file=$1
items_file=$2

if [ ! -f "${order_file}" ]; then
    echo "Error: Order file not found at: ${order_file}" >&2
    exit 1
fi

if [ ! -f "${items_file}" ]; then
    echo "Error: Items file not found at: ${items_file}" >&2
    exit 1
fi

echo "Using database: ${DB_FILE}"

# --- Створення таблиць, якщо вони не існують ---
sqlite3 "${DB_FILE}" <<EOF
  CREATE TABLE IF NOT EXISTS
  orders (
    key STRING PRIMARY_KEY NOT NULL,
    timestamp     DATETIME,
    date          DATE,
    time          TIME,
    hour          INT,
    sequence      INT,
    items_str     STRING,
    tax_percent   INT,
    total_amount  INT,
    taxableamount STRING,
    taxincluded   INT,
    amountreceived INT,
    cash          INT,
    change        INT
  );

  CREATE TABLE IF NOT EXISTS
  items (
    key STRING PRIMARY_KEY NOT NULL,
    timestamp     DATETIME,
    sequence      INT,
    product       STRING,
    price         INT
  );
EOF

# --- Імпорт даних ---
echo "Importing orders from ${order_file}..."
awk 'NR > 1' "${order_file}" | sqlite3 -csv "${DB_FILE}" ".import /dev/stdin orders"

echo "Importing items from ${items_file}..."
awk 'NR > 1' "${items_file}" | sqlite3 -csv "${DB_FILE}" ".import /dev/stdin items"

echo "✅ Data import completed successfully."
