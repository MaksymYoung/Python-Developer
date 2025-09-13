from functools import reduce
from operator import and_

from authentication.models import CustomUser
from author.models import Author
from django.core.paginator import Paginator
from django.db.models import Q
from django.shortcuts import get_object_or_404
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from order.models import Order
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from utils.cleaning import clean_str_field

from .models import Book
from .serializers import BookSearchSerializer, BookSerializer, CreateOrUpdateBookSerializer, DeleteBookSerializer
from utils.permissions import IsLibrarian, IsVisitorOrLibrarian

query_param = openapi.Parameter(
    'q',
    openapi.IN_QUERY,
    description="Search by book name or author full name (can contain multiple words or a number for count)",
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
            description="List of books with pagination",
            examples={
                "application/json": {
                    "books": [
                        {
                            "id": 1,
                            "name": "Kobzar",
                            "count": 12,
                            "authors": [
                                {"id": 3, "name": "Taras", "surname": "Shevchenko", "patronymic": ""}
                            ]
                        }
                    ],
                    "page": 1,
                    "num_pages": 1,
                    "total_books": 1,
                    "query": "Kobzar",
                    "filtered": True
                }
            }
        ),
        404: openapi.Response(
            description="No books found for the given query",
            examples={
                "application/json": {
                    "detail": "No books found for your search: 'some unknown author'"
                }
            }
        )
    },
    operation_summary="List all books",
    operation_description="Retrieve a list of books. Supports search by name or author and pagination (9 per page)."
)
@permission_classes([IsVisitorOrLibrarian])
@api_view(["GET"])
def show_books(request):
    serializer = BookSearchSerializer(data=request.GET)
    serializer.is_valid(raise_exception=True)
    query = serializer.validated_data.get('q', '').strip()

    books = Book.objects.filter(is_deleted=False).prefetch_related('authors')

    if query:
        if query.isdigit():
            books = books.filter(count=int(query))
        else:
            parts = query.split()
            combined_filters = [
                Q(name__icontains=part) |
                Q(authors__name__icontains=part) |
                Q(authors__surname__icontains=part) |
                Q(authors__patronymic__icontains=part)
                for part in parts
            ]
            books = books.filter(reduce(and_, combined_filters)).distinct()

        if not books.exists():
            return Response(
                {"detail": f"No books found for your search: '{query}'"},
                status=status.HTTP_404_NOT_FOUND
            )

    page = request.GET.get('page', 1)
    paginator = Paginator(books, 9)
    page_obj = paginator.get_page(page)
    books_data = BookSerializer(page_obj, many=True).data

    return Response({
        "books": books_data,
        "page": page_obj.number,
        "num_pages": paginator.num_pages,
        "total_books": paginator.count,
        "query": query,
        "filtered": bool(query)
    })


book_id_param = openapi.Parameter(
    'book_id',
    openapi.IN_PATH,
    description="ID of the book to retrieve",
    type=openapi.TYPE_INTEGER,
    required=True
)


@swagger_auto_schema(
    method='get',
    manual_parameters=[book_id_param],
    responses={
        200: openapi.Response(
            description="Detailed book information",
            examples={
                "application/json": {
                    "id": 5,
                    "name": "Kobzar",
                    "count": 12,
                    "authors": [
                        {
                            "id": 1,
                            "name": "Taras",
                            "surname": "Shevchenko",
                            "patronymic": ""
                        }
                    ],
                    "source_url": "https://example.com/kobzar"
                }
            }
        ),
        404: openapi.Response(description="Book not found")
    },
    operation_summary="Retrieve a book by ID",
    operation_description="Retrieve a single book by ID. Includes author information."
)
@permission_classes([IsVisitorOrLibrarian])
@api_view(['GET'])
def book_detail(request, book_id):
    book = get_object_or_404(Book, pk=book_id, is_deleted=False)
    serializer = BookSerializer(book)
    return Response(serializer.data, status=status.HTTP_200_OK)


book_id_param = openapi.Parameter(
    'book_id', openapi.IN_PATH, description="ID of the book to update", type=openapi.TYPE_INTEGER, required=True
)


@swagger_auto_schema(
    method='post',
    request_body=CreateOrUpdateBookSerializer,
    responses={
        201: openapi.Response(
            description="Book created successfully",
            schema=CreateOrUpdateBookSerializer
        ),
        400: "Validation error"
    },
    operation_summary="Create a new book",
    operation_description="Create a new book with authors."
)
@permission_classes([IsLibrarian])
@api_view(['POST'])
def create_book(request):
    serializer = CreateOrUpdateBookSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    authors_ids = request.data.get('authors', [])
    if not authors_ids or not isinstance(authors_ids, list):
        return Response(
            {"authors": ["You must provide a list of author IDs and select at least one author."]},
            status=status.HTTP_400_BAD_REQUEST
        )

    authors = Author.objects.filter(id__in=authors_ids, is_deleted=False)
    if authors.count() != len(authors_ids):
        return Response(
            {"authors": ["One or more authors not found or deleted."]},
            status=status.HTTP_400_BAD_REQUEST
        )

    name = clean_str_field(serializer.validated_data.get('name'))
    publication_year = serializer.validated_data.get('publication_year')

    existing_books = Book.objects.filter(
        name__iexact=name,
        publication_year=publication_year
    )

    submitted_authors_ids = set(authors_ids)
    for existing in existing_books:
        existing_authors_ids = set(existing.authors.values_list('id', flat=True))
        if existing_authors_ids == submitted_authors_ids:
            return Response(
                {"non_field_errors": ["A book with this title, authors, and publication year already exists."]},
                status=status.HTTP_400_BAD_REQUEST
            )

    book = serializer.save()
    book.authors.set(authors)

    return Response(CreateOrUpdateBookSerializer(book).data, status=status.HTTP_201_CREATED)


book_id_param = openapi.Parameter(
    'book_id', openapi.IN_PATH, description="ID of the book to update", type=openapi.TYPE_INTEGER
)


@swagger_auto_schema(
    method='put',
    manual_parameters=[book_id_param],
    request_body=CreateOrUpdateBookSerializer,
    responses={
        200: openapi.Response(
            description="Book updated successfully",
            schema=CreateOrUpdateBookSerializer
        ),
        400: "Validation error",
        404: "Book not found"
    },
    operation_summary="Update a book by ID",
    operation_description="Update an existing book by ID."
)
@permission_classes([IsLibrarian])
@api_view(['PUT'])
def update_book(request, book_id):
    book_instance = get_object_or_404(Book, pk=book_id)

    serializer = CreateOrUpdateBookSerializer(instance=book_instance, data=request.data)
    serializer.is_valid(raise_exception=True)

    authors_ids = request.data.get('authors', [])
    if not authors_ids or not isinstance(authors_ids, list):
        return Response(
            {"authors": ["You must provide a list of author IDs and select at least one author."]},
            status=status.HTTP_400_BAD_REQUEST
        )

    authors = Author.objects.filter(id__in=authors_ids, is_deleted=False)
    if authors.count() != len(authors_ids):
        return Response(
            {"authors": ["One or more authors not found or deleted."]},
            status=status.HTTP_400_BAD_REQUEST
        )

    name = clean_str_field(serializer.validated_data.get('name'))
    publication_year = serializer.validated_data.get('publication_year')

    existing_books = Book.objects.filter(
        name__iexact=name,
        publication_year=publication_year
    ).exclude(pk=book_instance.pk)

    submitted_authors_ids = set(authors_ids)
    for existing in existing_books:
        existing_authors_ids = set(existing.authors.values_list('id', flat=True))
        if existing_authors_ids == submitted_authors_ids:
            return Response(
                {"non_field_errors": ["A book with this title, authors, and publication year already exists."]},
                status=status.HTTP_400_BAD_REQUEST
            )

    book = serializer.save()
    book.authors.set(authors)

    return Response(CreateOrUpdateBookSerializer(book).data, status=status.HTTP_200_OK)


@swagger_auto_schema(
    method='delete',
    manual_parameters=[book_id_param],
    responses={
        200: openapi.Response(
            description="Book marked as deleted successfully",
            examples={
                "application/json": {
                    "detail": "The book 'Kobzar' was successfully marked as deleted.",
                    "book": {
                        "id": 1,
                        "name": "Kobzar",
                        "authors": "Shevchenko, Ivanenko",
                        "label": "Kobzar (Shevchenko, Ivanenko)"
                    }
                }
            }
        ),
        404: openapi.Response(description="Book not found")
    },
    operation_summary="Delete a book by ID",
    operation_description="Soft delete a book by setting is_deleted to True."
)
@permission_classes([IsLibrarian])
@api_view(['DELETE'])
def delete_book(request, book_id):
    book = get_object_or_404(Book, pk=book_id, is_deleted=False)
    book.is_deleted = True
    book.save()

    return Response(
        {
            "detail": f"The book '{book.name}' was successfully marked as deleted.",
            "book": DeleteBookSerializer(book).data
        },
        status=status.HTTP_200_OK
    )
