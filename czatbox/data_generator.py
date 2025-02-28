import random
from typing import List

def generate_opening_hours_queries() -> List[str]:
    templates = [
        "Czy jesteście otwaci {day} o {time}?",
        "O ktorej otwieracie w {day}?",
        "Czy moge przyjsc w {day} o {time}?",
        "Czy restauracja jest czynna {day}?",
    ]
    
    days = ["poniedziałek", "wtorek", "środę", "czwartek", "piątek", "sobotę", "niedzielę"]
    times = ["8:00", "9:00", "10:00", "12:00", "15:00", "19:00", "20:00"]
    
    queries = []
    for template in templates:
        for day in days:
            for time in times:
                query = template.format(day=day, time=time)
                # Dodaj typowe błędy
                query = query.replace("otwaci", "otwarci").replace("ktorej", "której")
                queries.append(query)
    
    return queries

def generate_menu_queries() -> List[str]:
    templates = [
        "Co macie w menu?",
        "Jakie dania oferujecie?",
        "Pokaż menu",
        "Co mogę zamówić?",
    ]
    
    return templates

def generate_order_queries() -> List[str]:
    templates = [
        "Poproszę {item}",
        "Chciałbym zamówić {item}",
        "Czy mogę prosić o {item}",
        "{item} poproszę",
    ]
    
    items = ["pizzę", "burgera", "lasagne", "spaghetti", "tiramisu"]
    modifications = ["bez pomidorów", "bez sosu", "extra ser", "na ostro"]
    
    queries = []
    for template in templates:
        for item in items:
            query = template.format(item=item)
            queries.append(query)
            for mod in modifications:
                query_with_mod = f"{query} {mod}"
                queries.append(query_with_mod)
    
    return queries 