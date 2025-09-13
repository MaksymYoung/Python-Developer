from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, OrderViewSet, UserOrderDetailView

# Create a router and register our viewsets with it
router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')
router.register(r'orders', OrderViewSet, basename='order')

# The API URLs are now determined automatically by the router
urlpatterns = [
    path('', include(router.urls)),
    # Custom URL for user order detail endpoint
    path('user/<int:user_id>/order/<int:order_id>/', UserOrderDetailView.as_view(), name='user-order-detail'),
] 