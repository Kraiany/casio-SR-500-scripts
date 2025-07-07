#!/usr/bin/env bash

# Скрипт для виконання SQL-запиту до бази даних sqlite3
# з можливістю вибору формату виводу.

# --- Функція для виводу інструкції з використання ---
usage() {
  echo "Usage: $0 [OPTIONS] database_file sql_file"
  echo
  echo "Executes a SQL query on a specified SQLite database."
  echo
  echo "Arguments:"
  echo "  database_file    Path to the SQLite database file."
  echo "  sql_file         Path to the file containing the SQL query to execute."
  echo
  echo "Options:"
  echo "  -m MODE          Set the output mode. Default is 'table'."
  echo "                   Allowed modes: ascii, box, column, csv, html, insert, json,"
  echo "                   line, list, markdown, qbox, quote, table, tabs, tcl."
  echo "  -q               Quiet mode. Suppress header information, print only query output."
  echo "  -h               Display this help message."
  exit 1
}

# --- Значення за замовчуванням ---
MODE="table"
QUIET_MODE=0 # 0=false, 1=true

# --- Обробка опцій командного рядка ---
while getopts ":m:qh" opt; do
  case ${opt} in
    m)
      # Перевірка, чи вказаний режим є допустимим
      case "$OPTARG" in
        ascii|box|column|csv|html|insert|json|line|list|markdown|qbox|quote|table|tabs|tcl)
          MODE="$OPTARG"
          ;;
        *)
          echo "Error: Invalid mode '$OPTARG' for option -m." >&2
          usage
          ;;
      esac
      ;;
    q)
      QUIET_MODE=1
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

# --- Перевірка наявності двох обов'язкових аргументів ---
if [ "$#" -ne 2 ]; then
    echo "Error: Please provide exactly two arguments: a database file and a SQL file." >&2
    echo "Note: Options (like -m or -q) must come before file arguments." >&2
    echo
    usage
fi

DB_FILE=$1
SQL_FILE=$2

# --- Перевірка, чи існують файли ---
if [ ! -f "${DB_FILE}" ]; then
    echo "Error: Database file not found at: ${DB_FILE}" >&2
    exit 1
fi

if [ ! -r "${SQL_FILE}" ]; then
    echo "Error: SQL file not found or is not readable at: ${SQL_FILE}" >&2
    exit 1
fi

# --- Вивід преамбули, якщо не ввімкнено тихий режим ---
if [ "${QUIET_MODE}" -eq 0 ]; then
  echo "Database:    ${DB_FILE}"
  echo "Query file:  ${SQL_FILE}"
  echo "Output mode: ${MODE}"
  echo "---"
fi

# --- Виконання основного запиту (виправлений, правильний спосіб) ---
sqlite3 "${DB_FILE}" ".mode ${MODE}" ".read ${SQL_FILE}"
