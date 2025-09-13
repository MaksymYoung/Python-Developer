from rest_framework import permissions


class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object or admins/librarians to access it.
    """
    
    def has_object_permission(self, request, view, obj):
        # Admin users and librarians can access everything
        if request.user.is_staff or request.user.is_superuser or request.user.role == 1:
            return True
        
        # Check if the object has a user attribute (for orders)
        if hasattr(obj, 'user'):
            return obj.user == request.user
        
        # Check if the object is the user itself
        if hasattr(obj, 'id'):
            return obj.id == request.user.id
        
        return False


class IsOwnerOrAdminForUserOrders(permissions.BasePermission):
    """
    Custom permission for user order endpoints.
    Allows users to access their own orders and admins/librarians to access all orders.
    """
    
    def has_permission(self, request, view):
        # Admin users and librarians can access everything
        if request.user.is_staff or request.user.is_superuser or request.user.role == 1:
            return True
        
        # For user order endpoints, check if the user is accessing their own orders
        user_id = view.kwargs.get('pk')
        if user_id:
            return int(user_id) == request.user.id
        
        return False


class IsAdminOrLibrarian(permissions.BasePermission):
    """
    Custom permission that allows only admin users and librarians to access.
    """
    
    def has_permission(self, request, view):
        return request.user.is_staff or request.user.is_superuser or request.user.role == 1 