#!/usr/bin/env gnuplot
# Встановити кодування для правильного відображення кирилиці
set encoding utf8

# Встановити термінал та вихідний файл.
# Змінено шрифт на "Arial" для гарантованої підтримки кирилиці.
set terminal pngcairo size 1280,960 enhanced font "Arial,12"
set output 'activity_3D_boxes.png'

# --- Загальні налаштування 3D-графіка ---
set title "3D-візуалізація активності за годинами та днями тижня"
set xlabel "Година дня" offset 0,-2
set ylabel "День тижня" offset 4,0
set zlabel "Рівень активності" offset -2,0
set border 4095
set view 60, 30

# --- Налаштування осей ---
set xrange [9:21]
set xtics 1
set yrange [0.5:7.5]
set ytics ("Неділя" 1, "Понеділок" 2, "Вівторок" 3, "Середа" 4, "Четвер" 5, "П'ятниця" 6, "Субота" 7)
set zrange [0:*]
set ztics 1000
set xyplane at 0

# --- Налаштування стилю боксів ---
set boxwidth 0.7
set boxdepth 0.7
set style fill solid 0.3 border lc '#aaaaaa'
set key outside right top

# --- Команда побудови 3D-графіка (splot) ---

# НОВИЙ РЯДОК: Створюємо рядок з назвами днів для легенди
days = "Неділя Понеділок Вівторок Середа Четвер П'ятниця Субота"

# ВИПРАВЛЕНО: Замість 'title columnheader(i)' тепер використовуємо 'title word(days, i-1)',
# щоб брати назви напряму зі скрипту, а не з файлу.
# Цикл залишається зворотним для правильного порядку відображення.
splot for [i=8:2:-1] 'data/weekly.dat' skip 1 using (column(1)):(i-1):(column(i)) with boxes title word(days, i-1)

