
# Markdown to PDF Conversion Script

This document describes a script for converting Markdown files into high-quality PDF documents using Pandoc and XeLaTeX. It is specifically configured for multilingual documents that may include Ukrainian, Japanese, and English text.

---

- [Markdown to PDF Conversion Script](#markdown-to-pdf-conversion-script)
  * [English](#english)
    + [1. Description](#1-description)
    + [2. Prerequisites & Installation (macOS)](#2-prerequisites--installation-macos)
    + [3. The Script (`md2pdf.sh`)](#3-the-script-md2pdfsh)
    + [4. Usage](#4-usage)
  * [Українська](#%D1%83%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0)
    + [1. Опис](#1-%D0%BE%D0%BF%D0%B8%D1%81)
    + [2. Вимоги та встановлення (macOS)](#2-%D0%B2%D0%B8%D0%BC%D0%BE%D0%B3%D0%B8-%D1%82%D0%B0-%D0%B2%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BB%D0%B5%D0%BD%D0%BD%D1%8F-macos)
    + [3. Скрипт (`md2pdf.sh`)](#3-%D1%81%D0%BA%D1%80%D0%B8%D0%BF%D1%82-md2pdfsh)

---

## English

### 1. Description

The `md2pdf.sh` script is a wrapper around the powerful `pandoc` utility. It uses the `xelatex` engine, which allows for advanced font handling, making it ideal for documents with non-Latin characters (like Cyrillic or Japanese).

The script automatically generates the output PDF filename based on the input Markdown filename (e.g., `input.md` becomes `input.pdf`).

### 2. Prerequisites & Installation (macOS)

Follow these steps to set up the necessary environment on your Mac.

**Step 1: Install Homebrew**

If you don't have Homebrew (the package manager for macOS), install it by running this command in your terminal:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Step 2: Install Pandoc and MacTeX**

`MacTeX` is a full LaTeX distribution and is required for the `xelatex` engine. `Pandoc` is the conversion tool.
```bash
brew install pandoc
brew install librsvg
brew install --cask mactex
```
*Note: MacTeX is a large download (over 5 GB).*

**Step 3: Update your PATH**

You need to tell your shell where to find the LaTeX binaries. Add the following line to your shell configuration file (e.g., `~/.zshrc` or `~/.bash_profile`):
```bash
# The year (e.g., 2025) might differ depending on the MacTeX version you installed.
# Check the actual path in /usr/local/texlive/
export PATH="/usr/local/texlive/2025/bin/universal-darwin:$PATH"
```
After adding it, restart your terminal or run `source ~/.zshrc`.

**Step 4: Verify Fonts (Optional)**

The script uses specific fonts. You can check if you have fonts that support certain languages using the fc-list command. For example, to find fonts supporting Ukrainian or Japanese:

```bash

# List fonts with Ukrainian language support
fc-list :lang=uk

# List fonts with Japanese language support
fc-list :lang=ja
```
If a required font is not found, Pandoc will raise an error. You may need to install the font or change it in the script.

Further Reading:
For more details on Pandoc and character encoding, this resource is helpful: 

* [Stack Overflow: Pandoc and foreign characters](https://stackoverflow.com/questions/18178084/pandoc-and-foreign-characters)

### 3. The Script (`md2pdf.sh`)

Here is the reusable script. Save it as `md2pdf.sh` and make it executable with `chmod +x md2pdf.sh`.

```bash
#!/bin/bash

# A script to convert Markdown to PDF with support for multiple languages.
# It automatically determines the output PDF name from the input Markdown file.
#
# Usage: ./md2pdf.sh <input_file.md>

# --- Check for the single required argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file.md>"
    exit 1
fi

INPUT_FILE="$1"
# Automatically create the output filename by replacing .md with .pdf
OUTPUT_FILE="${INPUT_FILE%.md}.pdf"

# --- Run the Pandoc command
pandoc "$INPUT_FILE" \
    --pdf-engine=xelatex \
    -o "$OUTPUT_FILE" \
    -V CJKmainfont="Toppan Bunkyu Gothic" \
    -V mainfont="Times New Roman" \
    -V geometry:"top=1cm, bottom=2cm, left=2cm, right=2cm" \
    -V papersize=a4

# --- Check for success
if [ $? -eq 0 ]; then
    echo "✅ Successfully generated $OUTPUT_FILE"
else
    echo "❌ Failed to generate PDF."
fi
```

### 4. Usage

To convert a Markdown file named `my_document.md`, run the script from your terminal. The output will be automatically named `my_document.pdf`.
```bash
./md2pdf.sh my_document.md
```

---

## Українська

### 1. Опис

Скрипт `md2pdf.sh` — це обгортка для потужної утиліти `pandoc`. Він використовує рушій `xelatex`, що забезпечує розширену роботу зі шрифтами і є ідеальним для документів з нелатинськими символами (наприклад, кирилицею чи японськими ієрогліфами).

Скрипт автоматично генерує ім'я вихідного PDF-файлу на основі імені вхідного Markdown-файлу (наприклад, `input.md` перетвориться на `input.pdf`).

### 2. Вимоги та встановлення (macOS)

Виконайте ці кроки, щоб налаштувати необхідне середовище на вашому Mac.

**Крок 1: Встановлення Homebrew**

Якщо у вас немає Homebrew (менеджера пакунків для macOS), встановіть його, виконавши цю команду в терміналі:
```bash
/bin/bash -c "$(curl -fsSL [https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh))"
```

**Крок 2: Встановлення Pandoc та MacTeX**

`MacTeX` — це повна дистрибуція LaTeX, необхідна для роботи рушія `xelatex`. `Pandoc` — це утиліта для конвертації.
```bash
brew install pandoc
brew install --cask mactex
```
*Примітка: MacTeX — це великий пакет (понад 5 ГБ).*

**Крок 3: Оновлення PATH**

Вам потрібно вказати вашій оболонці, де знаходяться файли LaTeX. Додайте наступний рядок до вашого конфігураційного файлу (наприклад, `~/.zshrc` або `~/.bash_profile`):
```bash
# Рік (напр., 2025) може відрізнятися залежно від версії встановленого MacTeX.
# Перевірте актуальний шлях у /usr/local/texlive/
export PATH="/usr/local/texlive/2025/bin/universal-darwin:$PATH"
```
Після цього перезапустіть термінал або виконайте `source ~/.zshrc`.

**Крок 4: Перевірка шрифтів (опційно)**

Скрипт використовує певні шрифти. Ви можете перевірити наявність шрифтів, що підтримують потрібні мови, за допомогою команди fc-list. Наприклад, щоб знайти шрифти для української чи японської мов:

```bash

# Список шрифтів з підтримкою української мови
fc-list :lang=uk

# Список шрифтів з підтримкою японської мови
fc-list :lang=ja
```

Якщо потрібний шрифт не знайдено, Pandoc видасть помилку. Можливо, вам доведеться встановити шрифт або змінити його назву у скрипті.

**Додаткова інформація:**
Для отримання додаткових відомостей про Pandoc та кодування символів буде корисним цей ресурс:

* [Stack Overflow: Pandoc and foreign characters](https://stackoverflow.com/questions/18178084/pandoc-and-foreign-characters)

### 3. Скрипт (`md2pdf.sh`)

Ось скрипт для багаторазового використання. Збережіть його під назвою `md2pdf.sh` і зробіть виконуваним за допомогою `chmod +x md2pdf.sh`.

```bash
#!/bin/bash

# Скрипт для конвертації Markdown у PDF з підтримкою кількох мов.
# Він автоматично визначає ім'я вихідного PDF-файлу з вхідного.
#
# Використання: ./md2pdf.sh <вхідний_файл.md>

# --- Перевірка наявності єдиного обов'язкового аргументу
if [ "$#" -ne 1 ]; then
    echo "Використання: $0 <вхідний_файл.md>"
    exit 1
fi

INPUT_FILE="$1"
# Автоматично створюємо ім'я вихідного файлу, замінюючи .md на .pdf
OUTPUT_FILE="${INPUT_FILE%.md}.pdf"

# --- Запуск команди Pandoc
pandoc "$INPUT_FILE" \
    --pdf-engine=xelatex \
    -o "$OUTPUT_FILE" \
    -V CJKmainfont="Toppan Bunkyu Gothic" \
    -V mainfont="Times New Roman" \
    -V geometry:"top=1cm, bottom=2cm, left=2cm, right=2cm" \
    -V papersize=a4

# --- Перевірка на успішність виконання
if [ $? -eq 0 ]; then
    echo "✅ Файл $OUTPUT_FILE успішно згенеровано"
else
    echo "❌ Не вдалося згенерувати PDF."
fi
```

### 4. Використання

Щоб перетворити файл `my_document.md`, запустіть скрипт у терміналі. Вихідний файл буде автоматично названо `my_document.pdf`.
```bash
./md2pdf.sh my_document.md
```
