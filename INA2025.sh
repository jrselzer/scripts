#!/bin/bash
# Auswertung von Limesurvey-CSV-Exporten mit Reihenfolgen von Antworten

tail --lines=+2 INA2025.csv | \
        awk -F ";" '
        {
                for (i = 6; i <= 15; i++) {
                        score[$i] += 16-i
                }
        }
        END {
                for (i in score) {
                        print score[i] " " i
                }
        }
        ' | \
        sort -nr | \
        cat -n
