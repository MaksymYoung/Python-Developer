from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from authentication.models import CustomUser
from order.models import Order
from .serializers import UserSerializer, OrderSerializer, UserOrderSerializer
from .permissions import IsOwnerOrAdmin, IsOwnerOrAdminForUserOrders, IsAdminOrLibrarian


class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for User CRUD operations.
    
    Provides endpoints for managing library users including visitors and librarians.
    Regular users can only access their own profile, while librarians and admins can manage all users.
    """
    queryset = CustomUser.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrAdmin]
    http_method_names = ['post']

    def get_permissions(self):
        """
        Only admin users and librarians can create, update, delete users
        Regular users can only view their own profile
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminOrLibrarian()]
        return [IsAuthenticated(), IsOwnerOrAdmin()]
    
    def get_queryset(self):
        """
        Admin users and librarians can see all users, regular users can only see their own profile
        """
        if self.request.user.is_staff or self.request.user.is_superuser or self.request.user.role == 1:
            return CustomUser.objects.all()
        return CustomUser.objects.filter(id=self.request.user.id)
    
    @swagger_auto_schema(
        operation_summary="List all users",
        operation_description="Retrieve a list of all users in the library system. Only accessible to librarians and administrators.",
        responses={
            200: UserSerializer(many=True),
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only'
        }
    )
    def list(self, request, *args, **kwargs):
        """List all users (librarians and admins only)"""
        return super().list(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Create a new user",
        operation_description="Create a new user account in the library system. Only accessible to librarians and administrators.",
        request_body=UserSerializer,
        responses={
            201: UserSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only'
        }
    )
    def create(self, request, *args, **kwargs):
        """Create a new user (librarians and admins only)"""
        return super().create(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Get user details",
        operation_description="Retrieve detailed information about a specific user. Users can only view their own profile, while librarians and admins can view any user.",
        responses={
            200: UserSerializer,
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'User not found'
        }
    )
    def retrieve(self, request, *args, **kwargs):
        """Get user details"""
        return super().retrieve(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Update user information",
        operation_description="Update all fields of a user account. Only accessible to librarians and administrators.",
        request_body=UserSerializer,
        responses={
            200: UserSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only',
            404: 'User not found'
        }
    )
    def update(self, request, *args, **kwargs):
        """Update user information (librarians and admins only)"""
        return super().update(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Partially update user information",
        operation_description="Update specific fields of a user account. Only accessible to librarians and administrators.",
        request_body=UserSerializer,
        responses={
            200: UserSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only',
            404: 'User not found'
        }
    )
    def partial_update(self, request, *args, **kwargs):
        """Partially update user information (librarians and admins only)"""
        return super().partial_update(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Delete a user",
        operation_description="Permanently delete a user account from the library system. Only accessible to librarians and administrators.",
        responses={
            204: 'User deleted successfully',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only',
            404: 'User not found'
        }
    )
    def destroy(self, request, *args, **kwargs):
        """Delete a user (librarians and admins only)"""
        return super().destroy(request, *args, **kwargs)
    
    @swagger_auto_schema(
        method='get',
        operation_summary="List user orders",
        operation_description="Retrieve all orders for a specific user. Users can only view their own orders, while librarians and admins can view any user's orders.",
        responses={
            200: UserOrderSerializer(many=True),
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'User not found'
        }
    )
    @swagger_auto_schema(
        method='post',
        operation_summary="Create order for user",
        operation_description="Create a new order for a specific user. Users can only create orders for themselves, while librarians and admins can create orders for any user.",
        request_body=OrderSerializer,
        responses={
            201: OrderSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'User not found'
        }
    )
    @action(detail=True, methods=['get', 'post'], 
            permission_classes=[IsAuthenticated, IsOwnerOrAdminForUserOrders])
    def order(self, request, pk=None):
        """
        Handle orders for a specific user
        GET: List all orders for the user
        POST: Create a new order for the user
        """
        user = self.get_object()
        
        if request.method == 'GET':
            # List orders for the user
            orders = Order.objects.filter(user=user)
            serializer = UserOrderSerializer(orders, many=True)
            return Response(serializer.data)
        
        elif request.method == 'POST':
            # Create a new order
            serializer = OrderSerializer(data=request.data)
            if serializer.is_valid():
                # Set the user automatically
                serializer.save(user=user)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserOrderDetailView(APIView):
    """
    API view for handling individual orders within a user context.
    
    Provides endpoints for managing specific orders belonging to a user.
    Users can only access their own orders, while librarians and admins can access any user's orders.
    """
    permission_classes = [IsAuthenticated, IsOwnerOrAdminForUserOrders]
    
    @swagger_auto_schema(
        operation_summary="Get specific user order",
        operation_description="Retrieve detailed information about a specific order belonging to a user. Users can only view their own orders, while librarians and admins can view any user's orders.",
        responses={
            200: UserOrderSerializer,
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'User or order not found'
        }
    )
    def get(self, request, user_id, order_id):
        """Get a specific order for a user"""
        try:
            user = CustomUser.objects.get(id=user_id)
            order = Order.objects.get(id=order_id, user=user)
            serializer = UserOrderSerializer(order)
            return Response(serializer.data)
        except CustomUser.DoesNotExist:
            return Response(
                {"detail": "User not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Order.DoesNotExist:
            return Response(
                {"detail": "Order not found."},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @swagger_auto_schema(
        operation_summary="Update specific user order",
        operation_description="Update all fields of a specific order belonging to a user. Users can only update their own orders, while librarians and admins can update any user's orders.",
        request_body=OrderSerializer,
        responses={
            200: OrderSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'User or order not found'
        }
    )
    def put(self, request, user_id, order_id):
        """Update a specific order for a user"""
        try:
            user = CustomUser.objects.get(id=user_id)
            order = Order.objects.get(id=order_id, user=user)
            serializer = OrderSerializer(order, data=request.data)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except CustomUser.DoesNotExist:
            return Response(
                {"detail": "User not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Order.DoesNotExist:
            return Response(
                {"detail": "Order not found."},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @swagger_auto_schema(
        operation_summary="Partially update specific user order",
        operation_description="Update specific fields of a specific order belonging to a user. Users can only update their own orders, while librarians and admins can update any user's orders.",
        request_body=OrderSerializer,
        responses={
            200: OrderSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'User or order not found'
        }
    )
    def patch(self, request, user_id, order_id):
        """Partially update a specific order for a user"""
        try:
            user = CustomUser.objects.get(id=user_id)
            order = Order.objects.get(id=order_id, user=user)
            serializer = OrderSerializer(order, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except CustomUser.DoesNotExist:
            return Response(
                {"detail": "User not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Order.DoesNotExist:
            return Response(
                {"detail": "Order not found."},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @swagger_auto_schema(
        operation_summary="Delete specific user order",
        operation_description="Permanently delete a specific order belonging to a user. Users can only delete their own orders, while librarians and admins can delete any user's orders.",
        responses={
            204: 'Order deleted successfully',
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'User or order not found'
        }
    )
    def delete(self, request, user_id, order_id):
        """Delete a specific order for a user"""
        try:
            user = CustomUser.objects.get(id=user_id)
            order = Order.objects.get(id=order_id, user=user)
            order.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except CustomUser.DoesNotExist:
            return Response(
                {"detail": "User not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Order.DoesNotExist:
            return Response(
                {"detail": "Order not found."},
                status=status.HTTP_404_NOT_FOUND
            )


class OrderViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Order CRUD operations.
    
    Provides endpoints for managing library book orders.
    Regular users can only view their own orders, while librarians and admins can manage all orders.
    """
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrAdmin]
    http_method_names = ['patch']

    def get_permissions(self):
        """
        Only admin users and librarians can create, update, delete orders
        Regular users can only view their own orders
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminOrLibrarian()]
        return [IsAuthenticated(), IsOwnerOrAdmin()]
    
    def get_queryset(self):
        """
        Admin users and librarians can see all orders, regular users can only see their own orders
        """
        if self.request.user.is_staff or self.request.user.is_superuser or self.request.user.role == 1:
            return Order.objects.all()
        return Order.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        """
        Set the user automatically when creating an order
        """
        serializer.save(user=self.request.user)
    
    @swagger_auto_schema(
        operation_summary="List all orders",
        operation_description="Retrieve a list of all orders in the library system. Regular users can only see their own orders, while librarians and admins can see all orders.",
        responses={
            200: OrderSerializer(many=True),
            401: 'Authentication required',
            403: 'Permission denied'
        }
    )
    def list(self, request, *args, **kwargs):
        """List all orders"""
        return super().list(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Create a new order",
        operation_description="Create a new book order in the library system. Only accessible to librarians and administrators.",
        request_body=OrderSerializer,
        responses={
            201: OrderSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only'
        }
    )
    def create(self, request, *args, **kwargs):
        """Create a new order (librarians and admins only)"""
        return super().create(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Get order details",
        operation_description="Retrieve detailed information about a specific order. Regular users can only view their own orders, while librarians and admins can view any order.",
        responses={
            200: OrderSerializer,
            401: 'Authentication required',
            403: 'Permission denied',
            404: 'Order not found'
        }
    )
    def retrieve(self, request, *args, **kwargs):
        """Get order details"""
        return super().retrieve(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Update order information",
        operation_description="Update all fields of an order. Only accessible to librarians and administrators.",
        request_body=OrderSerializer,
        responses={
            200: OrderSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only',
            404: 'Order not found'
        }
    )
    def update(self, request, *args, **kwargs):
        """Update order information (librarians and admins only)"""
        return super().update(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Partially update order information",
        operation_description="Update specific fields of an order. Only accessible to librarians and administrators.",
        request_body=OrderSerializer,
        responses={
            200: OrderSerializer,
            400: 'Invalid data provided',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only',
            404: 'Order not found'
        }
    )
    def partial_update(self, request, *args, **kwargs):
        """Partially update order information (librarians and admins only)"""
        return super().partial_update(request, *args, **kwargs)
    
    @swagger_auto_schema(
        operation_summary="Delete an order",
        operation_description="Permanently delete an order from the library system. Only accessible to librarians and administrators.",
        responses={
            204: 'Order deleted successfully',
            401: 'Authentication required',
            403: 'Permission denied - librarians and admins only',
            404: 'Order not found'
        }
    )
    def destroy(self, request, *args, **kwargs):
        """Delete an order (librarians and admins only)"""
        return super().destroy(request, *args, **kwargs) 