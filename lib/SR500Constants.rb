module SR500Constants

  # Constants used for parsing receipt summary lines.
  TaxableAmount     = '対象計'
  TaxIncluded       = '内税'
  TotalAmountDue    = '合  計'
  AmountReceived    = 'お預り'                   # お預り (おあずかり)
  Cancellation      = '訂正'
  Change            = 'お  釣'                   # Change or Cash - last line in sinle receipt
  Cash              = '現金'                     # 現金 (げんきん - genkin) -- NOT always End of receipt
  DrawerOpen        = '＃／替      ････････････' # POS opened, drawer opened
  SharpSlashKae   = '＃／替'                     # sharp-slash-kae - see
                                                 # README_EJ_FORMAT.md for explanation
  Return            = '戻          ････････････' # もど - modo, Return/Refund
  OrderCancellation = '取引中止'                 # 取引中止 (とりひきちゅうし - torihiki chūshi)
  Settlement        = '精算'                     # 精算 (せいさん - seisan)
  Receipt           = '領収書'                   # Ryōshū-sho
  DailyReport       = '日計明細'                 # Nikkei meisai

  Yen               = '￥'

  # 2025-03-31 12:32 - timestamp format
  Timestamp         = Regexp.new(/^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}$/)

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
    change:         'Change /お釣',   # お釣 (おつり - otsuri) -- End of receipt
    cash:           'Cash /現金',              # 現金 (げんきん - genkin) -- End of receipt
    cancellation:   'Cancel /訂正'             # 訂正 (ていせい - teisei)
  }
end

# 領収書 - (りょうしゅうしょ - ryōshūsho) -- receipt

__END__

Examples
-----------

************************ Drawer opened example

     2025-04-01 09:33
                  000003
＃／替      ････････････


************************ Найбільш вживаний приклад - нормальний чек без повернень

     2025-04-01 14:24
                  000004
Coffee/Te         ￥550
対象計      10.0%   ￥550
内税                 ￥50
合  計          ￥550
お預り          ￥550
お  釣              ￥0

************************ Ryōshū-sho

     2025-04-05 11:47
                  000007
           一連No.000006
           領収No.000001
領収書      ￥3,470
