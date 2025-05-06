module SR500Constants

  # Constants used for parsing receipt summary lines.
  TaxableAmount     = '対象計'
  TaxIncluded       = '内税'
  TotalAmountDue    = '合  計'
  AmountReceived    = 'お預り'  # お預り (おあずかり)
  Cancellation      = '訂正'
  AmountReturned    = 'お  釣'     # Change or Cash - last line in sinle receipt
  Cash              = '現金'       # 現金 (げんきん - genkin) -- NOT always End of receipt
  Reset             = '＃／替      ････････････' # Line when POS is turned OFF/ON (?? @dmytro)
  OrderCancellation = '取引中止' # 取引中止 (とりひきちゅうし - torihiki chūshi)
  Settlement        = '精算' # 精算 (せいさん - seisan)
  Receipt           = '領収書'  # Ryōshū-sho


  # Column headers for generated CSV files
  HEADERS = {
    timestamp:      'Timestamp',
    date:           'Date',
    time:           'Time',
    hour:            'Hour',
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

# 領収書 - (りょうしゅうしょ - ryōshūsho) -- receipt
