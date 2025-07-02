# Casio SR-500 Electronic Journal (EJ) Format Documentation

This document describes the various receipt formats found in the Casio SR-500 Electronic Journal (EJ) files.

- [Basic Receipt Structure](#basic-receipt-structure)
- [Receipt Types](#receipt-types)
  * [1. Standard Sale Receipt](#1-standard-sale-receipt)
  * [2. Cash Payment Receipt](#2-cash-payment-receipt)
  * [3. Multiple Items Receipt](#3-multiple-items-receipt)
  * [4. Receipt with Change](#4-receipt-with-change)
  * [5. Receipt with Split Tax Lines](#5-receipt-with-split-tax-lines)
  * [6. Receipt with Return/Cancellation](#6-receipt-with-returncancellation)
  * [7. Official Receipt (領収書 - ryōshū-sho)](#7-official-receipt-%E9%A0%98%E5%8F%8E%E6%9B%B8---ryoshu-sho)
  * [8. Drawer Open Record (＃／替 - kai)](#8-drawer-open-record-%EF%BC%83%EF%BC%8F%E6%9B%BF---kai)
  * [9. Daily Summary (日計明細 - nikkei meisai)](#9-daily-summary-%E6%97%A5%E8%A8%88%E6%98%8E%E7%B4%B0---nikkei-meisai)
  * [10. Unknown case.](#10-unknown-case)
- [Special Markers](#special-markers)
- [File Format](#file-format)
- [Data Fields](#data-fields)
- [Notes](#notes)

## Basic Receipt Structure

Each receipt in the EJ file follows this basic structure:
```
      YYYY-MM-DD HH:MM
                  XXXXXX
[Items and amounts...]
対象計     10.0% ￥XXXX
内税             ￥XXX
合  計           ￥XXXX
[Payment and change...]
```

## Receipt Types

### 1. Standard Sale Receipt
Most common type of receipt showing a sale with tax calculation.

Example:
```
     2025-04-04 11:14
                  000005
Varenyky          ￥770
Deruny            ￥880
対象計      10.0% ￥1,650
内税              ￥150
合  計            ￥1,650
お預り            ￥2,000
お  釣            ￥350
```

### 2. Cash Payment Receipt
Receipt showing cash payment without change.

Example:
```
     2025-04-04 15:30
                  000012
Lunch A           ￥1,600
対象計      10.0%  ￥1,600
内税               ￥145
現金               ￥1,600
```

### 3. Multiple Items Receipt
Receipt with multiple items and larger amounts.

Example:
```
     2025-04-05 18:08
                  000022
Borshch           ￥1,100
Grechanyky        ￥1,650
Mlyntsi           ￥1,100
Varenyky          ￥770
Varenyky          ￥770
Beer              ￥770
Beer              ￥770
Lemonade          ￥660
対象計      10.0% ￥7,590
内税              ￥690
現金              ￥7,590
```

### 4. Receipt with Change
Receipt showing payment with change returned.

Example:
```
     2025-04-05 16:03
                  000016
Lunch A           ￥1,600
対象計      10.0% ￥1,600
内税              ￥145
合  計            ￥1,600
お預り            ￥10,000
お  釣            ￥8,400
```

### 5. Receipt with Split Tax Lines
Receipt where the tax amount is split across two lines, typically for larger amounts.

Example:
```
     2025-04-12 15:50
                  000011
Beer              ￥770
Beer              ￥770
Beer              ￥770
Beer              ￥770
Beer              ￥770
Beer              ￥770
Lemonade          ￥660
Juice             ￥550
Varenyky          ￥770
Varenyky          ￥770
Varenyky          ￥770
Varenyky          ￥770
Deruny            ￥880
Grechanyky      ￥1,650
Chicken Kyiv    ￥1,650
Mlyntsi         ￥1,100
Lin.Varenyky    ￥1,320
対象計      10.0%
                 ￥15,510
内税              ￥1,410
合  計    ￥15,510
お預り    ￥15,510
```

### 6. Receipt with Return/Cancellation
Receipt showing an item return or cancellation. This type of receipt follows a specific format to record the reversal of a transaction. The receipt shows both the original item and its return, with special markers to indicate the type of reversal.

Format Structure:
1. Original item with positive amount
2. Return marker (`戻`) with dots (optional)
3. Same item with negative amount or direct correction
4. Correction marker (`訂正`) with the total correction amount
5. Tax calculation based on the final amount (if applicable)
6. Payment information

The return process can be indicated in several ways:

1. With `戻` marker:
   - `戻` (modori) marker with dots (`･･･････････`) to indicate a return operation
   - Negative amount for the returned item
   - `訂正` (teisei) marker showing the total correction amount
   - Tax is recalculated based on the final amount after the return

2. Direct correction:
   - Original item with positive amount
   - `訂正` (teisei) marker with negative amount
   - No tax calculation (amount becomes zero)
   - Payment amount of zero

3. Partial return with payment adjustment:
   - Multiple items with positive amounts
   - Tax calculation for total amount
   - Initial payment amount
   - Correction with negative amount
   - New payment amount and change

4. Multiple item corrections:
   - Multiple items with positive amounts
   - Multiple `訂正` lines for each returned item
   - Tax calculation for remaining items
   - Final payment amount

5. Payment method correction:
   - Original payment method and amount
   - `訂正` with negative amount
   - New payment method and amount

Example 1 (with `戻` marker):
```
     2025-04-22 13:19
                  000007
Bread               ￥220
戻          ････････････
Bread              -220
訂正                ￥220
対象計      10.0%   ￥220
内税                ￥20
現金                ￥220
```

Example 2 (direct correction):
```
     2025-04-13 15:10
                  000009
Set A            ￥3,850
訂正              -3,850
現金                ￥0
```

Example 3 (partial return with payment adjustment):
```
     2025-04-15 13:55
                  000011
Bread             ￥220
Bread             ￥220
Bread             ￥220
Bread             ￥220
Lunch A           ￥1,600
対象計      10.0% ￥2,480
内税              ￥225
合  計            ￥2,480
現金              ￥2,400
訂正              -2,400
お預り            ￥2,500
お  釣            ￥20
```

Example 4 (multiple item corrections):
```
     2025-04-19 16:27
                  000021
Golubtsi          ￥880
訂正                -880
Varenyky          ￥770
訂正                -770
Easter Cake S     ￥2,000
対象計      10.0% ￥2,000
内税              ￥182
合  計            ￥2,000
お預り            ￥2,000
お  釣            ￥0
```

Example 5 (payment method correction):
```
     2025-03-30 15:31
                  000016
Ukr.Wine 4        ￥5,500
Ukr.Wine 4        ￥5,500
対象計      10.0%
                  ￥11,000
内税              ￥1,000
合  計            ￥11,000
現金              ￥10,000
訂正             -10,000
現金              ￥11,000
```

Note: Returns can be partial (returning some items from a multi-item receipt) or complete (returning all items). The tax calculation always reflects the final amount after all returns are processed. For complete cancellations, the payment amount becomes zero. In partial returns, the payment amount may be adjusted and change may be given. Payment method corrections can occur when the initial payment method or amount needs to be changed.

### 7. Official Receipt (領収書 - ryōshū-sho)
Official receipt format with additional reference numbers.

Example:
```
     2025-04-05 11:47
                  000007
           一連No.000006
           領収No.000001
領収書      ￥3,470
```

### 8. Drawer Open Record (＃／替 - kai)
Record of cash drawer opening.

Example:
```
     2025-04-05 09:29
                  000003
＃／替      ････････････
```

### 8a. Drawer open with return (???)


Example in EJ250622.TXT


```
 14      2025-06-22 13:48
 15                   000005
 16 Lunch A         ￥1,600
 17 対象計      10.0% ￥1,600
 18 内税                ￥145
 19 合  計      ￥1,600
 20 お預り      ￥2,000
 21 お  釣          ￥400
 22 戻   2025-06-22 13:58
 23                   000006
 24 ＃／替      ････････････
```
```
戻   2025-06-22 13:58
                  000006
＃／替      ････････････
```

### 9. Daily Summary (日計明細 - nikkei meisai)
End of day summary report.

Example:
```
精算 2025-04-05 20:43
                  000027
0000 日計明細     Z 0049
総売               49 点
                 ￥49,920
純売               16 件
                 ￥49,920
現金在高          ￥49,920
対象計            ￥49,920
内税        10.0% ￥4,537
消費税合計         ￥4,537
領収書              1 件
                  ￥3,470
純客               16 名
------------------------
日計明細
SDｶｰﾄﾞ保存      正常終了
精算は正常に終了しました
が、ｽﾏ-ﾄﾌｫﾝへのﾃﾞｰﾀ送信
に失敗しました。ﾃﾞｰﾀはSD
ｶｰﾄﾞへﾊﾞｯｸｱｯﾌﾟしました。
ﾊﾞｯｸｱｯﾌﾟﾃﾞｰﾀは次回の精算
時に自動送信されます。
```

### 10. Unknown case.

(DK:) I don't know how to precess the follwoing case, and what is the
meanint of it.

File: `EJ250422.TXT`

```
      2025-04-22 13:19
                  000007
Bread             ￥220
戻          ････････････
Bread             -220
訂正              ￥220
対象計      10.0% ￥220
内税              ￥20
現金              ￥220
```

## Special Markers

1. `対象計` (taishō-kei) - Taxable amount
2. `内税` (nai-zei) - Internal tax
3. `合  計` (gō-kei) - Total amount
4. `お預り` (o-azukari) - Amount received
5. `お  釣` (o-tsuri) - Change
6. `現金` (genkin) - Cash payment
7. `＃／替` (kai) - Drawer open
8. `領収書` (ryōshū-sho) - Official receipt
9. `精算` (seisan) - Settlement/End of day
10. `戻` (modori) - Return
11. `訂正` (teisei) - Correction

## File Format

- Files are named in the format `EJYYMMDD.TXT` (e.g., `EJ250405.TXT` for April 5, 2025)
- Each receipt is separated by timestamps
- Original files are in Shift-JIS encoding with Japanese characters
  - Files are automatically converted to UTF-8 by the JPEncodingFile class
- Line endings: CRLF
- Currency symbol: ￥ (Japanese Yen)

## Data Fields

1. Timestamp: `YYYY-MM-DD HH:MM`
2. Receipt Number: 6-digit number
3. Items: Name and price pairs
4. Tax Information: Rate and amount
   - May appear as a single line or split across multiple lines
   - When split, the taxable amount appears on a separate line
   - The tax amount is shown on a single line
   - Tax rates can be either 10% (dine-in) or 8% (takeout)
5. Payment Information: Method and amount
6. Change: Amount returned
7. Returns/Corrections:
   - Marked with `戻` (return) or `訂正` (correction)
   - Negative amounts shown with a minus sign
   - Original item and return amount shown separately

## Notes

- All monetary values are in Japanese Yen (￥)
- Tax rates:
  - 10% for dine-in items (most common in current data)
  - 8% for takeout items (not present in current data but supported by the system)
- Receipt numbers are sequential within each day
- Some receipts may include additional information like official receipt numbers
- End of day reports include summary statistics and system status messages
- For large amounts, the taxable amount may be split onto a separate line
- When parsing split lines, look for the amount on the line following
  the `対象計` line


### Understanding ＃／替 (Sharp / Kae)

The term **＃／替** (pronounced similar to "sharp-slash-kae") on your Casio SR-500's EJ (Electronic Journal) entry most likely represents a **"Cash Change Amount"** or **"Cash Tendered for Change Calculation."**

Let's break down why:

* **＃ (Hash/Number Sign):** As discussed before, this often signifies an internal reference or a distinct numerical value.
* **／ (Slash):** Acts as a separator, possibly between a category and its value.
* **替 (かえ - *kae*):** This character is a common abbreviation for **釣銭 (お釣り - *otsuri*)**, meaning **"Change"** (the money returned to the customer).

**In your EJ entry:**

```
Borshch           ￥1,100
Varenyky            ￥770
Grechanyky        ￥1,650
＃／替              1020   <--- This line
対象計    10.0% ￥3,520
内税                ￥320
現金            ￥3,520
```

Here's the breakdown of what these lines collectively indicate:

1.  **Total Sales:** The items (Borshch, Varenyky, Grechanyky) sum up to `￥3,520`.
2.  **`対象計 10.0% ￥3,520`**: This confirms the taxable subtotal is `￥3,520`.
3.  **`内税 ￥320`**: This indicates `￥320` of that total is consumption tax (tax-included price).
4.  **`現金 ￥3,520`**: This shows the **customer paid exactly `￥3,520` in cash.**

**The `＃／替 1020` line's role:**

Since the `現金` line already confirms the customer paid the exact total (`￥3,520`), the `＃／替 1020` cannot be the actual change returned to the customer in this specific transaction (because there was no change).

Instead, it's highly probable that this line represents the **amount of cash tendered by the customer that was *intended* for change calculation, or an internal calculation related to the cash drawer, but it ended up being an exact payment.**

* **English Translations for ＃／替:**
    * **Cash Tendered for Change** (most likely)
    * **Change Calculation Input**
    * **Cash Received for Change**
    * **Internal Cash Change Value**

* **Українські Переклади для ＃／替:**
    * **Сума готівки, внесена для розрахунку решти** (найімовірніше)
    * **Вхідні дані для розрахунку решти**
    * **Отримана готівка для решти**
    * **Внутрішнє значення готівкової решти**

**Why does this happen?**

Even if a customer pays the exact amount, some POS systems might still register the act of the cashier receiving cash and preparing for a change calculation before confirming it's an exact payment. `＃／替` here might be a log of the cash *received* for the purpose of giving change, even if the change turned out to be zero.

To be absolutely certain, cross-referencing this specific line in your Casio SR-500's detailed manual (especially sections on cash operations, EJ data format, or error handling) would confirm its exact programmed purpose.
