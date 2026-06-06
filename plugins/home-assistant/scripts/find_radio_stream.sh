#!/bin/bash

# Перевірка аргументів
if [ $# -eq 0 ]; then
    echo "Використання: $0 \"назва радіостанції\""
    exit 1
fi

RADIO_NAME="$1"
SEARCH_QUERY=$(echo "$RADIO_NAME radio direct stream" | sed 's/ /+/g')

# Тимчасова директорія для результатів
TEMP_DIR=$(mktemp -d)
OUTPUT_FILE="$TEMP_DIR/radio_streams.txt"

# Пошук через DuckDuckGo (більш privacy-friendly)
curl -s "https://duckduckgo.com/html/?q=$SEARCH_QUERY" | \
    grep -Eo 'http[s]?://[^"]*(mp3|aac|stream)[^"]*' | \
    sort | uniq > "$OUTPUT_FILE"

# Перевірка знайдених URL
echo "Перевірка знайденихstream URL:"
while read -r url; do
    echo "Перевірка: $url"
    response=$(curl -sI "$url" 2>/dev/null | head -n 1)
    content_type=$(curl -sI "$url" 2>/dev/null | grep -i "content-type:")
    
    if [[ "$response" == *"200 OK"* ]] && [[ "$content_type" == *"audio/mpeg"* ]]; then
        echo "✅ Придатний stream: $url"
        
        # Збереження у файл придатних stream
        echo "$url" >> "$TEMP_DIR/working_streams.txt"
    else
        echo "❌ Не підходить: $url"
    fi
done < "$OUTPUT_FILE"

# Показати придатні stream
if [ -f "$TEMP_DIR/working_streams.txt" ]; then
    echo "Придатні stream URLs:"
    cat "$TEMP_DIR/working_streams.txt"
else
    echo "Не знайдено придатних stream URLs"
fi

# Прибирання тимчасових файлів
rm -rf "$TEMP_DIR"