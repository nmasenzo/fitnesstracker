from datetime import timedelta, datetime
from rest_framework.views import APIView
from django.utils.decorators import method_decorator
from django.http import JsonResponse
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from ..models import Exercise, ExerciseLog, User
from ..serializers import ExerciseSerializer
from ..decorators.firebase_decorator import firebase_token_required
import json


class GetExercisesView(APIView):
    def get(self, request):
        exercises = Exercise.objects.all()
        paginator = PageNumberPagination()
        paginator.page_size = 50
        paginated_exercises = paginator.paginate_queryset(exercises, request)
        serializer = ExerciseSerializer(paginated_exercises, many=True)

        return paginator.get_paginated_response(serializer.data)


class CreateExerciseLogView(APIView):
    @method_decorator(firebase_token_required)
    def post(self, request):
        try:
            # Parse the request body
            data = json.loads(request.body)

            # Get the current user UID from the authenticated request
            user_uid = request.user_uid

            # Extract required data from the request
            exercise_id = data.get('exercise_id')
            workout_date = data.get('workout_date')
            workout_time = data.get('workout_time')
            sets = data.get('sets', [])

            # Validate required fields
            if not exercise_id or not workout_date or not workout_time:
                return JsonResponse({'error': 'exercise_id, workout_date, and workout_time are required.'}, status=400)

            # Validate that the exercise exists
            try:
                exercise = Exercise.objects.get(id__iexact=exercise_id)
            except Exercise.DoesNotExist:
                return JsonResponse({'error': 'Invalid exercise_id. Exercise not found.'}, status=404)

            # Create the exercise log
            exercise_log = ExerciseLog.objects.create(
                user_uid=User.objects.get(user_uid=user_uid),  # Fetch the user object
                exercise_id=exercise,
                workout_date=workout_date,
                workout_time=workout_time,
                sets=sets
            )

            # Return the created log data
            return JsonResponse({
                'message': 'Exercise log created successfully.',
                'log_id': exercise_log.log_id,
                'user_uid': exercise_log.user_uid.user_uid,
                'exercise_id': exercise_log.exercise_id.id,
                'workout_date': exercise_log.workout_date,
                'workout_time': exercise_log.workout_time,
                'sets': exercise_log.sets
            }, status=201)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON payload.'}, status=400)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)


class GetExerciseByIdView(APIView):
    def get(self, request, id):
        try:
            exercise = Exercise.objects.get(id__iexact=id)
        except Exercise.DoesNotExist:
            return Response({'error': 'Exercise not found'}, status=404)

        data = {
            'id': exercise.id,
            'name': exercise.name,
            'force': exercise.force,
            'level': exercise.level,
            'mechanic': exercise.mechanic,
            'primary_muscles': exercise.primary_muscles,
            'secondary_muscles': exercise.secondary_muscles,
        }

        return Response(data)
    
class GetExercisesByDateView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            user_uid = request.user_uid
            workout_date = request.GET.get('workout_date')

            if not workout_date:
                return JsonResponse({'error': 'workout_date is required.'}, status=400)

            # Validate the date format
            try:
                datetime.strptime(workout_date, "%Y-%m-%d").date()
            except ValueError:
                return JsonResponse({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=400)

            exercise_logs = ExerciseLog.objects.filter(
                user_uid__user_uid=user_uid,
                workout_date=workout_date
            )

            logs_data = [
                {
                    'log_id': log.log_id,
                    'exercise_id': log.exercise_id.id,
                    'exercise_name': log.exercise_id.name,
                    'workout_date': log.workout_date,
                    'workout_time': log.workout_time,
                    'sets': log.sets
                }
                for log in exercise_logs
            ]

            return JsonResponse({
                'message': 'Exercise logs retrieved successfully.',
                'user_uid': user_uid,
                'workout_date': workout_date,
                'logs': logs_data
            }, status=200)

        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)
        
class GetMusclePercentageView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            user_uid = request.user_uid
            workout_date = request.GET.get('workout_date')

            if not workout_date:
                return JsonResponse({'error': 'workout_date is required.'}, status=400)

            exercise_logs = ExerciseLog.objects.filter(
                user_uid__user_uid=user_uid,
                workout_date=workout_date
            )

            if not exercise_logs.exists():
                return JsonResponse({
                    'message': 'No exercise logs found for the given date.',
                    'user_uid': user_uid,
                    'workout_date': workout_date,
                    'muscle_percentages': {}
                }, status=200)

            all_muscle_groups = [
                "abdominals", "abductors", "adductors", "biceps", "calves", "chest", "forearms",
                "glutes", "hamstrings", "lats", "lower back", "middle back", "neck", "quadriceps",
                "shoulders", "traps", "triceps"
            ]

            muscle_counts = {muscle: 0 for muscle in all_muscle_groups}

            for log in exercise_logs:
                try:
                    exercise = Exercise.objects.get(id__iexact=log.exercise_id.id)
                except Exercise.DoesNotExist:
                    continue

                for exercise_set in log.sets:
                    reps = exercise_set['reps']
                    weight = exercise_set['weight']
                    set_weight_factor = reps * weight

                    for muscle in exercise.primary_muscles:
                        muscle_counts[muscle] += (2 * set_weight_factor)

                    for muscle in exercise.secondary_muscles:
                        muscle_counts[muscle] += (1 * set_weight_factor)

            muscle_percentages = {
                muscle: min(round((count / 10000) * 100, 2), 100)
                for muscle, count in muscle_counts.items()
            }

            return JsonResponse({
                'message': 'Muscle percentages calculated successfully.',
                'user_uid': user_uid,
                'workout_date': workout_date,
                'muscle_percentages': muscle_percentages
            }, status=200)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON payload.'}, status=400)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)
        
class GetExercisesLogView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            user_uid = request.user_uid
            log_id = request.GET.get('log_id')

            if not log_id:
                return JsonResponse({'error': 'log_id is required.'}, status=400)

            try:
                # Ensure log_id is an integer
                log_id = int(log_id)
            except ValueError:
                return JsonResponse({'error': 'log_id must be an integer.'}, status=400)

            exercise_log = ExerciseLog.objects.get(
                user_uid__user_uid=user_uid,
                log_id=log_id
            )

            log_data = {
                'log_id': exercise_log.log_id,
                'exercise_id': exercise_log.exercise_id.id,
                'exercise_name': exercise_log.exercise_id.name,
                'workout_date': exercise_log.workout_date,
                'workout_time': exercise_log.workout_time,
                'sets': exercise_log.sets
            }

            return JsonResponse({
                'message': 'Exercise log retrieved successfully.',
                'user_uid': user_uid,
                'log': log_data
            }, status=200)

        except ExerciseLog.DoesNotExist:
            return JsonResponse({'error': 'Exercise log not found.'}, status=404)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)
        
class EditExerciseLogView(APIView):
    @method_decorator(firebase_token_required)
    def put(self, request):
        try:
            data = json.loads(request.body)
            user_uid = request.user_uid
            log_id = data.get('log_id')
            exercise_id = data.get('exercise_id')
            workout_date = data.get('workout_date')
            workout_time = data.get('workout_time')
            sets = data.get('sets', [])

            if not log_id:
                return JsonResponse({'error': 'log_id is required.'}, status=400)

            try:
                exercise_log = ExerciseLog.objects.get(log_id=log_id, user_uid__user_uid=user_uid)
            except ExerciseLog.DoesNotExist:
                return JsonResponse({'error': 'Exercise log not found.'}, status=404)

            if exercise_id:
                try:
                    exercise = Exercise.objects.get(id__iexact=exercise_id)
                    exercise_log.exercise_id = exercise
                except Exercise.DoesNotExist:
                    return JsonResponse({'error': 'Invalid exercise_id. Exercise not found.'}, status=404)

            if workout_date:
                exercise_log.workout_date = workout_date

            if workout_time:
                exercise_log.workout_time = workout_time

            if sets:
                exercise_log.sets = sets

            exercise_log.save()

            return JsonResponse({
                'message': 'Exercise log updated successfully.',
                'log': {
                    'log_id': exercise_log.log_id,
                    'exercise_id': exercise_log.exercise_id.id,
                    'exercise_name': exercise_log.exercise_id.name,
                    'workout_date': exercise_log.workout_date,
                    'workout_time': exercise_log.workout_time,
                    'sets': exercise_log.sets
                }
            }, status=200)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON payload.'}, status=400)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)
        
class GetExercisesByDateRangeView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            # Extract query parameters
            user_uid = request.user_uid
            start_date = request.GET.get('start_date')
            end_date = request.GET.get('end_date')

            # Validate required fields
            if not start_date or not end_date:
                return JsonResponse({'error': 'start_date and end_date are required.'}, status=400)

            # Validate date formats
            try:
                datetime.strptime(start_date, "%Y-%m-%d")
                datetime.strptime(end_date, "%Y-%m-%d")
            except ValueError:
                return JsonResponse({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=400)

            # Fetch exercise logs for the given date range
            exercise_logs = ExerciseLog.objects.filter(
                user_uid__user_uid=user_uid,
                workout_date__range=[start_date, end_date]
            )

            # Prepare the logs data
            logs_data = [
                {
                    'log_id': log.log_id,
                    'exercise_id': log.exercise_id.id,
                    'exercise_name': log.exercise_id.name,
                    'workout_date': log.workout_date,
                    'workout_time': log.workout_time,
                    'sets': log.sets
                }
                for log in exercise_logs
            ]

            return JsonResponse({
                'message': 'Exercise logs retrieved successfully.',
                'user_uid': user_uid,
                'start_date': start_date,
                'end_date': end_date,
                'logs': logs_data
            }, status=200)

        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)


class GetMusclePercentagesByDateRangeView(APIView):
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            # Extract query parameters
            user_uid = request.user_uid
            start_date = request.GET.get('start_date')
            end_date = request.GET.get('end_date')

            # Validate required fields
            if not start_date or not end_date:
                return JsonResponse({'error': 'start_date and end_date are required.'}, status=400)

            # Validate date formats
            try:
                datetime.strptime(start_date, "%Y-%m-%d")
                datetime.strptime(end_date, "%Y-%m-%d")
            except ValueError:
                return JsonResponse({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=400)

            # Fetch exercise logs for the given date range
            exercise_logs = ExerciseLog.objects.filter(
                user_uid__user_uid=user_uid,
                workout_date__range=[start_date, end_date]
            )

            if not exercise_logs.exists():
                return JsonResponse({
                    'message': 'No exercise logs found for the given date range.',
                    'user_uid': user_uid,
                    'start_date': start_date,
                    'end_date': end_date,
                    'muscle_percentages': {}
                }, status=200)

            all_muscle_groups = [
                "abdominals", "abductors", "adductors", "biceps", "calves", "chest", "forearms",
                "glutes", "hamstrings", "lats", "lower back", "middle back", "neck", "quadriceps",
                "shoulders", "traps", "triceps"
            ]

            muscle_counts = {muscle: 0 for muscle in all_muscle_groups}

            for log in exercise_logs:
                try:
                    exercise = Exercise.objects.get(id__iexact=log.exercise_id.id)
                except Exercise.DoesNotExist:
                    continue

                for exercise_set in log.sets:
                    reps = exercise_set['reps']
                    weight = exercise_set['weight']
                    set_weight_factor = reps * weight

                    for muscle in exercise.primary_muscles:
                        muscle_counts[muscle] += (2 * set_weight_factor)

                    for muscle in exercise.secondary_muscles:
                        muscle_counts[muscle] += (1 * set_weight_factor)

            muscle_percentages = {
                muscle: min(round((count / 10000) * 100, 2), 100)
                for muscle, count in muscle_counts.items()
            }

            return JsonResponse({
                'message': 'Muscle percentages calculated successfully.',
                'user_uid': user_uid,
                'start_date': start_date,
                'end_date': end_date,
                'muscle_percentages': muscle_percentages
            }, status=200)

        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)

class ExerciseLogView(APIView):
    @method_decorator(firebase_token_required)
    def post(self, request):
        """Create a new exercise log."""
        try:
            # Parse the request body
            data = json.loads(request.body)
            user_uid = request.user_uid

            # Extract required data
            exercise_id = data.get('exercise_id')
            workout_date = data.get('workout_date')
            workout_time = data.get('workout_time')
            sets = data.get('sets', [])

            # Validate required fields
            if not exercise_id or not workout_date or not workout_time:
                return JsonResponse({'error': 'exercise_id, workout_date, and workout_time are required.'}, status=400)

            # Validate that the exercise exists
            try:
                exercise = Exercise.objects.get(id__iexact=exercise_id)
            except Exercise.DoesNotExist:
                return JsonResponse({'error': 'Invalid exercise_id. Exercise not found.'}, status=404)

            # Create the exercise log
            exercise_log = ExerciseLog.objects.create(
                user_uid=User.objects.get(user_uid=user_uid),
                exercise_id=exercise,
                workout_date=workout_date,
                workout_time=workout_time,
                sets=sets
            )

            # Return the created log data
            return JsonResponse({
                'message': 'Exercise log created successfully.',
                'log_id': exercise_log.log_id,
                'user_uid': exercise_log.user_uid.user_uid,
                'exercise_id': exercise_log.exercise_id.id,
                'workout_date': exercise_log.workout_date,
                'workout_time': exercise_log.workout_time,
                'sets': exercise_log.sets
            }, status=201)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON payload.'}, status=400)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)

    @method_decorator(firebase_token_required)
    def put(self, request):

        """Update an existing exercise log."""
        try:
            data = json.loads(request.body)
            user_uid = request.user_uid

            # Extract required data
            log_id = data.get('log_id')
            exercise_id = data.get('exercise_id')
            workout_date = data.get('workout_date')
            workout_time = data.get('workout_time')
            sets = data.get('sets', [])

            if not log_id:
                return JsonResponse({'error': 'log_id is required.'}, status=400)

            # Validate and fetch the existing log
            try:
                exercise_log = ExerciseLog.objects.get(log_id=log_id, user_uid__user_uid=user_uid)
            except ExerciseLog.DoesNotExist:
                return JsonResponse({'error': 'Exercise log not found.'}, status=404)

            # Update fields if provided
            if exercise_id:
                try:
                    exercise = Exercise.objects.get(id__iexact=exercise_id)
                    exercise_log.exercise_id = exercise
                except Exercise.DoesNotExist:
                    return JsonResponse({'error': 'Invalid exercise_id. Exercise not found.'}, status=404)

            if workout_date:
                exercise_log.workout_date = workout_date

            if workout_time:
                exercise_log.workout_time = workout_time

            if sets:
                exercise_log.sets = sets

            # Save changes
            exercise_log.save()

            # Return the updated log data
            return JsonResponse({
                'message': 'Exercise log updated successfully.',
                'log': {
                    'log_id': exercise_log.log_id,
                    'exercise_id': exercise_log.exercise_id.id,
                    'exercise_name': exercise_log.exercise_id.name,
                    'workout_date': exercise_log.workout_date,
                    'workout_time': exercise_log.workout_time,
                    'sets': exercise_log.sets
                }
            }, status=200)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON payload.'}, status=400)
        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)
        
    @method_decorator(firebase_token_required)
    def get(self, request):
        try:
            user_uid = request.user_uid
            log_id = request.GET.get('log_id')

            if log_id:
                # Retrieve a specific log by log_id
                try:
                    # Ensure log_id is an integer
                    log_id = int(log_id)
                except ValueError:
                    return JsonResponse({'error': 'log_id must be an integer.'}, status=400)

                try:
                    exercise_log = ExerciseLog.objects.get(
                        user_uid__user_uid=user_uid,
                        log_id=log_id
                    )
                except ExerciseLog.DoesNotExist:
                    return JsonResponse({'error': 'Exercise log not found.'}, status=404)

                log_data = {
                    'log_id': exercise_log.log_id,
                    'exercise_id': exercise_log.exercise_id.id,
                    'exercise_name': exercise_log.exercise_id.name,
                    'workout_date': exercise_log.workout_date,
                    'workout_time': exercise_log.workout_time,
                    'sets': exercise_log.sets
                }

                return JsonResponse({
                    'message': 'Exercise log retrieved successfully.',
                    'user_uid': user_uid,
                    'log': log_data
                }, status=200)

            else:
                # Retrieve all logs for the authenticated user
                exercise_logs = ExerciseLog.objects.filter(
                    user_uid__user_uid=user_uid
                ).order_by('-workout_date', '-workout_time')

                logs_data = [
                    {
                        'log_id': log.log_id,
                        'exercise_id': log.exercise_id.id,
                        'exercise_name': log.exercise_id.name,
                        'workout_date': log.workout_date,
                        'workout_time': log.workout_time,
                        'sets': log.sets
                    }
                    for log in exercise_logs
                ]

                return JsonResponse({
                    'message': 'Exercise logs retrieved successfully.',
                    'user_uid': user_uid,
                    'logs': logs_data
                }, status=200)

        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)