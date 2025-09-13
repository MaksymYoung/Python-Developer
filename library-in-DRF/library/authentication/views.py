from django.conf import settings
from django.contrib.auth import login, logout
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.core.paginator import Paginator
from django.db import IntegrityError
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.urls import reverse
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from order.models import Order
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from utils.permissions import IsLibrarian, IsVisitorOrLibrarian
from django.views.decorators.csrf import csrf_exempt
from .models import CustomUser
from .serializers import EmailTokenObtainPairSerializer, LoginSerializer, RegisterSerializer, PasswordResetSerializer, \
    CustomUserSerializer


@swagger_auto_schema(
    method='post',
    request_body=LoginSerializer,
    responses={
        200: openapi.Response('Login successful', examples={'application/json': {'message': 'Login successful'}}),
        400: 'Validation errors'
    },
    operation_summary="Authenticate user and create session",
    operation_description="User login with username and password. Creates session cookie on success."
)
@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        login(request, user)
        return Response({'message': 'Login successful'}, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@swagger_auto_schema(
    method='post',
    request_body=RegisterSerializer,
    responses={
        201: openapi.Response(
            description="Registration successful",
            examples={'application/json': {
                'message': 'Registration successful. Please check your email to activate your account.',
                'uidb64': 'encoded-user-id',
                'token': 'activation-token'
            }}
        ),
        400: 'Validation errors',
        500: openapi.Response(
            description="Internal server error",
            examples={'application/json': {'detail': 'Some error occurred.'}}
        ),
    },
    operation_summary="User registration",
    operation_description="Register a new user. Sends activation email on success."
)
@permission_classes([AllowAny])
@api_view(['POST'])
def register_view(request):
    serializer = RegisterSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        try:
            user = serializer.save()
            user.is_active = False
            user.save()
        except IntegrityError:
            return Response({'detail': 'Some error occurred.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        uid = urlsafe_base64_encode(force_bytes(user.pk))
        token = default_token_generator.make_token(user)
        activation_link = request.build_absolute_uri(
            reverse('authentication:activate', args=[uid, token])
        )

        send_mail(
            subject="Activate your BookNest account",
            message=(
                f"Hi {user.first_name},\n\n"
                f"Please click the link below to activate your account:\n\n"
                f"{activation_link}\n\n"
                "If you didn't register, just ignore this email."
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )

        return Response({
            'message': 'Registration successful. Please check your email to activate your account.',
            'uidb64': uid,
            'token': token
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@swagger_auto_schema(
    method='post',
    responses={
        200: openapi.Response(
            description="Logout successful",
            examples={'application/json': {"message": "Successfully logged out."}}
        ),
        401: 'Unauthorized'
    },
    operation_summary="User logout",
    operation_description="Logs out the current authenticated user by ending the session."
)
@api_view(['POST'])
@permission_classes([IsVisitorOrLibrarian])
def logout_view(request):
    logout(request)
    return Response({"message": "Successfully logged out."}, status=status.HTTP_200_OK)


query_param = openapi.Parameter(
    'q', openapi.IN_QUERY, description="Search query for user id, first name, or last name", type=openapi.TYPE_STRING,
    required=True
)

page_param = openapi.Parameter(
    'page', openapi.IN_QUERY, description="Page number for pagination", type=openapi.TYPE_INTEGER, required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[query_param, page_param],
    responses={
        200: openapi.Response(
            description="List of users with pagination and optional filtering",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={
                    'results': openapi.Schema(
                        type=openapi.TYPE_ARRAY,
                        items=openapi.Schema(type=openapi.TYPE_OBJECT)
                    ),
                    'page': openapi.Schema(type=openapi.TYPE_INTEGER),
                    'pages': openapi.Schema(type=openapi.TYPE_INTEGER),
                    'has_next': openapi.Schema(type=openapi.TYPE_BOOLEAN),
                    'has_previous': openapi.Schema(type=openapi.TYPE_BOOLEAN),
                    'filtered': openapi.Schema(type=openapi.TYPE_BOOLEAN),
                    'query': openapi.Schema(type=openapi.TYPE_STRING),
                    'total': openapi.Schema(type=openapi.TYPE_INTEGER),
                }
            )
        ),
        403: 'Permission denied'
    },
    operation_summary="List all users",
    operation_description="Retrieve paginated list of users with optional search filter."
)
@permission_classes([IsLibrarian])
@api_view(['GET'])
def show_all_users(request):
    if request.user.role != 1:
        return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

    query = request.GET.get('q', '').strip()
    users = CustomUser.objects.all()
    filtered = False

    if query:
        filtered = True
        filters = (
                Q(id__iexact=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query)
        )

        parts = query.split()
        if len(parts) >= 2:
            first, last = parts[0], parts[1]
            filters |= Q(first_name__icontains=first, last_name__icontains=last)
            filters |= Q(first_name__icontains=last, last_name__icontains=first)

        try:
            filters |= Q(id=int(query))
        except ValueError:
            pass

        users = users.filter(filters).distinct()

    paginator = Paginator(users, 12)
    page_number = request.GET.get("page")
    page_obj = paginator.get_page(page_number)

    serializer = CustomUserSerializer(page_obj.object_list, many=True)

    return Response({
        "results": serializer.data,
        "page": page_obj.number,
        "pages": paginator.num_pages,
        "has_next": page_obj.has_next(),
        "has_previous": page_obj.has_previous(),
        "filtered": filtered,
        "query": query,
        "total": paginator.count,
    })


user_id_param = openapi.Parameter(
    'user_id', openapi.IN_PATH, description="ID of the user to retrieve", type=openapi.TYPE_INTEGER, required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[user_id_param],
    responses={
        200: openapi.Response('User details', CustomUserSerializer),
        404: 'User not found',
        403: 'Permission denied',
    },
    operation_summary="Retrieve user by ID",
    operation_description="Retrieve detailed information about a user by their ID."
)
@permission_classes([IsLibrarian])
@api_view(['GET'])
def user_detail(request, user_id):
    user = get_object_or_404(CustomUser, pk=user_id)
    serializer = CustomUserSerializer(user)
    return Response(serializer.data, status=status.HTTP_200_OK)


user_id_param = openapi.Parameter(
    'user_id', openapi.IN_PATH, description="ID of the user to update", type=openapi.TYPE_INTEGER, required=True
)


@swagger_auto_schema(
    method='put',
    manual_parameters=[user_id_param],
    request_body=CustomUserSerializer,
    responses={
        200: openapi.Response('User updated successfully', CustomUserSerializer),
        400: 'Validation errors',
        403: 'Permission denied',
        404: 'User not found',
    },
    operation_summary="Update user by ID",
    operation_description="Update user information by ID. Only the user themselves or librarians (role=1) can update."
)
@permission_classes([IsLibrarian])
@api_view(['PUT'])
def user_update(request, user_id):
    user = get_object_or_404(CustomUser, pk=user_id)

    if request.user != user and request.user.role != 1:
        return Response({"detail": "You can't update this user."}, status=status.HTTP_403_FORBIDDEN)

    serializer = CustomUserSerializer(user, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


user_id_param = openapi.Parameter(
    'user_id', openapi.IN_PATH, description="ID of the user to delete", type=openapi.TYPE_INTEGER, required=True
)


@swagger_auto_schema(
    method='delete',
    manual_parameters=[user_id_param],
    responses={
        204: openapi.Response(description="User deleted successfully"),
        403: 'Only admin can delete users',
        404: 'User not found',
    },
    operation_summary="Delete user by ID",
    operation_description="Delete a user by ID. Only admin (role=1) can perform this operation."
)
@permission_classes([IsLibrarian])
@api_view(['DELETE'])
def user_delete(request, user_id):
    user = get_object_or_404(CustomUser, pk=user_id)

    if request.user.role != 1:
        return Response({"detail": "Only admin can delete users."}, status=status.HTTP_403_FORBIDDEN)

    user.delete()
    return Response({"message": "User deleted."}, status=status.HTTP_204_NO_CONTENT)


@swagger_auto_schema(
    method='post',
    request_body=PasswordResetSerializer,
    responses={
        200: openapi.Response(
            description="Password reset email sent",
            examples={'application/json': {'message': 'Password reset email sent.'}}
        ),
        400: 'Validation errors'
    },
    operation_summary="Request password reset email",
    operation_description="Request a password reset email by providing user's email."
)
@permission_classes([AllowAny])
@api_view(['POST'])
def forgot_password(request):
    serializer = PasswordResetSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        serializer.save(request=request)
        return Response({'message': 'Password reset email sent.'}, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


uidb64_param = openapi.Parameter(
    'uidb64', openapi.IN_PATH, description="Base64 encoded user ID", type=openapi.TYPE_STRING, required=True
)

token_param = openapi.Parameter(
    'token', openapi.IN_PATH, description="Account activation token", type=openapi.TYPE_STRING, required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[uidb64_param, token_param],
    responses={
        200: openapi.Response(
            description="Account activated successfully",
            examples={'application/json': {'message': 'Account activated successfully.'}}
        ),
        400: openapi.Response(
            description="Invalid or expired token",
            examples={'application/json': {'error': 'Invalid or expired activation link.'}}
        ),
    },
    operation_summary="Activate user account",
    operation_description="Activate a user account using the encoded user ID and token sent via email."
)
@permission_classes([AllowAny])
@api_view(['GET'])
def activate(request, uidb64, token):
    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = CustomUser.objects.get(pk=uid)
    except Exception:
        user = None

    if user is not None and default_token_generator.check_token(user, token):
        user.is_active = True
        user.save()
        login(request, user)
        return Response({'message': 'Account activated successfully.'}, status=status.HTTP_200_OK)
    else:
        return Response({'error': 'Invalid or expired activation link.'}, status=status.HTTP_400_BAD_REQUEST)


@swagger_auto_schema(
    method='post',
    request_body=EmailTokenObtainPairSerializer,
    responses={
        200: openapi.Response(
            description="JWT access and refresh tokens",
            examples={
                'application/json': {
                    'access': 'eyJ0eXAiOiJKV1QiLCJhbGciOi...',
                    'refresh': 'eyJ0eXAiOiJKV1QiLCJhbGciOi...'
                }
            }
        ),
        401: openapi.Response(
            description="Invalid credentials",
            examples={'application/json': {'non_field_errors': ['No active account found with the given credentials']}}
        )
    },
    operation_summary="Obtain JWT tokens",
    operation_description="Obtain JWT access and refresh tokens using email and password."
)
@permission_classes([AllowAny])
@api_view(['POST'])
def custom_token_obtain_pair(request):
    serializer = EmailTokenObtainPairSerializer(data=request.data)

    if serializer.is_valid():
        return Response(serializer.validated_data, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)


@swagger_auto_schema(
    method='post',
    request_body=TokenRefreshSerializer,
    responses={
        200: openapi.Response(
            description="New JWT access token",
            examples={
                'application/json': {
                    'access': 'eyJ0eXAiOiJKV1QiLCJhbGciOi...'
                }
            }
        ),
        401: openapi.Response(
            description="Invalid or expired refresh token",
            examples={'application/json': {'detail': 'Token is invalid or expired'}}
        )
    },
    operation_summary="Refresh access JWT token",
    operation_description="Refresh the access token using a valid refresh token."
)
@permission_classes([AllowAny])
@api_view(['POST'])
def custom_token_refresh(request):
    serializer = TokenRefreshSerializer(data=request.data)
    if serializer.is_valid():
        return Response(serializer.validated_data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)
