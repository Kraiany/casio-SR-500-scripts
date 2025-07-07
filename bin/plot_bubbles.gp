#!/usr/bin/env gnuplot
# Встановити кодування для правильного відображення кирилиці у графіку
set encoding utf8

# Встановити термінал та вихідний файл
set terminal pngcairo size 1024,768 enhanced font "Verdana,12"
set output 'activity_bubbles.png'

# --- Налаштування графіка ---
set title "Годинна активність протягом тижня"
set xlabel "День тижня"
set ylabel "Година дня"
set xrange [0.5:7.5]
set xtics ("Неділя" 1, "Понеділок" 2, "Вівторок" 3, "Середа" 4, "Четвер" 5, "П'ятниця" 6, "Субота" 7)
set yrange [21:9]
set grid ytics
SCALE_FACTOR = 750.0
set style data points
set key outside right top

# --- Команда побудови графіка (з ручними заголовками) ---

# Створюємо рядок з назвами днів, розділеними пробілом
days = "Неділя Понеділок Вівторок Середа Четвер П'ятниця Субота"

# ВИПРАВЛЕНО: Замість 'title columnheader(i)' використовуємо 'title word(days, i-1)'
# word(days, i-1) бере (i-1)-е слово з рядка 'days'
plot for [i=2:8] 'data/weekly.dat' skip 1 using (i-1):(column(1)):(column(i)/SCALE_FACTOR) with points pt 7 ps var title word(days, i-1)

