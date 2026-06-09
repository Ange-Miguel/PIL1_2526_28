from django.urls import path
from . import views

urlpatterns = [
    path('notifications/', views.mes_notifications, name='notifications'),
    path('notifications/<int:notif_id>/lu/', views.marquer_lu, name='marquer_lu'),
]