#!/usr/bin/env bash

# Script to load CSV result files from SR-500 orders and items into sqlite3 DB.

order_file=$1
items_file=$2

[ -z "${items_file}" ] && { echo "Usage: $0 orders_file.csv items_file.csv"; exit 1; }

DB=casio-sr500.db

sqlite3 $DB <<EOF
    CREATE TABLE IF NOT EXISTS
    orders (
      key STRING PRIMARY_KEY NOT NULL,
      timestamp      DATETIME,
      date           DATE,
      time           TIME,
      hour           INT,
      sequence       INT,
      items_str      STRING,
      tax_percent    INT,
      total_amount   INT,
      taxableamount  STRING,
      taxincluded    INT,
      amountreceived INT,
      cash           INT,
      change         INT
    );

    CREATE TABLE IF NOT EXISTS
    items (
      key STRING PRIMARY_KEY NOT NULL,
      timestamp      DATETIME,
      sequence       INT,
      product        STRING,
      price          INT
    );
EOF

awk 'NR != 1 {print $0}' < $order_file > temp
printf ".mode csv\n.import temp orders\n" | sqlite3 $DB

awk 'NR != 1 {print $0}' < $items_file > temp
printf ".mode csv\n.import temp items\n" | sqlite3 $DB

rm -f temp
