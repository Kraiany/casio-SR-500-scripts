#!/opt/homebrew/bin/gnuplot
# Встановити термінал та вихідний файл
set terminal pngcairo size 1024,768 enhanced font "Verdana,12"
set output 'activity_by_day_bars.png'

# Встановити заголовок графіка та мітки осей
set title "Годинна активність за днями тижня"
set xlabel "Година дня"
set ylabel "Рівень активності"

# Налаштувати легенду (ключ)
set key outside right top

# Встановити сітку по осі Y
set grid y

# Встановити стиль даних для гістограми
set style data histograms

# Встановити стиль гістограми (кластеризована)
set style histogram clustered gap 1

# Встановити стиль заповнення для стовпців
set style fill solid 0.8 border -1
set boxwidth 0.9

# Вказати, як обробляти пропущені дані
set datafile missing ""

# Побудувати графік
# Використовуємо xtic(1) для отримання міток осі X з першого стовпця
plot for [i=2:8] 'data/weekly.dat' using i:xtic(1) title columnheader(i)
