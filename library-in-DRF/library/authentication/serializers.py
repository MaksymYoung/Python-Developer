import re

from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.models import Group, Permission
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import send_mail
from django.core.validators import validate_email
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import CustomUser, ROLE_CHOICES


class UserSerializer(serializers.ModelSerializer):
    role_name = serializers.CharField(source='get_role_display', read_only=True)

    class Meta:
        model = CustomUser
        fields = [
            'id',
            'first_name',
            'middle_name',
            'last_name',
            'email',
            'role',
            'role_name',
            'is_active',
        ]
        read_only_fields = fields
        ref_name = "UserSerializerApiV1"


class CustomUserSerializer(serializers.ModelSerializer):
    password1 = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    password2 = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

    groups = serializers.PrimaryKeyRelatedField(queryset=Group.objects.all(), many=True, required=False)
    user_permissions = serializers.PrimaryKeyRelatedField(queryset=Permission.objects.all(), many=True, required=False)

    class Meta:
        model = CustomUser
        fields = [
            "id",
            "email",
            "first_name",
            "middle_name",
            "last_name",
            "role",
            "password1",
            "password2",
            "is_staff",
            "is_active",
            "groups",
            "user_permissions"
        ]
        read_only_fields = ["id"]

    def validate_required_names(first_name, last_name):
        if not first_name:
            raise serializers.ValidationError({"first_name": "First name is required."})
        if not last_name:
            raise serializers.ValidationError({"last_name": "Last name is required."})

    def validate(self, data):
        self.validate_required_names(data.get('first_name'), data.get('last_name'))

        password1 = data.get('password1')
        password2 = data.get('password2')
        if password1 != password2:
            raise serializers.ValidationError({"password2": "Passwords do not match."})

        validate_password(password1, user=self.instance)

        return data

    def create(self, validated_data):
        password = validated_data.pop('password1')
        validated_data.pop('password2')

        groups = validated_data.pop('groups', [])
        user_permissions = validated_data.pop('user_permissions', [])

        user = CustomUser(**validated_data)
        user.set_password(password)
        user.save()

        if groups:
            user.groups.set(groups)
        if user_permissions:
            user.user_permissions.set(user_permissions)

        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password1', None)
        validated_data.pop('password2', None)

        groups = validated_data.pop('groups', None)
        user_permissions = validated_data.pop('user_permissions', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if password:
            instance.set_password(password)

        instance.save()

        if groups is not None:
            instance.groups.set(groups)
        if user_permissions is not None:
            instance.user_permissions.set(user_permissions)

        return instance


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(
        max_length=255,
        required=True,
        help_text="Enter your registered email address."
    )
    password = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'},
        help_text="Enter your password."
    )

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        if not email or not password:
            raise serializers.ValidationError(_('Both email and password are required.'))

        user = authenticate(username=email, password=password)
        if not user:
            raise serializers.ValidationError(_('Invalid email or password.'))

        if not user.is_active:
            raise serializers.ValidationError(_('This account is disabled.'))

        attrs['user'] = user
        return attrs


class RegisterSerializer(serializers.Serializer):
    login = serializers.EmailField(max_length=255)
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(max_length=100)
    middle_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    role = serializers.ChoiceField(choices=ROLE_CHOICES)

    def validate_login(self, value):
        try:
            validate_email(value)
        except DjangoValidationError:
            raise serializers.ValidationError("Enter a valid email address.")
        if CustomUser.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email is already registered.")
        return value

    def validate_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long.")
        if not re.search(r"\d", value):
            raise serializers.ValidationError("Password must contain at least one digit.")
        if not re.search(r"[A-Z]", value):
            raise serializers.ValidationError("Password must contain at least one uppercase letter.")
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', value):
            raise serializers.ValidationError("Password must contain at least one special character.")
        return value

    def validate(self, attrs):
        if attrs.get('password') != attrs.get('confirm_password'):
            raise serializers.ValidationError("Passwords do not match.")

        pattern = re.compile(r'^([A-Za-z]{2,}|[A-Za-z]\.)$')
        for field in ['first_name', 'middle_name', 'last_name']:
            value = attrs.get(field)
            if not value:
                raise serializers.ValidationError({field: f"{field.replace('_', ' ').capitalize()} is required."})
            if not pattern.match(value):
                raise serializers.ValidationError({field: (
                    f"{field.replace('_', ' ').capitalize()} must be at least 2 letters, "
                    "or a single letter followed by a dot (e.g. 'A.')."
                )})
        return attrs

    def create(self, validated_data):
        validated_data.pop('confirm_password')

        user = CustomUser.objects.create_user(
            email=validated_data['login'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            middle_name=validated_data['middle_name'],
            last_name=validated_data['last_name'],
            role=validated_data['role'],
        )
        return user


class PasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField(
        max_length=255,
        required=True,
        help_text="Enter your registered email address."
    )

    def validate_email(self, value):
        if not CustomUser.objects.filter(email=value, is_active=True).exists():
            raise serializers.ValidationError("There is no active user with this email address.")
        return value

    def save(self, request):
        email = self.validated_data['email']
        user = CustomUser.objects.get(email=email, is_active=True)
        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))

        reset_url = f"{'https' if request.is_secure() else 'http'}://{request.get_host()}/reset/{uid}/{token}/"

        subject = "Password Reset Requested"
        message = (
            f"Hello,\n\n"
            f"You requested a password reset. Click the link below to reset your password:\n"
            f"{reset_url}\n\n"
            f"If you did not request this, please ignore this email.\n\n"
            f"Thank you."
        )

        send_mail(
            subject,
            message,
            None,
            [email],
            fail_silently=False,
        )


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'email'

    def validate(self, attrs):
        credentials = {
            'email': attrs.get('email'),
            'password': attrs.get('password')
        }

        user = authenticate(**credentials)

        if user is None:
            raise serializers.ValidationError('Invalid email or password.')

        if not user.is_active:
            raise serializers.ValidationError('This account is inactive.')

        attrs['username'] = attrs.get('email')

        data = super().validate(attrs)
        return {
            'access': data['access'],
            'refresh': data['refresh'],
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
            }
        }
