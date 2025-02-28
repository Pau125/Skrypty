#!/bin/bash

# plansza
plansza=(" " " " " " " " " " " " " " " " " ")
gracz="X"
komputer="O"
tryb_gry=""
PLIK_ZAPISU="gra_save.txt"

wyswietl_plansze() {
    clear
    echo " ${plansza[0]} | ${plansza[1]} | ${plansza[2]} "
    echo "---+---+---"
    echo " ${plansza[3]} | ${plansza[4]} | ${plansza[5]} "
    echo "---+---+---"
    echo " ${plansza[6]} | ${plansza[7]} | ${plansza[8]} "
}

sprawdz_wygrana() {
    # poziomo
    for ((i=0; i<9; i+=3)); do
        if [[ "${plansza[$i]}" != " " && "${plansza[$i]}" == "${plansza[$((i+1))]}" && "${plansza[$i]}" == "${plansza[$((i+2))]}" ]]; then
            return 0
        fi
    done
    
    # pionowo
    for ((i=0; i<3; i++)); do
        if [[ "${plansza[$i]}" != " " && "${plansza[$i]}" == "${plansza[$((i+3))]}" && "${plansza[$i]}" == "${plansza[$((i+6))]}" ]]; then
            return 0
        fi
    done
    
    # po przekątnych
    if [[ "${plansza[0]}" != " " && "${plansza[0]}" == "${plansza[4]}" && "${plansza[0]}" == "${plansza[8]}" ]]; then
        return 0
    fi
    if [[ "${plansza[2]}" != " " && "${plansza[2]}" == "${plansza[4]}" && "${plansza[2]}" == "${plansza[6]}" ]]; then
        return 0
    fi
    
    return 1
}

zapisz_gre() {
    # Wyczyść plik przed zapisem
    > "$PLIK_ZAPISU"
    
    # każdy element planszy w osobnej linii
    for i in {0..8}; do
        echo "${plansza[$i]}" >> "$PLIK_ZAPISU"
    done
    echo "$tryb_gry" >> "$PLIK_ZAPISU"
    echo "$gracz" >> "$PLIK_ZAPISU"
    echo "Gra została zapisana!"
    exit 0
}

wczytaj_gre() {
    if [ -f "$PLIK_ZAPISU" ]; then
        # plansza
        i=0
        while IFS= read -r linia || [ -n "$linia" ]; do
            if [ $i -lt 9 ]; then
                plansza[$i]="$linia"
            elif [ $i -eq 9 ]; then
                tryb_gry="$linia"
            elif [ $i -eq 10 ]; then
                gracz="$linia"
            fi
            ((i++))
        done < "$PLIK_ZAPISU"
        
        # czy wszystkie dane zostały wczytane
        if [ $i -lt 11 ]; then
            echo "Błąd: Nieprawidłowy format pliku zapisu!"
            return 1
        fi
        return 0
    fi
    return 1
}

ruch_komputera() {
    for ((i=0; i<9; i++)); do
        if [[ "${plansza[$i]}" == " " ]]; then
            plansza[$i]="$komputer"
            return
        fi
    done
}

# pętla gry
gra() {
    echo "Wybierz tryb gry:"
    echo "1 - Gra z drugim graczem"
    echo "2 - Gra z komputerem"
    echo "3 - Wczytaj zapisaną grę"
    read -r wybor

    case $wybor in
        1) tryb_gry="pvp";;
        2) tryb_gry="pvc";;
        3) 
            if wczytaj_gre; then
                echo "Wczytano zapisaną grę!"
                sleep 1
            else
                echo "Brak zapisanej gry!"
                exit 1
            fi
            ;;
        *) 
            echo "Nieprawidłowy wybór!"
            exit 1
            ;;
    esac

    while true; do
        wyswietl_plansze
        
        # Ruch gracza
        echo "Gracz $gracz, wybierz pole (1-9) lub 's' aby zapisać grę:"
        read -r ruch
        
        if [[ "$ruch" == "s" ]]; then
            zapisz_gre
        fi
        
        if ! [[ "$ruch" =~ ^[1-9]$ ]]; then
            echo "Nieprawidłowy ruch!"
            continue
        fi
        
        pozycja=$((ruch-1))
        
        if [[ "${plansza[$pozycja]}" != " " ]]; then
            echo "Pole zajęte!"
            continue
        fi
        
        plansza[$pozycja]="$gracz"
        
        if sprawdz_wygrana; then
            wyswietl_plansze
            echo "Gracz $gracz wygrywa!"
            exit 0
        fi
        
        # czy remis
        if [[ ! " ${plansza[@]} " =~ " " ]]; then
            wyswietl_plansze
            echo "Remis!"
            exit 0
        fi
        
        # Zmiana gracza lub ruch komputera
        if [[ "$tryb_gry" == "pvp" ]]; then
            if [[ "$gracz" == "X" ]]; then
                gracz="O"
            else
                gracz="X"
            fi
        else
            wyswietl_plansze
            echo "Ruch komputera..."
            sleep 1
            ruch_komputera
            
            if sprawdz_wygrana; then
                wyswietl_plansze
                echo "Komputer wygrywa!"
                exit 0
            fi
        fi
    done
}

gra