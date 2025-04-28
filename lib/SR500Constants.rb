module SR500Constants

  # Constants used for parsing receipt summary lines.
  TaxableAmount  = '対象計'
  TaxIncluded    = '内税'
  TotalAmountDue = '合  計'
  AmountReceived = 'お預り'
  Cancellation   = '訂正'
  AmountReturned = 'お  釣'     # Change or Cash - last line in sinle receipt
  Cash           = '現金'
  Reset          = '＃／替      ････････････' # Is this always line when POS is turned OFF (?? @dmytro)

  # Column headers for generated CSV files
  HEADERS = {
    timestamp:      'Timestamp',
    sequence:       'Order #',
    items:          'PLU',
    taxableamount:  'TaxableAmount /対象計',
    tax_percent:    'Tax  %',
    tax_amount:     'Total Amount /合計',      # (ごうけい - gōkei)
    taxincluded:    'Tax Included  /内税',
    amountreceived: 'Amount Received /お預り', # お預り (おあずかり - oazukari)
    amountreturned: 'Amount Returned /お釣',   # お釣 (おつり - otsuri) -- End of receipt
    cash:           'Cash /現金',              # 現金 (げんきん - genkin) -- End of receipt
    cancellation:   'Cancel /訂正'             # 訂正 (ていせい - teisei)
  }
end
