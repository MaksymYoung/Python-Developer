from django.core.management.base import BaseCommand
from authentication.models import CustomUser
from order.models import Order
from book.models import Book


class Command(BaseCommand):

    def handle(self, *args, **options):
        librarian, created = CustomUser.objects.get_or_create(
            email='librarian@example.com',
            defaults={
                'first_name': 'Larysa',
                'last_name': 'Bibliotekar',
                'middle_name': 'Ivanivna',
                'is_active': True,
                'is_staff': True,
                'role': 1
            }
        )
        if created:
            librarian.set_password('librarianpass')
            librarian.save()
            self.stdout.write(self.style.SUCCESS("Created librarian user: librarian@example.com"))

        visitor, created = CustomUser.objects.get_or_create(
            email='visitor@example.com',
            defaults={
                'first_name': 'Vasyl',
                'last_name': 'Chytach',
                'middle_name': 'Petrovych',
                'is_active': True,
                'is_staff': False,
                'role': 0
            }
        )
        if created:
            visitor.set_password('visitorpass')
            visitor.save()
            self.stdout.write(self.style.SUCCESS("Created visitor user: visitor@example.com"))
