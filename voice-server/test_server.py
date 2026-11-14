import unittest
from unittest.mock import patch

import server


def extracted_food(name, search, **overrides):
    return {
        "name": name,
        "search": search,
        "branded": False,
        "grams": 200,
        "recipe_details": [],
        "nutrition_quote": None,
        "base_calories": None,
        "base_protein": None,
        "portion_assumed": True,
        "calories": None,
        "protein": None,
        "status": "eaten",
        "date": "2026-11-14",
        "servings": None,
        "explicit_grams": None,
        **overrides,
    }


class MealNutritionTest(unittest.TestCase):
    def test_composite_estimates_missing_nutrient_without_creating_entries(self):
        food = extracted_food(
            "מרק עם יוגורט", "vegetable soup with yogurt", protein=0,
            nutrition_quote="0 גרם חלבון", recipe_details=["yogurt"],
        )
        transcript = "מרק עם יוגורט, 0 גרם חלבון"

        def respond(prompt, data, _schema, **_kwargs):
            if prompt == server.PARSE:
                self.assertEqual(data["transcript"], transcript)
                self.assertNotIn("saved_foods", data)
                return {"items": [food], "clarification": None}
            if prompt == server.MATCH_REFERENCE:
                return {"matches": [{"item": 0, "history_id": None, "personal_id": 0}]}
            self.assertEqual(prompt, server.RESOLVE_NUTRITION)
            self.assertEqual(data[0]["candidates"], [])
            self.assertEqual(data[0]["known_protein"], 0)
            return {"items": [{"item": 0, "candidate": None, "parts": [
                {"portion": "קערת מרק", "calories": 120, "protein": 4},
                {"portion": "כף יוגורט", "calories": 30, "protein": 1},
            ]}]}

        with patch.object(server, "structured", side_effect=respond), patch.object(
            server, "lookup", return_value={1: ("Vegetable soup, canned", 60, 3)}
        ):
            result = server.parse_meal(
                transcript, "2026-11-14", "2026-11-14",
                history=[{"name": "לחם", "calories": 100, "protein": 5}],
                personal_foods=[{"name": "יוגורט", "calories": 100, "protein": 5, "defaultGrams": None}],
            )
        self.assertEqual(len(result["items"]), 1)
        item = result["items"][0]
        self.assertEqual(item["calories"], 150)
        self.assertEqual(item["protein"], 0)
        self.assertEqual(item["estimateSource"], "קערת מרק (120 kcal) + כף יוגורט (30 kcal)")
        self.assertIsNone(item["personalSource"])
        self.assertIsNone(item["source"])

    def test_complete_personal_reference_skips_lookup_and_estimate(self):
        food = extracted_food("חצי פיתה", "pita", calories=999)
        entry = {"name": "פיתה", "calories": 200, "protein": 8, "defaultGrams": None}
        responses = [
            {"items": [food], "clarification": None},
            {"matches": [{"item": 0, "history_id": None, "personal_id": 0}]},
        ]
        with patch.object(server, "structured", side_effect=responses), patch.object(server, "lookup") as lookup:
            result = server.parse_meal("חצי פיתה", "2026-11-14", "2026-11-14", personal_foods=[entry])
        lookup.assert_not_called()
        item = result["items"][0]
        self.assertEqual((item["calories"], item["protein"]), (100, 4))
        self.assertEqual(item["personalSource"], "פיתה")
        self.assertIsNone(item["estimateSource"])

    def test_additions_are_summed_on_top_of_stated_base(self):
        transcript = "קערת אורז היא 400 קלוריות לפני התוספות, הוספתי טחינה"
        food = extracted_food(
            "קערת אורז עם טחינה", "rice bowl with tahini",
            base_calories=400, nutrition_quote="400 קלוריות", recipe_details=["tahini"],
        )
        responses = [
            {"items": [food], "clarification": None},
            {"items": [{"item": 0, "candidate": None, "parts": [
                {"portion": "קערת אורז", "calories": 200, "protein": 7},
                {"portion": "כף טחינה", "calories": 90, "protein": 3},
            ]}]},
        ]
        with patch.object(server, "structured", side_effect=responses), patch.object(server, "lookup") as lookup:
            result = server.parse_meal(transcript, "2026-11-14", "2026-11-14")
        lookup.assert_not_called()
        item = result["items"][0]
        self.assertEqual((item["calories"], item["protein"]), (490, 10))
        self.assertEqual(item["estimateSource"], "קערת אורז (400 kcal) + כף טחינה (90 kcal)")
