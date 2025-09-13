from rest_framework import serializers
from authentication.models import CustomUser
from order.models import Order


class UserSerializer(serializers.ModelSerializer):
    """
    Serializer for CustomUser model
    
    Handles serialization and deserialization of user data including
    personal information, role, and account status.
    """
    role_name = serializers.CharField(
        source='get_role_display', 
        read_only=True,
        help_text="Human-readable role name (visitor or librarian)"
    )
    
    class Meta:
        model = CustomUser
        fields = [
            'id', 'first_name', 'middle_name', 'last_name', 
            'email', 'created_at', 'updated_at', 'role', 
            'role_name', 'is_active'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
        extra_kwargs = {
            'first_name': {
                'help_text': 'User\'s first name (max 20 characters)',
                'max_length': 20
            },
            'middle_name': {
                'help_text': 'User\'s middle name (max 20 characters, optional)',
                'max_length': 20,
                'required': False
            },
            'last_name': {
                'help_text': 'User\'s last name (max 20 characters)',
                'max_length': 20
            },
            'email': {
                'help_text': 'User\'s email address (must be unique)',
                'max_length': 100
            },
            'role': {
                'help_text': 'User role: 0 for visitor, 1 for librarian'
            },
            'is_active': {
                'help_text': 'Whether the user account is active'
            }
        }
        ref_name = "UserSerializerAuthentication"


class OrderSerializer(serializers.ModelSerializer):
    """
    Serializer for Order model
    
    Handles serialization and deserialization of book order data including
    book reference, user reference, and order dates.
    """
    book_title = serializers.CharField(
        source='book.name', 
        read_only=True,
        help_text="Title of the ordered book"
    )
    user_email = serializers.CharField(
        source='user.email', 
        read_only=True,
        help_text="Email of the user who placed the order"
    )
    
    class Meta:
        model = Order
        fields = [
            'id', 'book', 'book_title', 'user', 'user_email',
            'created_at', 'end_at', 'plated_end_at'
        ]
        read_only_fields = ['id', 'created_at']
        extra_kwargs = {
            'book': {
                'help_text': 'ID of the book being ordered'
            },
            'user': {
                'help_text': 'ID of the user placing the order'
            },
            'end_at': {
                'help_text': 'Actual return date of the book (null if not returned)',
                'required': False
            },
            'plated_end_at': {
                'help_text': 'Planned return date of the book (2 weeks from creation)'
            }
        }
        ref_name = 'OrderSerializerInOrderApp'


class UserOrderSerializer(serializers.ModelSerializer):
    """
    Serializer for Order model when accessed through user endpoint
    
    Simplified version of OrderSerializer that excludes user information
    since it's already in the URL context.
    """
    book_title = serializers.CharField(
        source='book.name', 
        read_only=True,
        help_text="Title of the ordered book"
    )
    
    class Meta:
        model = Order
        fields = [
            'id', 'book', 'book_title', 'created_at', 
            'end_at', 'plated_end_at'
        ]
        read_only_fields = ['id', 'created_at']
        extra_kwargs = {
            'book': {
                'help_text': 'ID of the book being ordered'
            },
            'end_at': {
                'help_text': 'Actual return date of the book (null if not returned)',
                'required': False
            },
            'plated_end_at': {
                'help_text': 'Planned return date of the book (2 weeks from creation)'
            }
        } 