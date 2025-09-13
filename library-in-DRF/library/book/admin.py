from author.models import Author
from django.contrib import admin
from django.contrib.admin import SimpleListFilter
from django.contrib.admin.views.main import ChangeList
from django.db.models import Count
from django.shortcuts import redirect
from django.urls import reverse
from django.views.decorators.csrf import csrf_exempt
from .models import Book
import plotly.graph_objs as go


class AuthorInlineAdmin(admin.TabularInline):
    model = Book.authors.through
    extra = 1
    verbose_name = "Author"
    verbose_name_plural = "Authors"


class AuthorsFilter(SimpleListFilter):
    title = "Authors"
    parameter_name = "author"

    def lookups(self, request, model_admin):
        authors = Author.objects.all()
        return [(str(author.id), f"{author.name} {author.surname}") for author in authors]

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(authors__id=self.value()).distinct()
        return queryset


@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ["id", 'name', "get_authors", "publication_year", 'count']

    def get_authors(self, obj):
        return ", ".join([f"{author.name} {author.surname}" for author in obj.authors.all()])

    get_authors.short_description = "Authors"

    list_display_links = ['name']

    list_filter = ("id", AuthorsFilter, "publication_year")

    search_fields = ['id', 'name', 'authors__name', 'authors__surname']
    list_editable = ['count']
    ordering = ['id']

    inlines = [AuthorInlineAdmin]
