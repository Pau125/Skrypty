from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
import json
from datetime import datetime, timedelta

class ActionCheckOpeningHours(Action):
    def name(self) -> Text:
        return "action_check_opening_hours"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        with open('data/opening_hours.json', 'r') as f:
            hours = json.load(f)
            
        day = tracker.get_slot("day")
        time = tracker.get_slot("time")
        
        if hours["items"][day]["open"] == 0:
            dispatcher.utter_message(f"Przepraszamy, w {day} jesteśmy zamknięci.")
        else:
            dispatcher.utter_message(
                f"W {day} jesteśmy otwarci od {hours['items'][day]['open']}:00 "
                f"do {hours['items'][day]['close']}:00"
            )
        
        return []

class ActionShowMenu(Action):
    def name(self) -> Text:
        return "action_show_menu"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
            
        with open('data/menu.json', 'r') as f:
            menu = json.load(f)
            
        menu_text = "Nasze menu:\n"
        for item in menu["items"]:
            menu_text += f"- {item['name']}: {item['price']} zł\n"
            
        dispatcher.utter_message(text=menu_text)
        return []

class ActionProcessOrder(Action):
    def name(self) -> Text:
        return "action_process_order"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
            
        dish = tracker.get_slot("dish")
        address = tracker.get_slot("address")
        
        if dish and address:
            dispatcher.utter_message(
                f"Dziękujemy za zamówienie! Twoje danie: {dish} zostanie dostarczone na adres: {address}. "
                "Czas dostawy to około 45 minut."
            )
        elif not address:
            dispatcher.utter_message("Proszę podać adres dostawy.")
        else:
            dispatcher.utter_message("Przepraszamy, nie rozpoznałem zamówienia. Proszę spróbować ponownie.")
            
        return [] 