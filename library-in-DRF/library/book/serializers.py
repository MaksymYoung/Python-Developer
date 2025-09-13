from datetime import date
from urllib.parse import urlparse
from author.models import Author
from utils.cleaning import clean_str_field
from rest_framework import serializers
from .models import Book


class BookSearchSerializer(serializers.Serializer):
    q = serializers.CharField(
        required=False,
        allow_blank=True,
        label='Search'
    )


def validate_source_url_common(value):
    if value:
        parsed = urlparse(value)
        if parsed.scheme not in ['http', 'https'] or not parsed.netloc:
            raise serializers.ValidationError('Invalid source URL.')
        if len(value) > 255:
            raise serializers.ValidationError('URL is too long.')
    return value


def validate_date_of_issue_common(value):
    if value and value > date.today():
        raise serializers.ValidationError("Date of issue can't be in the future.")
    return value


def validate_count_common(value):
    if value < 1:
        raise serializers.ValidationError("Count must be more or equal 1.")
    return value


class BookLimitedUpdateSerializer(serializers.ModelSerializer):
    count = serializers.IntegerField(
        min_value=1,
        required=True,
        help_text="Non-negative integer. Quantity of books available."
    )
    source_url = serializers.URLField(
        required=False,
        allow_blank=True,
        help_text="Optional valid URL referencing the book source."
    )
    date_of_issue = serializers.DateField(
        required=False,
        allow_null=True,
        help_text="Date when the book was issued. Cannot be in the future."
    )

    class Meta:
        model = Book
        fields = ['count', 'source_url', 'date_of_issue']

    def validate_source_url(self, value):
        return validate_source_url_common(value)

    def validate_date_of_issue(self, value):
        return validate_date_of_issue_common(value)

    def validate_count(self, value):
        return validate_count_common(value)


class CreateOrUpdateBookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = ['id', 'name', 'description', 'count', 'publication_year', 'source_url', 'date_of_issue']

    def validate_name(self, value):
        value = clean_str_field(value)
        if len(value) > 128:
            raise serializers.ValidationError("Maximum length is 128 characters.")
        return value.capitalize()

    def validate_count(self, value):
        return validate_count_common(value)

    def validate_source_url(self, value):
        value = clean_str_field(value)
        return validate_source_url_common(value)

    def validate_publication_year(self, value):
        current_year = date.today().year
        if value > current_year:
            raise serializers.ValidationError("Publication year can't be in the future.")
        return value

    def validate_date_of_issue(self, value):
        return validate_date_of_issue_common(value)


class DeleteBookSerializer(serializers.Serializer):
    book = serializers.PrimaryKeyRelatedField(
        queryset=Book.objects.filter(is_deleted=False)
    )

    def to_representation(self, instance):
        book = instance['book'] if isinstance(instance, dict) else instance
        authors_surnames = ', '.join(a.surname for a in book.authors.all())
        return {
            'id': book.id,
            'name': book.name,
            'authors': authors_surnames,
            'label': f"{book.name} ({authors_surnames})"
        }


class BookSerializer(serializers.ModelSerializer):
    authors = serializers.SerializerMethodField()

    class Meta:
        model = Book
        fields = ['id', 'name', 'description', 'count', 'publication_year', 'source_url', 'date_of_issue', 'authors']

    def get_authors(self, obj):
        return [f"{author.name} {author.surname}" for author in obj.authors.all()]
