import json
from django.core.management.base import BaseCommand

from app.models import Exercise

class Command(BaseCommand):
    help = "Load exercises from a JSON file into the database"

    def handle(self, *args, **options):
        file_path = "/app/fitnesstracker/data/exercises.json"  # Adjust path as needed

        # Open and load JSON file
        with open(file_path, "r") as file:
            data = json.load(file)

        # Iterate through each exercise in the JSON array
        for item in data:
            # Extract fields from JSON
            exercise = Exercise(
                id=item["id"],
                name=item["name"],
                force=item.get("force"),  # Use .get to handle optional fields
                level=item["level"],
                mechanic=item.get("mechanic"),
                equipment=item.get("equipment"),
                primary_muscles=item["primaryMuscles"],
                secondary_muscles=item["secondaryMuscles"],
                instructions=item["instructions"],
                category=item["category"],
                images=item["images"],
            )
            exercise.save()

        self.stdout.write(self.style.SUCCESS("Successfully loaded exercises!"))
