from rest_framework.views import APIView
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.http import JsonResponse
import json
import requests


class GetBearerTokenView(APIView):
    @method_decorator(csrf_exempt)
    def post(self, request):
        try:
            data = json.loads(request.body)
            email = data.get('email')
            password = data.get('password')

            if not email or not password:
                return JsonResponse({'error': 'Email and password are required.'}, status=400)

            import requests

            firebase_api_key = "AIzaSyAhp_2Bjl0EsCt0swDh4ckaWPRnATE07AQ"
            url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={firebase_api_key}"

            payload = {
                "email": email,
                "password": password,
                "returnSecureToken": True
            }

            response = requests.post(url, json=payload)
            if response.status_code != 200:
                return JsonResponse({'error': 'Invalid email or password.'}, status=401)

            id_token = response.json().get('idToken')

            return JsonResponse({'token_type': 'Bearer', 'access_token': id_token}, status=200)

        except Exception as e:
            return JsonResponse({'error': f'An error occurred: {str(e)}'}, status=500)
