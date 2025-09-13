from django.urls import path
from . import views

app_name = 'author'

urlpatterns = [
    path('author/', views.create_author, name='create_author'),
    path('author/<int:author_id>/update/', views.update_author, name='update_author'),
    path('authors/', views.show_authors, name='show_authors'),
    path('author/<int:author_id>/delete/', views.delete_author, name='delete_author'),
    path('author/<int:author_id>/', views.show_author, name='show_author')
]
