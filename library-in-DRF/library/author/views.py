from functools import reduce
from operator import and_

from book.models import Book
from django.db.models import Q
from django.shortcuts import get_object_or_404
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from utils.permissions import IsLibrarian

from .models import Author
from .serializers import AuthorSearchSerializer, CreateOrUpdateAuthorSerializer, DeleteAuthorSerializer
from book.serializers import BookSerializer
from utils.permissions import IsVisitorOrLibrarian


@swagger_auto_schema(
    method='post',
    request_body=CreateOrUpdateAuthorSerializer,
    responses={
        201: openapi.Response("Author created successfully", CreateOrUpdateAuthorSerializer),
        400: "Validation error"
    },
    operation_summary="Create a new author",
    operation_description="Create a new author."
)
@permission_classes([IsLibrarian])
@api_view(["POST"])
def create_author(request):
    serializer = CreateOrUpdateAuthorSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


author_id_param = openapi.Parameter(
    'author_id', openapi.IN_PATH, description="ID of the author to update", type=openapi.TYPE_INTEGER
)


@swagger_auto_schema(
    method='put',
    manual_parameters=[author_id_param],
    request_body=CreateOrUpdateAuthorSerializer,
    responses={
        200: openapi.Response("Author updated successfully", CreateOrUpdateAuthorSerializer),
        400: "Validation error",
        404: "Author not found"
    },
    operation_summary="Update an existing author by ID",
    operation_description="Update an existing author by ID."
)
@permission_classes([IsLibrarian])
@api_view(["PUT"])
def update_author(request, author_id):
    author = get_object_or_404(Author, pk=author_id, is_deleted=False)
    serializer = CreateOrUpdateAuthorSerializer(author, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


author_id_param = openapi.Parameter(
    'author_id', openapi.IN_PATH, description="ID of the author to retrieve", type=openapi.TYPE_INTEGER, required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[author_id_param],
    responses={
        200: openapi.Response(
            description="Author details with list of books",
            examples={
                "application/json": {
                    "author": {
                        "id": 3,
                        "name": "Lesya",
                        "surname": "Ukrainka",
                        "patronymic": "Petrovna",
                        "source_url": "https://example.com/lesya",
                    },
                    "books": [
                        {"id": 7, "title": "Contra spem spero"},
                        {"id": 9, "title": "Forest Song"},
                    ],
                    "action": "Show Author"
                }
            }
        ),
        404: openapi.Response(description="Author not found"),
    },
    operation_summary="Retrieve an existing author by ID",
    operation_description="Retrieve full information about an author by ID, including their books."
)
@permission_classes([IsVisitorOrLibrarian])
@api_view(["GET"])
def show_author(request, author_id):
    author = get_object_or_404(Author, pk=author_id, is_deleted=False)
    books = author.books.all()

    author_data = CreateOrUpdateAuthorSerializer(author).data
    books_data = BookSerializer(books, many=True).data

    return Response({
        "author": author_data,
        "books": books_data,
        "action": "Show Author"
    }, status=status.HTTP_200_OK)


query_param = openapi.Parameter(
    'q',
    openapi.IN_QUERY,
    description="Search by name, surname or patronymic (supports multiple words)",
    type=openapi.TYPE_STRING,
    required=True
)

page_param = openapi.Parameter(
    'page',
    openapi.IN_QUERY,
    description="Page number for pagination",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[query_param, page_param],
    responses={
        200: openapi.Response(
            description="Paginated list of authors",
            examples={
                "application/json": {
                    "count": 1,
                    "next": None,
                    "previous": None,
                    "results": [
                        {
                            "id": 1,
                            "name": "Ivan",
                            "surname": "Franko",
                            "patronymic": "Yakovych",
                            "source_url": "https://example.com/ivan"
                        }
                    ]
                }
            }
        )
    },
    operation_summary="List all authors",
    operation_description="Retrieve a paginated list of authors. Supports optional search by full name."
)
@permission_classes([IsVisitorOrLibrarian])
@api_view(["GET"])
def show_authors(request):
    serializer = AuthorSearchSerializer(data=request.GET)
    serializer.is_valid(raise_exception=True)

    query = serializer.validated_data.get('q', '').strip()
    authors = Author.objects.filter(is_deleted=False)

    if query:
        parts = query.split()
        combined_filters = [
            Q(name__icontains=part) | Q(surname__icontains=part) | Q(patronymic__icontains=part)
            for part in parts
        ]
        authors = authors.filter(reduce(and_, combined_filters)).distinct()

    authors = authors.order_by('surname', 'name')

    paginator = PageNumberPagination()
    paginator.page_size = 30
    result_page = paginator.paginate_queryset(authors, request)

    serialized = CreateOrUpdateAuthorSerializer(result_page, many=True)
    return paginator.get_paginated_response(serialized.data)


author_id_param = openapi.Parameter(
    'author_id',
    openapi.IN_PATH,
    description="ID of the author to delete",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='delete',
    manual_parameters=[author_id_param],
    responses={
        200: openapi.Response(
            description="Author marked as deleted successfully",
            examples={
                "application/json": {
                    "detail": "Successfully deleted author Ivan Franko!",
                    "author": {
                        "id": 1,
                        "name": "Ivan",
                        "surname": "Franko",
                        "patronymic": "Yakovych",
                        "source_url": "https://example.com/ivan"
                    }
                }
            }
        ),
        400: openapi.Response(
            description="Cannot delete author due to associated books",
            examples={
                "application/json": {
                    "detail": "Cannot delete author Ivan Franko — they have associated books."
                }
            }
        ),
        404: "Author not found"
    },
    operation_summary="Delete an existing author by ID",
    operation_description="Delete an author by ID only if they have no associated books. Performs soft delete by setting `is_deleted=True`."
)
@permission_classes([IsLibrarian])
@api_view(["DELETE"])
def delete_author(request, author_id):
    author = get_object_or_404(Author, pk=author_id, is_deleted=False)

    if author.books.exists():
        return Response(
            {"detail": f"Cannot delete author {author.name} {author.surname} — they have associated books."},
            status=status.HTTP_400_BAD_REQUEST
        )

    author.is_deleted = True
    author.save()

    return Response(
        {
            "detail": f"Successfully deleted author {author.name} {author.surname}!",
            "author": DeleteAuthorSerializer(author).data
        },
        status=status.HTTP_200_OK
    )
