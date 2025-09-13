from django.urls import path, reverse_lazy
from django.contrib.auth import views as auth_views
from . import views

app_name = 'authentication'

urlpatterns = [
    path('token/', views.custom_token_obtain_pair, name='custom_token_obtain_pair'),
    path('token/refresh/', views.custom_token_refresh, name='token_refresh'),
    path('login/', views.login_view, name='login'),
    path('register/', views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),
    path('api/v1/users/', views.show_all_users, name='show_all_users'),
    path('api/v1/user/<int:user_id>/', views.user_detail, name='specific_user'),
    path('forgot-password/', views.forgot_password, name='password_reset'
    ),
    path(
        'forgot-password/done/',
        auth_views.PasswordResetDoneView.as_view(
            template_name='authentication/password_reset_done.html'
        ),
        name='password_reset_done'
    ),
    path(
        'reset/<uidb64>/<token>/',
        auth_views.PasswordResetConfirmView.as_view(
            template_name='authentication/password_reset_confirm.html',
            success_url=reverse_lazy('authentication:password_reset_complete')
        ),
        name='password_reset_confirm'
    ),
    path(
        'forgot-password/complete/',
        auth_views.PasswordResetCompleteView.as_view(
            template_name='authentication/password_reset_complete.html'
        ),
        name='password_reset_complete'
    ),
    path('activate/<uidb64>/<token>/', views.activate, name='activate')
]
