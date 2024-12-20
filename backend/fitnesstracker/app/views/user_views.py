from django.http import JsonResponse
from firebase_admin import auth as firebase_auth
from rest_framework.views import APIView
from django.utils.decorators import method_decorator
from ..decorators.firebase_decorator import firebase_token_required
from django.views.decorators.csrf import csrf_exempt
import json
from ..models import ExerciseLog, Exercise, User
from datetime import timedelta, datetime
from django.db.models import Count


class GetUidView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        return JsonResponse({'user_uid': request.user_uid})
    
class GetUserNameView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            user_uid = request.user_uid
            user = User.objects.get(user_uid=user_uid)

            return JsonResponse({
                'name': user.name
            }, status=200)

        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)

class CreateUserView(APIView):
    @method_decorator(csrf_exempt)
    def post(self, request):
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON payload'}, status=400)

        name = data.get("name", "Default User")
        email = data.get("email")
        password = data.get("password")
        age = data.get("age")
        height = data.get("height")
        weight = data.get("weight")
        fitness_level = data.get("fitness_level")

        if not password:
            return JsonResponse({'error': 'Password is required to create a Firebase user'}, status=400)
        if not email:
            return JsonResponse({'error': 'Email is required to create a Firebase user'}, status=400)

        try:
            firebase_user = firebase_auth.create_user(
                email=email,
                password=password,
                display_name=name
            )
        except firebase_auth.EmailAlreadyExistsError:
            return JsonResponse({'error': 'A user with this email already exists'}, status=400)

        user_uid = firebase_user.uid
        user, created = User.objects.get_or_create(
            user_uid=user_uid,
            defaults={
                "name": name,
                "email": email,
                "age": age,
                "height": height,
                "weight": weight,
                "fitness_level": fitness_level,
            }
        )

        message = "A new user was created!" if created else "User already exists!"

        return JsonResponse({
            'message': message,
            'user_uid': user.user_uid,
            'created': created,
            'user_data': {
                "name": user.name,
                "email": user.email,
                "age": user.age,
                "height": user.height,
                "weight": user.weight,
                "fitness_level": user.fitness_level,
            }
        })

class DeleteUserView(APIView):
    @method_decorator(csrf_exempt)
    @method_decorator(firebase_token_required)
    def delete(self, request):
        user_uid = request.user_uid

        try:
            firebase_auth.delete_user(user_uid)
        except firebase_auth.UserNotFoundError:
            return JsonResponse({'error': 'User UID does not exist in Firebase.', 'user_uid': user_uid})
        except Exception as e:
            return JsonResponse({'error': 'An error occurred while deleting the Firebase user.', 'details': str(e)})

        try:
            user = User.objects.get(user_uid=user_uid)
            user.delete()
        except User.DoesNotExist:
            return JsonResponse({'error': 'User record does not exist in the database.', 'user_uid': user_uid})
        except Exception as e:
            return JsonResponse({'error': 'An error occurred while deleting the database record.', 'details': str(e)})

        return JsonResponse({
            'message': 'User UID deleted successfully from Firebase and database.',
            'user_uid': user_uid
        })
    

class GetDashboardDataView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            # Parse query parameters
            user_uid = request.user_uid
            start_date_str = request.GET.get('start_date')
            end_date_str = request.GET.get('end_date')

            # Validate required fields
            if not start_date_str or not end_date_str:
                return JsonResponse({'error': 'start_date and end_date are required.'}, status=400)

            # Convert string dates to datetime objects
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
            end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date()

            # Define the previous week date range
            prev_start_date = start_date - timedelta(days=7)
            prev_end_date = end_date - timedelta(days=7)

            # Fetch exercise logs for the current week and previous week
            current_week_logs = ExerciseLog.objects.filter(
                user_uid__user_uid=user_uid,
                workout_date__range=[start_date, end_date]
            )

            previous_week_logs = ExerciseLog.objects.filter(
                user_uid__user_uid=user_uid,
                workout_date__range=[prev_start_date, prev_end_date]
            )

            # Calculate the number of logs for current and previous weeks
            current_week_num_logs = current_week_logs.count()
            previous_week_num_logs = previous_week_logs.count()

            # Calculate the total number of sets for current and previous weeks
            current_week_sets = sum(
                [len(log.sets) for log in current_week_logs if log.sets]
            )

            previous_week_sets = sum(
                [len(log.sets) for log in previous_week_logs if log.sets]
            )

            # Get unique muscles for current week
            current_week_exercises = Exercise.objects.filter(
                id__in=current_week_logs.values_list('exercise_id', flat=True)
            )
            current_week_muscles = set()
            for exercise in current_week_exercises:
                current_week_muscles.update(exercise.primary_muscles)
                current_week_muscles.update(exercise.secondary_muscles)
            current_week_num_muscles = len(current_week_muscles)

            # Get unique muscles for previous week
            previous_week_exercises = Exercise.objects.filter(
                id__in=previous_week_logs.values_list('exercise_id', flat=True)
            )
            previous_week_muscles = set()
            for exercise in previous_week_exercises:
                previous_week_muscles.update(exercise.primary_muscles)
                previous_week_muscles.update(exercise.secondary_muscles)
            previous_week_num_muscles = len(previous_week_muscles)

            # Hardcoded progress percentage
            progress_percentage = 79  # Placeholder value

            # Prepare response data
            response_data = {
                "firstName": User.objects.get(user_uid=user_uid).name.split(' ')[0],
                "start_date": start_date_str,
                "end_date": end_date_str,
                "currentWeek": {
                    "numOfLogs": current_week_num_logs,
                    "numOfMuscles": current_week_num_muscles,
                    "numOfSets": current_week_sets
                },
                "previousWeek": {
                    "numOfLogs": previous_week_num_logs,
                    "numOfMuscles": previous_week_num_muscles,
                    "numOfSets": previous_week_sets
                },
                "progressPercentage": progress_percentage
            }

            return JsonResponse(response_data, status=200)

        except ValueError:
            return JsonResponse({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=400)
        except User.DoesNotExist:
            return JsonResponse({'error': 'User not found.'}, status=404)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)

        
class GetUserInfoView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            # Get the authenticated user's UID
            user_uid = request.user_uid

            # Fetch the user from the database
            user = User.objects.get(user_uid=user_uid)

            # Prepare the user information to return
            user_info = {
                "name": user.name,
                "email": user.email,
                "age": user.age,
                "height": user.height,
                "weight": user.weight,
                "fitness_level": user.fitness_level,
            }

            return JsonResponse(user_info, status=200)

        except User.DoesNotExist:
            return JsonResponse({'error': 'User not found.'}, status=404)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)

