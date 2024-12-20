from rest_framework import serializers
from .models import User, Exercise

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'

class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = ['id']

class Exercise(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = '__all__'
