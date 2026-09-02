import os
from datetime import datetime, timedelta, timezone
from functools import wraps

import jwt
from flask import request, jsonify
from werkzeug.security import check_password_hash

import mongo

TOKEN_TTL_HOURS = 8


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
        'exp': datetime.now(timezone.utc) + timedelta(hours=TOKEN_TTL_HOURS),
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
        request.admin = payload
        return fn(*args, **kwargs)
    return wrapper
