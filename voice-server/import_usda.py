"""Extract food names, kcal and protein per 100 g from a FoodData Central CSV ZIP."""
import argparse
import csv
import io
import json
from pathlib import Path
from zipfile import ZipFile


def rows(archive, filename):
    member = next(name for name in archive.namelist() if name.rsplit("/", 1)[-1] == filename)
    with archive.open(member) as stream:
        yield from csv.DictReader(io.TextIOWrapper(stream, encoding="utf-8-sig"))


def catalog(archives):
    foods = {}
    for path in archives:
        with ZipFile(path) as archive:
            nutrients = {}
            for row in rows(archive, "food_nutrient.csv"):
                # The FNDDS export uses USDA nutrient numbers for these rows.
                nutrient = {"203": "1003", "208": "1008"}.get(row["nutrient_id"], row["nutrient_id"])
                if nutrient in ("1003", "1008", "2047", "2048") and row["amount"]:
                    nutrients.setdefault(row["fdc_id"], {})[nutrient] = float(row["amount"])
            for food in rows(archive, "food.csv"):
                data = nutrients.get(food["fdc_id"], {})
                calories = next((data[key] for key in ("1008", "2047", "2048") if key in data), None)
                protein = data.get("1003")
                if calories is not None or protein is not None:
                    foods[int(food["fdc_id"])] = [food["description"], calories, protein]
    return foods


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("archives", nargs="+", type=Path)
    args = parser.parse_args()
    foods = catalog(args.archives)
    temporary = args.output.with_suffix(".tmp")
    temporary.write_text(json.dumps(foods, ensure_ascii=False), encoding="utf-8")
    temporary.replace(args.output)
    print(f"Imported {len(foods)} USDA foods.")
