from django.db import models
from accounts.models import User

class Notification(models.Model):
    TYPES = [
        ('message', 'Nouveau message'),
        ('match', 'Nouveau match'),
        ('offre', 'Nouvelle offre'),
    ]
    destinataire = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='notifications'
    )
    type_notification = models.CharField(max_length=20, choices=TYPES)
    message = models.TextField()
    lu = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.type_notification} - {self.destinataire}"