from rest_framework import serializers
from urllib.parse import urlparse
import re

from .models import Author
from utils.cleaning import clean_str_field


class CreateOrUpdateAuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = ['id', 'name', 'surname', 'patronymic', 'source_url']

    def validate(self, data):
        name = clean_str_field(data.get('name'))
        surname = clean_str_field(data.get('surname'))
        patronymic = clean_str_field(data.get('patronymic'))
        author_url = clean_str_field(data.get('source_url'))

        if not (name or surname or patronymic):
            raise serializers.ValidationError("Please fill at least one of the fields: name, surname, or patronymic.")

        for value, field in [(name, 'name'), (surname, 'surname'), (patronymic, 'patronymic')]:
            if value and re.search(r'\d', value):
                raise serializers.ValidationError({field: "This field cannot contain digits."})
            if value and len(value) > 20:
                raise serializers.ValidationError({field: 'Maximum length is 20 characters.'})

        if author_url:
            parsed = urlparse(author_url)
            if parsed.scheme not in ['http', 'https'] or not parsed.netloc:
                raise serializers.ValidationError({'source_url': 'Invalid author URL.'})
            elif len(author_url) > 255:
                raise serializers.ValidationError({'source_url': 'URL is too long.'})

        existing = Author.objects.filter(
            name__iexact=name,
            surname__iexact=surname,
            patronymic__iexact=patronymic or None
        )
        if self.instance:
            existing = existing.exclude(pk=self.instance.pk)
        if existing.exists():
            raise serializers.ValidationError("Author with the same name, surname, and patronymic already exists.")

        data['name'] = name.capitalize() if name else None
        data['surname'] = surname.capitalize() if surname else None
        data['patronymic'] = patronymic.capitalize() if patronymic else None
        return data


class AuthorSearchSerializer(serializers.Serializer):
    q = serializers.CharField(required=False, allow_blank=True)


class DeleteAuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = ['id', 'name', 'surname', 'patronymic', 'source_url']


class AuthorSerializer(serializers.Serializer):
    author = serializers.PrimaryKeyRelatedField(
        queryset=Author.objects.filter(is_deleted=False)
    )

    def to_representation(self, instance):
        author = instance['author'] if isinstance(instance, dict) else instance
        return {
            'id': author.id,
            'name': author.name,
            'surname': author.surname,
            'patronymic': author.patronymic,
            'label': f"{author.name} {author.surname} {author.patronymic}"
        }


class AuthorListSerializer(serializers.Serializer):
    authors = AuthorSerializer(many=True)
