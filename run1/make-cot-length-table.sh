#!/bin/bash

mkdir -p best-stats-cot

LOG_PATH=log

mode=bare

get_acc() {
    local stats_file=$1
    acc="$(cat $stats_file | perl -ne '/^Accuracy: ([\d.]+)/ && print $1')"
}

get_wc() {
    local stats_file=$1
    #wc=$(cat $stats_file | perl -ne '/^Total samples: (\d+)/ && print $1')
    wc=$(cat $stats_file | perl -ne 'if(/^Total samples: (\d+)/) {print $1;last}')
}

get_len() {
    local stats_file=$1
    #wc=$(cat $stats_file | perl -ne '/^Total samples: (\d+)/ && print $1')
    len=$(cat $stats_file | perl -ne 'if(/^CoT length: (\d+)/) {print $1;last}')
}

get_lenw() {
    local stats_file=$1
    #wc=$(cat $stats_file | perl -ne '/^Total samples: (\d+)/ && print $1')
    lenw=$(cat $stats_file | perl -ne 'if(/^CoT words: (\d+)/) {print $1;last}')
}

star_rating() {
    local num=$1
    if [ -z "$num" ]; then
        stars="?"
    elif [ "$num" -lt 5 ]; then
        stars="***"
    elif [ "$num" -lt 10 ]; then
        stars="**"
    elif [ "$num" -lt 20 ]; then
        stars="*"
    else
        stars=""
    fi
}

handle_stats() {
    local stats_file=$1
    get_acc $stats_file
    get_wc $stats_file
    get_len $stats_file
    get_lenw $stats_file
    handle_stats_print $acc $wc $len $lenw
}

handle_stats_print() {
    local l_acc=$1
    local l_wc=$2
    local l_len=$3
    local l_lenw=$4
    star_rating "$l_wc"
    #printf " %6.2f" $acc
    printf " %6.2f/%-3s %5.0fc,%4.0ft    " $acc $wc $len $lenw
    #printf " %6.2f%-3s " "$acc" "$stars"
}

for dataset in $(cat datasets.txt); do
    printf "%-30s" $dataset

    for size in 0.6B 1.7B 4B 8B; do
        stats_file=best-stats-cot/Qwen3-${size}_${dataset}.hascot
        has_cot_file=$(ls results/accuracy_test-4/Qwen_Qwen3-${size}_${dataset}_train_2025*[0-9]_cot*.txt 2>/dev/null | tail -n 1)
        has_cot_file2=$(ls $LOG_PATH/Qwen3-${size}_${dataset}.json_2025*Reliance.jsonl 2>/dev/null | tail -n 1)

        if [ -f "$stats_file" ]; then
            handle_stats $stats_file
        elif [ -f "$has_cot_file2" ]; then
            python reasoning-new-calc.py $has_cot_file2 > $stats_file
            handle_stats $stats_file
        else
            echo -n "    -                       "
        fi
    done

    echo
done
