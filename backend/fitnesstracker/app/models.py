from django.db import models
from django.contrib.postgres.fields import ArrayField
    
class User(models.Model):
    user_uid = models.CharField(primary_key=True)
    name = models.CharField(max_length=100)
    email = models.EmailField(max_length=256)
    age = models.IntegerField()
    height = models.FloatField()
    weight = models.FloatField()
    fitness_level = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.email

class Exercise(models.Model):
    FORCE_CHOICES = [
        (None, "None"),
        ("static", "Static"),
        ("pull", "Pull"),
        ("push", "Push"),
    ]

    LEVEL_CHOICES = [
        ("beginner", "Beginner"),
        ("intermediate", "Intermediate"),
        ("expert", "Expert"),
    ]

    MECHANIC_CHOICES = [
        (None, "None"),
        ("isolation", "Isolation"),
        ("compound", "Compound"),
    ]

    EQUIPMENT_CHOICES = [
        (None, "None"),
        ("medicine ball", "Medicine Ball"),
        ("dumbbell", "Dumbbell"),
        ("body only", "Body Only"),
        ("bands", "Bands"),
        ("kettlebells", "Kettlebells"),
        ("foam roll", "Foam Roll"),
        ("cable", "Cable"),
        ("machine", "Machine"),
        ("barbell", "Barbell"),
        ("exercise ball", "Exercise Ball"),
        ("e-z curl bar", "E-Z Curl Bar"),
        ("other", "Other"),
    ]

    MUSCLE_CHOICES = [
        ("abdominals", "Abdominals"),
        ("abductors", "Abductors"),
        ("adductors", "Adductors"),
        ("biceps", "Biceps"),
        ("calves", "Calves"),
        ("chest", "Chest"),
        ("forearms", "Forearms"),
        ("glutes", "Glutes"),
        ("hamstrings", "Hamstrings"),
        ("lats", "Lats"),
        ("lower back", "Lower Back"),
        ("middle back", "Middle Back"),
        ("neck", "Neck"),
        ("quadriceps", "Quadriceps"),
        ("shoulders", "Shoulders"),
        ("traps", "Traps"),
        ("triceps", "Triceps"),
    ]

    CATEGORY_CHOICES = [
        ("powerlifting", "Powerlifting"),
        ("strength", "Strength"),
        ("stretching", "Stretching"),
        ("cardio", "Cardio"),
        ("olympic weightlifting", "Olympic Weightlifting"),
        ("strongman", "Strongman"),
        ("plyometrics", "Plyometrics"),
    ]

    id = models.CharField(max_length=255, primary_key=True)
    name = models.CharField(max_length=255)
    force = models.CharField(
        max_length=10, choices=FORCE_CHOICES, null=True, blank=True
    )
    level = models.CharField(max_length=15, choices=LEVEL_CHOICES)
    mechanic = models.CharField(
        max_length=15, choices=MECHANIC_CHOICES, null=True, blank=True
    )
    equipment = models.CharField(
        max_length=20, choices=EQUIPMENT_CHOICES, null=True, blank=True
    )
    primary_muscles = models.JSONField()
    secondary_muscles = models.JSONField()
    instructions = models.JSONField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    images = models.JSONField()

    def __str__(self):
        return self.name

class ExerciseLog(models.Model):
    log_id = models.AutoField(primary_key=True)  # Auto-incremented primary key
    user_uid = models.ForeignKey(User, on_delete=models.CASCADE, to_field='user_uid')  # FK to User by Firebase UID
    exercise_id = models.ForeignKey(Exercise, on_delete=models.CASCADE)  # FK to Exercise table
    workout_date = models.DateField()  # Date of the workout
    workout_time = models.TimeField()  # Time of the workout

    # Array of objects for sets
    sets = ArrayField(
        models.JSONField(),  # Each set is represented as a JSON object
        default=list,  # Default is an empty list
        help_text='Array of objects with set details (set number, reps, weight)'
    )

    def __str__(self):
        return f"Log {self.log_id} for User {self.user_uid_id} - Exercise {self.exercise_id_id}"






