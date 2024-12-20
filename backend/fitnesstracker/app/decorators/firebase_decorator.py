from django.http import JsonResponse
from firebase_admin import auth as firebase_auth


def firebase_token_required(view_func):
    def wrapped_view(request, *args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return JsonResponse({'error': 'Authorization header missing or invalid'}, status=401)

        id_token = auth_header.split(' ')[1]  # Extract the token
        try:
            decoded_token = firebase_auth.verify_id_token(id_token)
            request.user_uid = decoded_token['uid']  # Add the user's UID to the request
            return view_func(request, *args, **kwargs)
        except firebase_auth.InvalidIdTokenError:
            return JsonResponse({'error': 'Invalid ID token'}, status=401)
        except firebase_auth.ExpiredIdTokenError:
            return JsonResponse({'error': 'Expired ID token'}, status=401)
        except Exception as e:
            return JsonResponse({'error': f'Authentication error: {str(e)}'}, status=401)

    return wrapped_view
