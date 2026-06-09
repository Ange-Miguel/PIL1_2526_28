from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Notification
from .serializers import NotificationSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def mes_notifications(request):
    notifications = Notification.objects.filter(
        destinataire=request.user
    ).order_by('-date_creation')
    serializer = NotificationSerializer(notifications, many=True)
    return Response(serializer.data)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def marquer_lu(request, notif_id):
    notification = Notification.objects.get(id=notif_id)
    notification.lu = True
    notification.save()
    return Response({'message': 'Notification marquée comme lue'})