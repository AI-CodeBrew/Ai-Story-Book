from datetime import datetime, timezone

from bson import ObjectId
from bson.errors import InvalidId
from werkzeug.security import generate_password_hash, check_password_hash

import mongo


def _serialize(user):
    if not user:
        return None
    created_at = user.get('createdAt')
    return {
        'id': str(user['_id']),
        'email': user['email'],
        'name': user.get('name', ''),
        'authProvider': user.get('authProvider', 'password'),
        'createdAt': created_at.isoformat() if isinstance(created_at, datetime) else created_at,
    }


def get_user_by_email(email):
    db = mongo.get_db()
    return db.users.find_one({'email': email.lower().strip()})


def get_user_by_id(user_id):
    db = mongo.get_db()
    try:
        return db.users.find_one({'_id': ObjectId(user_id)})
    except InvalidId:
        return None


def signup(email, password, name):
    email = (email or '').lower().strip()
    if not email or '@' not in email:
        raise ValueError('A valid email is required')
    if not password or len(password) < 6:
        raise ValueError('Password must be at least 6 characters')
    if get_user_by_email(email):
        raise ValueError('Email already registered')

    db = mongo.get_db()
    now = datetime.now(timezone.utc)
    doc = {
        'email': email,
        'passwordHash': generate_password_hash(password),
        'name': (name or email.split('@')[0]).strip(),
        'googleId': None,
        'authProvider': 'password',
        'createdAt': now,
        'lastLoginAt': now,
    }
    result = db.users.insert_one(doc)
    doc['_id'] = result.inserted_id
    return doc


def login(email, password):
    user = get_user_by_email(email)
    if not user or not user.get('passwordHash'):
        return None
    if not check_password_hash(user['passwordHash'], password):
        return None
    db = mongo.get_db()
    db.users.update_one({'_id': user['_id']}, {'$set': {'lastLoginAt': datetime.now(timezone.utc)}})
    return user


def find_or_create_google_user(claims):
    db = mongo.get_db()
    google_id = claims['sub']
    email = claims.get('email', '').lower().strip()
    now = datetime.now(timezone.utc)

    user = db.users.find_one({'googleId': google_id})
    if user:
        db.users.update_one({'_id': user['_id']}, {'$set': {'lastLoginAt': now}})
        return user

    user = get_user_by_email(email) if email else None
    if user:
        db.users.update_one(
            {'_id': user['_id']},
            {'$set': {'googleId': google_id, 'authProvider': 'both', 'lastLoginAt': now}},
        )
        user['googleId'] = google_id
        user['authProvider'] = 'both'
        return user

    doc = {
        'email': email,
        'passwordHash': None,
        'name': claims.get('name') or (email.split('@')[0] if email else 'User'),
        'googleId': google_id,
        'authProvider': 'google',
        'createdAt': now,
        'lastLoginAt': now,
    }
    result = db.users.insert_one(doc)
    doc['_id'] = result.inserted_id
    return doc
