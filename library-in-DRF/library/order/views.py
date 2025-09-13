import datetime
from datetime import datetime, timedelta

from book.models import Book
from book.serializers import BookSerializer
from django.core.paginator import Paginator
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.views.decorators.http import require_http_methods
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from utils.permissions import IsLibrarian, IsVisitor, IsVisitorOrLibrarian

from .models import Order
from .serializers import OrderCreateSerializer, OrderSearchSerializer, OrderSerializer

query_param = openapi.Parameter(
    'q',
    openapi.IN_QUERY,
    description="Search query: order id, book name, author name, user email/name, or date (YYYY-MM-DD)",
    type=openapi.TYPE_STRING,
    required=True,
)

page_param = openapi.Parameter(
    'page',
    openapi.IN_QUERY,
    description="Page number for pagination",
    type=openapi.TYPE_INTEGER,
    required=True,
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[query_param, page_param],
    responses={
        200: openapi.Response(
            description="Paginated list of orders",
            examples={
                "application/json": {
                    "orders": [
                        {
                            "id": 1,
                            "book": {
                                "id": 10,
                                "name": "Kobzar",
                                "count": 12,
                                "publication_year": 1840,
                                "authors": [
                                    {"id": 5, "name": "Taras", "surname": "Shevchenko", "patronymic": ""}
                                ]
                            },
                            "user": {
                                "id": 20,
                                "email": "user@example.com",
                                "first_name": "Ivan",
                                "last_name": "Ivanov"
                            },
                            "created_at": 1687785600,
                            "end_at": 1688208000,
                            "plated_end_at": 1688294400
                        }
                    ],
                    "page": 1,
                    "num_pages": 5,
                    "total_orders": 45,
                    "query": "Kobzar",
                    "filtered": True,
                    "selected_orders_choices": [{"id": "1", "label": "1"}]
                }
            }
        )
    },
    operation_summary="List all orders",
    operation_description="Get all orders with optional search and pagination."
)
@permission_classes([IsLibrarian])
@api_view(['GET'])
def all_orders(request):
    serializer = OrderSearchSerializer(data=request.GET)
    serializer.is_valid(raise_exception=True)
    query = serializer.validated_data.get('q', '').strip()

    orders = Order.objects.select_related('user', 'book').prefetch_related('book__authors').all().order_by("-id")

    if query:
        q_filters = Q(id__iexact=query) | \
                    Q(book__name__icontains=query) | \
                    Q(book__authors__name__icontains=query) | \
                    Q(book__authors__surname__icontains=query) | \
                    Q(user__email__icontains=query) | \
                    Q(user__first_name__icontains=query) | \
                    Q(user__last_name__icontains=query)

        if ' ' in query:
            first, last = query.split(' ', 1)
            q_filters |= Q(user__first_name__icontains=first) & Q(user__last_name__icontains=last)
            q_filters |= Q(book__authors__name__icontains=first) & Q(book__authors__surname__icontains=last)

        try:
            datetime.strptime(query, '%Y-%m-%d')
            q_filters |= Q(created_at__date=query)
        except ValueError:
            pass

        orders = orders.filter(q_filters).distinct('id')

    paginator = Paginator(orders, 10)
    page_number = request.GET.get('page') or 1
    page_obj = paginator.get_page(page_number)

    orders_data = []
    for order in page_obj.object_list:
        order_data = {
            'id': order.id,
            'book': BookSerializer(order.book).data,
            'user': {
                'id': order.user.id,
                'email': order.user.email,
                'first_name': order.user.first_name,
                'last_name': order.user.last_name,
            },
            'created_at': int(order.created_at.timestamp()) if order.created_at else None,
            'end_at': int(order.end_at.timestamp()) if order.end_at else None,
            'plated_end_at': int(order.plated_end_at.timestamp()) if order.plated_end_at else None,
        }
        orders_data.append(order_data)

    choices = [{'id': str(order.id), 'label': str(order.id)} for order in page_obj.object_list]

    response_data = {
        'orders': orders_data,
        'page': page_obj.number,
        'num_pages': paginator.num_pages,
        'total_orders': paginator.count,
        'query': query,
        'filtered': bool(query),
        'selected_orders_choices': choices,
    }

    return Response(response_data, status=status.HTTP_200_OK)


order_id_param = openapi.Parameter(
    'order_id',
    openapi.IN_PATH,
    description="ID of the order to retrieve",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[order_id_param],
    responses={
        200: openapi.Response(description="Order details", schema=OrderSerializer),
        404: openapi.Response(description="Order not found")
    },
    operation_summary="Retrieve an order by ID",
    operation_description="Retrieve a single order by its ID."
)
@permission_classes([IsLibrarian])
@api_view(['GET'])
def show_order(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    serializer = OrderSerializer(order)
    return Response(serializer.data, status=status.HTTP_200_OK)


@swagger_auto_schema(
    method='get',
    responses={
        200: openapi.Response(
            description="List of orders for the authenticated user",
            schema=OrderSerializer(many=True)
        ),
        401: "Unauthorized"
    },
    operation_summary="List own orders",
    operation_description="Retrieve orders for the currently authenticated user."
)
@permission_classes([IsVisitor])
@api_view(['GET'])
def show_own_orders(request):
    orders = Order.objects.filter(user=request.user).select_related('book')
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


def user_already_ordered_this_book(user, book_id):
    return Order.objects.filter(user=user, book_id=book_id, end_at__isnull=True).exists()


def get_books_not_ordered_by_user(user):
    active_ordered_books = Order.objects.filter(user=user, end_at__isnull=True).values_list('book_id', flat=True)
    return Book.objects.exclude(id__in=active_ordered_books)


order_create_request = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=['book', 'term'],
    properties={
        'book': openapi.Schema(type=openapi.TYPE_INTEGER, description='ID of the book to order'),
        'term': openapi.Schema(type=openapi.TYPE_INTEGER, description='Term of the order in days'),
    },
)

order_create_response_201 = openapi.Response(
    description="Order created successfully",
    schema=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        properties={
            'detail': openapi.Schema(type=openapi.TYPE_STRING)
        }
    )
)

order_create_response_400 = openapi.Response(description="Validation error or user ordered same book twice")
order_create_response_403 = openapi.Response(description="Admins cannot create orders")
order_create_response_500 = openapi.Response(description="Server error during order creation")


@swagger_auto_schema(
    method='post',
    request_body=order_create_request,
    responses={
        201: order_create_response_201,
        400: order_create_response_400,
        403: order_create_response_403,
        500: order_create_response_500,
    },
    operation_summary="Create a new order",
    operation_description="Create a new order for the authenticated visitor user."
)
@permission_classes([IsVisitor])
@api_view(['POST'])
def create_order(request):
    if request.user.role == 1:
        return Response(
            {"detail": "Admins cannot create orders."},
            status=status.HTTP_403_FORBIDDEN
        )

    serializer = OrderCreateSerializer(data=request.data)
    if serializer.is_valid():
        book = serializer.validated_data['book']
        term = serializer.validated_data['term']

        if user_already_ordered_this_book(request.user, book):
            return Response(
                {"error": "You cannot order the same book twice."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            order = Order(
                user=request.user,
                book=book,
                created_at=timezone.now(),
                plated_end_at=timezone.now() + timedelta(days=term)
            )
            order.save()
            return Response(
                {"detail": "Order created successfully."},
                status=status.HTTP_201_CREATED
            )
        except Exception as e:
            return Response(
                {"error": f"An error occurred: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    else:
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


selected_orders_param = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=['selected_orders'],
    properties={
        'selected_orders': openapi.Schema(
            type=openapi.TYPE_ARRAY,
            items=openapi.Schema(type=openapi.TYPE_INTEGER),
            description="List of order IDs to close"
        ),
    },
    description="Payload with selected order IDs to be closed"
)


@swagger_auto_schema(
    method='put',
    request_body=selected_orders_param,
    responses={
        200: openapi.Response(
            description="Orders successfully closed",
            examples={
                "application/json": {"detail": "3 order(s) successfully closed."}
            }
        ),
        400: openapi.Response(description="No orders selected or bad request"),
        403: openapi.Response(description="Permission denied")
    },
    operation_summary="Close selected orders",
    operation_description="Close selected orders by setting their end_at field to current time."
)
@permission_classes([IsLibrarian])
@api_view(['PUT'])
def close_orders(request):
    user = request.user
    if not (user.is_superuser or getattr(user, 'role', None) == 1):
        return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

    selected_ids = request.data.get('selected_orders', [])
    if not selected_ids:
        return Response({"warning": "No orders were selected."}, status=status.HTTP_400_BAD_REQUEST)

    orders_to_close = Order.objects.filter(id__in=selected_ids, end_at__isnull=True)
    count = orders_to_close.update(end_at=timezone.now())

    return Response({"detail": f"{count} order(s) successfully closed."}, status=status.HTTP_200_OK)


user_id_param = openapi.Parameter(
    'user_id',
    openapi.IN_PATH,
    description="ID user",
    type=openapi.TYPE_INTEGER,
    required=True
)

order_id_param = openapi.Parameter(
    'order_id',
    openapi.IN_PATH,
    description="ID order",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[user_id_param, order_id_param],
    responses={
        200: openapi.Response(
            description="User order details",
            schema=OrderSerializer
        ),
        404: openapi.Response(description="Order or user not found")
    },
    operation_summary="Get user order by user ID and order ID",
    operation_description="Get user order by user ID and order ID."
)
@permission_classes([IsLibrarian])
@api_view(['GET'])
def show_user_order(request, user_id, order_id):
    order = get_object_or_404(Order, id=order_id, user_id=user_id)
    serializer = OrderSerializer(order)
    return Response(serializer.data, status=status.HTTP_200_OK)


user_id_param = openapi.Parameter(
    'user_id',
    openapi.IN_PATH,
    description="ID user",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[user_id_param],
    responses={
        200: openapi.Response(
            description="User orders",
            schema=OrderSerializer(many=True)
        ),
        404: openapi.Response(description="User not found or they have no orders")
    },
    operation_summary="Get user orders",
    operation_description="Get all orders from a specific user by ID."
)
@permission_classes([IsLibrarian])
@api_view(['GET'])
def user_orders(request, user_id):
    orders = Order.objects.filter(user__id=user_id).select_related('book')
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


order_id_param = openapi.Parameter(
    'order_id',
    openapi.IN_PATH,
    description="ID of the order to update",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='put',
    manual_parameters=[order_id_param],
    request_body=OrderSerializer,
    responses={
        200: openapi.Response(
            description="Updated order data",
            schema=OrderSerializer
        ),
        400: openapi.Response(description="Invalid data"),
        404: openapi.Response(description="Order not found")
    },
    operation_summary="Update an existing order by its ID",
    operation_description="Update an existing order by its ID."
)
@permission_classes([IsVisitorOrLibrarian])
@api_view(['PUT'])
def update_order(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    serializer = OrderSerializer(order, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


order_id_param = openapi.Parameter(
    'order_id',
    openapi.IN_PATH,
    description="ID of the order to delete",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='delete',
    manual_parameters=[order_id_param],
    responses={
        204: openapi.Response(description="Order deleted successfully"),
        404: openapi.Response(description="Order not found"),
    },
    operation_summary="Delete an existing order by its ID",
    operation_description="Delete an existing order by its ID."
)
@permission_classes([IsVisitorOrLibrarian])
@api_view(['DELETE'])
def delete_order(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    order.delete()
    return Response({"detail": f"Order {order_id} deleted successfully."}, status=status.HTTP_204_NO_CONTENT)
