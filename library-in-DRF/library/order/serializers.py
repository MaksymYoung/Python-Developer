from book.models import Book
from rest_framework import serializers
from .models import Order
from authentication.serializers import UserSerializer
from book.serializers import BookSerializer

from authentication.models import CustomUser


class OrderSearchSerializer(serializers.Serializer):
    q = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text='Search by Order ID, Date, Book, Author, User Email or Name'
    )


class OrderCreateSerializer(serializers.ModelSerializer):
    user = serializers.CharField(write_only=True, required=False, default='')

    book = serializers.PrimaryKeyRelatedField(
        queryset=Book.objects.filter(is_deleted=False),
        required=True,
        label="Select Book"
    )

    term = serializers.IntegerField(
        min_value=1,
        max_value=14,
        label="Order Duration (days)",
        help_text="Enter number of days between 1 and 14"
    )

    class Meta:
        model = Order
        fields = ['user', 'book', 'term']

    def validate_term(self, value):
        if not (1 <= value <= 14):
            raise serializers.ValidationError("Term must be between 1 and 14 days.")
        return value


class OrderSerializer(serializers.ModelSerializer):
    book = BookSerializer(read_only=True)
    book_id = serializers.PrimaryKeyRelatedField(
        queryset=Book.objects.all(), source='book', write_only=True
    )

    user = UserSerializer(read_only=True)
    user_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(), source='user', write_only=True
    )

    created_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", read_only=True)
    end_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", allow_null=True, required=False)
    plated_end_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M:%S", read_only=True)

    penalty = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'book', 'book_id', 'user', 'user_id',
            'created_at', 'end_at', 'plated_end_at', 'penalty'
        ]
        ref_name = 'OrderSerializerInApiV1'

    def get_penalty(self, obj):
        return obj.calculate_penalty()
