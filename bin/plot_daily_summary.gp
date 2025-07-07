#!/opt/homebrew/bin/gnuplot
# --- Крок 1: Підготовка до запису в тимчасовий файл ---

# Назва тимчасового файлу, куди будуть записані суми
tmp_file = 'temp_data.txt'

# Перенаправити весь вивід команди 'print' у цей файл
set print tmp_file

# --- Крок 2: Обчислити та записати суму для кожного дня ---
# Ми використовуємо стандартну змінну STATS_sum, яка перезаписується
# після кожного виклику 'stats'. Тому ми відразу ж записуємо її у файл.

# Неділя (стовпець 2)
stats 'data/weekly.dat' using 2 nooutput
# Перевіряємо, чи були знайдені числові записи, щоб уникнути помилок
if (STATS_records > 0) { print sprintf("sunday %g", STATS_sum) } else { print "sunday 0" }

# Понеділок (стовпець 3)
stats 'data/weekly.dat' using 3 nooutput
if (STATS_records > 0) { print sprintf("monday %g", STATS_sum) } else { print "monday 0" }

# Вівторок (стовпець 4)
stats 'data/weekly.dat' using 4 nooutput
if (STATS_records > 0) { print sprintf("tuesday %g", STATS_sum) } else { print "tuesday 0" }

# Середа (стовпець 5)
stats 'data/weekly.dat' using 5 nooutput
if (STATS_records > 0) { print sprintf("wednesday %g", STATS_sum) } else { print "wednesday 0" }

# Четвер (стовпець 6)
stats 'data/weekly.dat' using 6 nooutput
if (STATS_records > 0) { print sprintf("thursday %g", STATS_sum) } else { print "thursday 0" }

# П'ятниця (стовпець 7)
stats 'data/weekly.dat' using 7 nooutput
if (STATS_records > 0) { print sprintf("friday %g", STATS_sum) } else { print "friday 0" }

# Субота (стовпець 8)
stats 'data/weekly.dat' using 8 nooutput
if (STATS_records > 0) { print sprintf("saturday %g", STATS_sum) } else { print "saturday 0" }

# Зупинити перенаправлення виводу у файл
set print

# --- Крок 3: Побудувати графік, використовуючи тимчасовий файл ---

# Налаштування графіка
set terminal pngcairo size 1024,768 enhanced font "Verdana,12"
set output 'daily_summary_bars.png'
set title "Сумарна активність за днями тижня"
set ylabel "Загальна сума активності"
set xlabel "День тижня"
set key off
set grid y
set xtics rotate by -45
set style data histograms
set style histogram clustered gap 1
set style fill solid 0.8 border -1
set boxwidth 0.7
set yrange [0:*]

# Побудувати графік з нашого тимчасового файлу
plot tmp_file using 2:xtic(1)

# Можна додати команду для видалення тимчасового файлу після побудови,
# але це залежить від вашої операційної системи.
# Наприклад, для Linux/macOS:
# ; pause -1 ; system("rm temp_data.txt")
