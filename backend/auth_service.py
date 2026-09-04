import os
from datetime import datetime, timedelta, timezone
from functools import wraps

import jwt
from flask import request, jsonify
from werkzeug.security import check_password_hash
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

import mongo

TOKEN_TTL_HOURS = 8
USER_TOKEN_TTL_DAYS = 30


def _secret():
    secret = os.environ.get('JWT_SECRET')
    if not secret:
        raise RuntimeError('JWT_SECRET is not set')
    return secret


def verify_admin(email, password):
    db = mongo.get_db()
    admin = db.admins.find_one({'email': email})
    if not admin or not check_password_hash(admin['passwordHash'], password):
        return None
    return admin


def create_token(admin):
    payload = {
        'sub': str(admin['_id']),
        'email': admin['email'],
        'role': 'admin',
        'exp': datetime.now(timezone.utc) + timedelta(hours=TOKEN_TTL_HOURS),
        'iat': datetime.now(timezone.utc),
    }
    return jwt.encode(payload, _secret(), algorithm='HS256')


def create_user_token(user):
    payload = {
        'sub': str(user['_id']),
        'email': user['email'],
        'role': 'user',
        'exp': datetime.now(timezone.utc) + timedelta(days=USER_TOKEN_TTL_DAYS),
        'iat': datetime.now(timezone.utc),
    }
    return jwt.encode(payload, _secret(), algorithm='HS256')


def decode_token(token):
    return jwt.decode(token, _secret(), algorithms=['HS256'])


def require_admin(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        header = request.headers.get('Authorization', '')
        if not header.startswith('Bearer '):
            return jsonify({'success': False, 'error': 'Missing admin token'}), 401
        token = header[len('Bearer '):]
        try:
            payload = decode_token(token)
        except jwt.ExpiredSignatureError:
            return jsonify({'success': False, 'error': 'Token expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'success': False, 'error': 'Invalid token'}), 401
        if payload.get('role') != 'admin':
            return jsonify({'success': False, 'error': 'Invalid token'}), 401
        request.admin = payload
        return fn(*args, **kwargs)
    return wrapper


def require_user(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        header = request.headers.get('Authorization', '')
        if not header.startswith('Bearer '):
            return jsonify({'success': False, 'error': 'Login required'}), 401
        token = header[len('Bearer '):]
        try:
            payload = decode_token(token)
        except jwt.ExpiredSignatureError:
            return jsonify({'success': False, 'error': 'Token expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'success': False, 'error': 'Invalid token'}), 401
        if payload.get('role') != 'user':
            return jsonify({'success': False, 'error': 'Invalid token'}), 401
        request.user = payload
        return fn(*args, **kwargs)
    return wrapper


def try_decode_admin(req):
    """Non-throwing admin check used by public endpoints that behave
    differently for admins (e.g. listing every story instead of only
    public ones). Returns the token payload if valid, else None."""
    header = req.headers.get('Authorization', '')
    if not header.startswith('Bearer '):
        return None
    try:
        payload = decode_token(header[len('Bearer '):])
    except jwt.PyJWTError:
        return None
    return payload if payload.get('role') == 'admin' else None


def verify_google_id_token(token_str):
    client_id = os.environ.get('GOOGLE_CLIENT_ID')
    if not client_id:
        raise RuntimeError('GOOGLE_CLIENT_ID is not set')
    return google_id_token.verify_oauth2_token(token_str, google_requests.Request(), client_id)
