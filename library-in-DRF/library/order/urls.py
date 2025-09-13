from django.urls import path
from . import views

urlpatterns = [
    path('orders/', views.all_orders, name='all_orders'),
    path('order/', views.create_order, name='create_order'),
    path('order/<int:order_id>/', views.show_order, name='show_order'),
    path('order/<int:order_id>/update/', views.update_order, name='update_order'),
    path('order/<int:order_id>/delete/', views.delete_order, name='delete_order'),
    path('user/orders/', views.show_own_orders, name='own_orders'),
    path('close/orders/', views.close_orders, name='close_orders'),
    path('user/<int:user_id>/orders/', views.user_orders, name='user_orders'),
    path('user/<int:user_id>/order/<int:order_id>/', views.show_user_order, name='show_user_order')
]