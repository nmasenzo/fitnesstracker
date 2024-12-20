from django.urls import path
from app.views.auth_views import GetBearerTokenView
from app.views.user_views import GetUidView, GetUserNameView, CreateUserView, DeleteUserView, GetDashboardDataView, GetUserInfoView
from app.views.exercise_views import GetExercisesView, GetExerciseByIdView, GetExercisesLogView, GetExercisesByDateView, GetMusclePercentageView
from app.views.exercise_views import CreateExerciseLogView, EditExerciseLogView, GetExercisesByDateRangeView, GetMusclePercentagesByDateRangeView
from app.views.exercise_views import ExerciseLogView

urlpatterns = [
    path('api/auth/uid/', GetUidView.as_view(), name='get_uid_view'),
    path('api/users/', CreateUserView.as_view(), name='create_user_view'),
    path('api/users/me/', DeleteUserView.as_view(), name='delete_user_view'),
    path('api/auth/login/', GetBearerTokenView.as_view(), name='get_bearer_token_view'),
    path('api/exercises/', GetExercisesView.as_view(), name='get_exercises_view' ),
    # path('api/exercises/logs/', CreateExerciseLogView.as_view(), name='create_exercise_log'),
    path('api/exercises/logs/by-date/', GetExercisesByDateView.as_view(), name='get_exercises_by_date'),
    path('api/exercises/muscle-percentage/by-date/', GetMusclePercentageView.as_view(), name='get_muscle_percentage_by_date'),
    # path('api/get_exercise_log/', GetExercisesLogView.as_view(), name='get_exercise_log'),
    # path('api/exercises/logs/', EditExerciseLogView.as_view(), name='edit_exercise_log'),
    path('api/exercises/logs/', ExerciseLogView.as_view(), name='exercise_log_view'),
    path('api/get_username/', GetUserNameView.as_view(), name='get_username'),
    path('api/exercises/logs/by-date-range/', GetExercisesByDateRangeView.as_view(), name='get_exercises_by_date_range'),
    path('api/exercises/muscle-percentage/by-date-range/', GetMusclePercentagesByDateRangeView.as_view(), name='get_muscle_percentages_by_date_range'),
    path('api/users/me/dashboard/', GetDashboardDataView.as_view(), name='get_dashboard_data'),
    path('api/users/me/info/', GetUserInfoView.as_view(), name='get_user_info'),
    path('api/exercises/<str:id>/', GetExerciseByIdView.as_view(), name='get_exercise_by_id')
]
