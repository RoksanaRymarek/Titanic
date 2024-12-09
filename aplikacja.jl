using DataFrames
using CSV
using HTTP
using GLM
using JLD2
using Gtk
using GtkReactive

# Pobieranie danych z zestawu Titanic
Titanic = "http://analityk.edu.pl/wp-content/uploads/2020/02/titanic.csv"
titanic_data = CSV.read(download(Titanic), DataFrame)

# Przygotowanie danych
DataFrames.select!(titanic_data, Not([:ticket, :fare, :boat, :body, :cabin, :embarked, :home_dest]))
dropmissing!(titanic_data)
titanic_data.sex = ifelse.(titanic_data.sex .== "male", 1, 0)

# Wczytanie modelu z pliku
model_file = "trained_model.jld2"
@load model_file logreg

"""
    predict_survival(age, sex, pclass, parch, sibsp)

Funkcja przewidująca prawdopodobieństwo przeżycia na podstawie wieku, płci, klasy, liczby rodzeństwa i liczby rodziców

# Argumenty
- `age::Float64`: Wiek pasażera.
- `sex::Int64`: Płeć pasażera (wartości: 1 - mężczyzna, 0 - kobieta).
- `pclass::Int64`: Klasa pasażera (wartości: 1 - pierwsza klasa, 2 - druga klasa, 3 - trzecia klasa).
- `parch::Int64`: Liczba rodziców/dzieci na pokładzie.
- `sibsp::Int64`: Liczba rodzeństwa/małżonków na pokładzie.

# Zwraca
Prawdopodobieństwo przeżycia wyrażone w procentach.

# Uwagi
Funkcja korzysta z wytrenowanego modelu regresji logistycznej `logreg`, który musi być dostępny.
"""
function predict_survival(age, sex, pclass, parch, sibsp)
    new_data = DataFrame(age=[age], sex=[sex], pclass=[pclass], parch=[parch], sibsp=[sibsp])
    predicted_label = predict(logreg, new_data)[1]
    return round(100 * predicted_label)
end

# Tworzenie głównego okna
window = GtkWindow(title = "Program przewidujący prawdopodobieństwo przeżycia na Titanicu")

# Tworzenie kontenera
content = GtkBox(:v)

# Tworzenie etykiet i pól tekstowych

age_label = GtkLabel("Wiek:")
age_entry = GtkEntry()
sex_label = GtkLabel("Płeć (0 - kobieta, 1 - mężczyzna):")
sex_entry = GtkEntry()
pclass_label = GtkLabel("Klasa (1 - 3):")
pclass_entry = GtkEntry()
parch_label = GtkLabel("Liczba rodziców/dzieci na pokładzie:")
parch_entry = GtkEntry()
sibsp_label = GtkLabel("Liczba rodzeństwa/partnerów na pokładzie:")
sibsp_entry = GtkEntry()
calculate_button = GtkButton("Oblicz")
result_label = GtkLabel("Prawdopodobieństwo przeżycia:")
resultt = GtkLabel(" ")

"""
    ff(widget)

Funkcja przewiduje prawdopodobieństwo przeżycia na podstawie danych demograficznych wprowadzonych w interfejsie GTK.

# Argumenty
- `widget`: Obiekt reprezentujący interfejs GTK.

# Uwagi
- Funkcja używa funkcji `parse()` do konwersji wartości wprowadzonych w interfejsie na odpowiednie typy danych.
- Funkcja korzysta z funkcji `get_gtk_property()` do pobierania wartości wprowadzonych danych.
- Funkcja korzysta z funkcji `set_gtk_property!()` do aktualizacji właściwości etykiety wynikowej `resultt`.
"""
function ff(widget)
    age = parse(Int, get_gtk_property(age_entry, :text, String))
    sex = parse(Int, get_gtk_property(sex_entry, :text, String))
    pclass = parse(Int, get_gtk_property(pclass_entry, :text, String))
    parch = parse(Int, get_gtk_property(parch_entry, :text, String))
    sibsp = parse(Int, get_gtk_property(sibsp_entry, :text, String))

    probability = predict_survival(age, sex, pclass, parch, sibsp)
    
    result = "Prawdopodobieństwo przeżycia: $probability%"

    if probability > 50
        result = result * " Gratulacje! Istnieje większe prawdopodobieństwo, że przeżyjesz."
    else
        result = result * " Niestety, istnieje mniejsze prawdopodobieństwo, że przeżyjesz."
    end
    
    set_gtk_property!(resultt, :label, result)
end

# Obsługa przycisku
id = signal_connect(ff, calculate_button, "clicked")

# Dodawanie elementów do kontenera
push!(content, age_label)
push!(content, age_entry)
push!(content, sex_label)
push!(content, sex_entry)
push!(content, pclass_label)
push!(content, pclass_entry)
push!(content, parch_label)
push!(content, parch_entry)
push!(content, sibsp_label)
push!(content, sibsp_entry)
push!(content, calculate_button)
push!(content, result_label)
push!(content, resultt)

# Ustawienie kontenera jako zawartość okna
set_gtk_property!(window, :child, content)

# Wyświetlenie okna
showall(window)