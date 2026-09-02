import os
from pymongo import MongoClient, ASCENDING, DESCENDING

_client = None
_db = None


def get_db():
    """Return the shared MongoDB database handle, connecting lazily on first use."""
    global _client, _db
    if _db is None:
        uri = os.environ.get('MONGODB_URI')
        if not uri:
            raise RuntimeError('MONGODB_URI is not set')
        _client = MongoClient(uri, serverSelectionTimeoutMS=8000)
        _db = _client[os.environ.get('MONGODB_DB_NAME', 'ai_storybook')]
        ensure_indexes(_db)
    return _db


def ping():
    """Cheap connectivity check used by /api/health. Never raises."""
    try:
        get_db().command('ping')
        return True
    except Exception as e:
        print(f"Mongo ping failed: {e}")
        return False


def ensure_indexes(db):
    db.stories.create_index([('id', ASCENDING)], unique=True)
    db.stories.create_index([('isDefault', ASCENDING), ('createdAt', DESCENDING)])
    db.stories.create_index([('visitorId', ASCENDING)])

    db.feedback.create_index([('storyId', ASCENDING), ('submittedAt', DESCENDING)])

    db.visits.create_index([('createdAt', ASCENDING), ('visitorId', ASCENDING)])
    db.visits.create_index([('visitorId', ASCENDING)])

    db.admins.create_index([('email', ASCENDING)], unique=True)
