# Library API Documentation

This document describes the REST API endpoints for the Library management system.

## Base URL
```
http://127.0.0.1:8000/api/v1/
```

## Authentication
All API endpoints require authentication. The API supports:
- Session Authentication
- Basic Authentication

## User Roles and Permissions

### Role Types
- **Visitor (role=0)**: Regular users who can only access their own data
- **Librarian (role=1)**: Staff members with administrative privileges
- **Admin**: Django superusers with full system access

### Permission Levels
- **Regular Users (Visitors)**: Can only view and manage their own profile and orders
- **Librarians**: Have the same permissions as administrators - can manage all users and orders
- **Administrators**: Full system access (Django superusers)

## Endpoints

### User Management

#### Get User Details
- **URL**: `/users/{id}/`
- **Method**: `GET`
- **Description**: Get details of a specific user
- **Permissions**: Users can only access their own profile, librarians and admins can access all profiles

#### Create User
- **URL**: `/users/`
- **Method**: `POST`
- **Description**: Create a new user
- **Permissions**: Librarians and admins only

#### Update User
- **URL**: `/users/{id}/`
- **Method**: `PUT` / `PATCH`
- **Description**: Update user information
- **Permissions**: Librarians and admins only

#### Delete User
- **URL**: `/users/{id}/`
- **Method**: `DELETE`
- **Description**: Delete a user
- **Permissions**: Librarians and admins only

#### List Users
- **URL**: `/users/`
- **Method**: `GET`
- **Description**: List all users
- **Permissions**: Librarians and admins only

### User Orders

#### List User Orders
- **URL**: `/users/{id}/order/`
- **Method**: `GET`
- **Description**: Get all orders for a specific user
- **Permissions**: Users can only access their own orders, librarians and admins can access all orders

#### Create User Order
- **URL**: `/users/{id}/order/`
- **Method**: `POST`
- **Description**: Create a new order for a specific user
- **Permissions**: Users can only create orders for themselves, librarians and admins can create orders for any user

#### Get Specific User Order
- **URL**: `/user/{user_id}/order/{order_id}/`
- **Method**: `GET`
- **Description**: Get details of a specific order for a user
- **Permissions**: Users can only access their own orders, librarians and admins can access all orders

#### Update User Order
- **URL**: `/user/{user_id}/order/{order_id}/`
- **Method**: `PUT` / `PATCH`
- **Description**: Update a specific order for a user
- **Permissions**: Users can only update their own orders, librarians and admins can update any order

#### Delete User Order
- **URL**: `/user/{user_id}/order/{order_id}/`
- **Method**: `DELETE`
- **Description**: Delete a specific order for a user
- **Permissions**: Users can only delete their own orders, librarians and admins can delete any order

### Order Management

#### List Orders
- **URL**: `/orders/`
- **Method**: `GET`
- **Description**: List all orders
- **Permissions**: Users can only see their own orders, librarians and admins can see all orders

#### Create Order
- **URL**: `/orders/`
- **Method**: `POST`
- **Description**: Create a new order
- **Permissions**: Librarians and admins only

#### Get Order Details
- **URL**: `/orders/{id}/`
- **Method**: `GET`
- **Description**: Get details of a specific order
- **Permissions**: Users can only access their own orders, librarians and admins can access all orders

#### Update Order
- **URL**: `/orders/{id}/`
- **Method**: `PUT` / `PATCH`
- **Description**: Update order information
- **Permissions**: Librarians and admins only

#### Delete Order
- **URL**: `/orders/{id}/`
- **Method**: `DELETE`
- **Description**: Delete an order
- **Permissions**: Librarians and admins only

## Data Models

### User
```json
{
    "id": 1,
    "first_name": "John",
    "middle_name": "Doe",
    "last_name": "Smith",
    "email": "john@example.com",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z",
    "role": 0,
    "role_name": "visitor",
    "is_active": true
}
```

### Order
```json
{
    "id": 1,
    "book": 1,
    "book_title": "Sample Book",
    "user": 1,
    "user_email": "john@example.com",
    "created_at": "2023-01-01T00:00:00Z",
    "end_at": null,
    "plated_end_at": "2023-01-15T00:00:00Z"
}
```

## Error Responses

The API returns standard HTTP status codes:

- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Permission denied
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

Error responses include a `detail` field with a description of the error:

```json
{
    "detail": "You do not have permission to access this resource."
}
```

## Example Usage

### Get User Details
```bash
curl -X GET http://127.0.0.1:8000/api/v1/users/1/ \
     -H "Authorization: Basic <base64-encoded-credentials>"
```

### Create Order for User (Librarian/Admin only)
```bash
curl -X POST http://127.0.0.1:8000/api/v1/users/1/order/ \
     -H "Content-Type: application/json" \
     -H "Authorization: Basic <base64-encoded-credentials>" \
     -d '{"book": 1, "plated_end_at": "2023-01-15T00:00:00Z"}'
```

### Update User Order
```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/user/1/order/1/ \
     -H "Content-Type: application/json" \
     -H "Authorization: Basic <base64-encoded-credentials>" \
     -d '{"end_at": "2023-01-10T00:00:00Z"}'
```

## Role-Based Access Summary

| Action | Visitor | Librarian | Admin |
|--------|---------|-----------|-------|
| View own profile | ✅ | ✅ | ✅ |
| View own orders | ✅ | ✅ | ✅ |
| Create own orders | ✅ | ✅ | ✅ |
| Update own orders | ✅ | ✅ | ✅ |
| Delete own orders | ✅ | ✅ | ✅ |
| View all users | ❌ | ✅ | ✅ |
| Create users | ❌ | ✅ | ✅ |
| Update users | ❌ | ✅ | ✅ |
| Delete users | ❌ | ✅ | ✅ |
| View all orders | ❌ | ✅ | ✅ |
| Create orders for others | ❌ | ✅ | ✅ |
| Update any order | ❌ | ✅ | ✅ |
| Delete any order | ❌ | ✅ | ✅ | 