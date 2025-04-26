module SR500Constants

  # Constants used for parsing receipt summary lines.
  TaxableAmount  = "対象計"
  TaxIncluded    = "内税"
  TotalAmountDue = "合  計"
  AmountReceived = "お預り"
  AmountReturned = "お  釣"     # Change or Cash - last line in sinle receipt
  Cash           = "現金"
  Reset          = "＃／替      ････････････" # Is this always line when POS is turned OFF (?? @dmytro)

  # Column headers for generated CSV files
  HEADERS = {
    timestamp:      "Timestamp",
    sequence:       "Order #",
    items:          "PLU",
    taxableamount:  "TaxableAmount /対象計",
    tax_percent:    "Tax  %",
    tax_amount:     "Total Amount",
    taxincluded:    "Tax Included  /内税",
    amountreceived: "Amount Received /お預り",
    amountreturned: "Amount Returned /お釣",
    cash:           "Cash /現金",
  }
end
