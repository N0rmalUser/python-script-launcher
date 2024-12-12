#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен быть запущен от имени администратора (root)."
    exit 1
fi

SCRIPT1_NAME="start"
SCRIPT2_NAME="stop"

SCRIPT1_CONTENT='#!/bin/bash

function find_main_py_files() {
    local current_dir=$1
    find "$current_dir" -type f -name "main.py" -exec dirname {} \;
}

function start_process() {
    local script_path=$1
    echo "Запуск процесса: python3 $script_path"
    nohup python3 "$script_path" > /dev/null 2>&1 &
    echo "Процесс запущен."
}

root_dir=$(pwd)
dirs_with_main_py=($(find_main_py_files "$root_dir"))

if [ ${#dirs_with_main_py[@]} -eq 0 ]; then
    echo "Не найдено файлов main.py."
    exit 1
fi

selected_dir=$(printf "%s\n" "${dirs_with_main_py[@]}" | fzf --height 50% --border --preview "tree -C {}")
if [ -z "$selected_dir" ]; then
    echo "Выбор не был сделан"
    exit 1
fi

script_path="$selected_dir/main.py"
pid=$(pgrep -f "python3 $script_path")

if [ -n "$pid" ]; then
    choice=$(echo -e "Завершить и запустить заново\nОставить процесс запущенным" | fzf --height 5%)
    if [[ "$choice" == "Завершить и запустить заново" ]]; then
        echo "Завершение процесса с PID: $pid"
        kill -9 "$pid"
        sleep 1
        start_process "$script_path"
    else
        echo "Процесс оставлен работающим."
    fi
else
    echo "Процесс не найден. Запускаем новый."
    start_process "$script_path"
fi
'

SCRIPT2_CONTENT='#!/bin/bash

function find_main_py_files() {
    local current_dir=$1
    find "$current_dir" -type f -name "main.py" -exec dirname {} \;
}

root_dir=$(pwd)
dirs_with_main_py=($(find_main_py_files "$root_dir"))

if [ ${#dirs_with_main_py[@]} -eq 0 ]; then
    echo "Не найдено файлов main.py."
    exit 1
fi

selected_dir=$(printf "%s\n" "${dirs_with_main_py[@]}" | fzf --height 50% --border --preview "tree -C {}")
if [ -z "$selected_dir" ]; then
    echo "Выбор не был сделан"
    exit 1
fi

script_path="$selected_dir/main.py"
pid=$(pgrep -f "python3 $script_path")

if [ -n "$pid" ]; then
    kill -9 "$pid"
    echo "Процесс с PID $pid завершён"
else
    echo "Процесс для $script_path не найден."
fi
'

mkdir -p /usr/local/bin
echo "$SCRIPT1_CONTENT" > /usr/local/bin/$SCRIPT1_NAME
chmod +x /usr/local/bin/$SCRIPT1_NAME
echo "$SCRIPT2_CONTENT" > /usr/local/bin/$SCRIPT2_NAME
chmod +x /usr/local/bin/$SCRIPT2_NAME

if [[ -x /usr/local/bin/$SCRIPT1_NAME && -x /usr/local/bin/$SCRIPT2_NAME ]]; then
    echo "Скрипты успешно установлены в /usr/local/bin и готовы к использованию."
else
    echo "Произошла ошибка при установке скриптов."
    exit 1
fi
