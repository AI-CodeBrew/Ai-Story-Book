from datetime import datetime, timezone

from pymongo import ReturnDocument

import bunny_storage
import mongo


def _serialize(doc):
    if not doc:
        return None
    doc = dict(doc)
    doc.pop('_id', None)
    created_at = doc.get('createdAt')
    if isinstance(created_at, datetime):
        doc['createdAt'] = created_at.isoformat()
    return doc


def save_story(story, visitor_id=None, source='website'):
    """Persist a fully-assembled story (real images already merged in).
    Upserts by the story's own `id` so re-saving the same id is idempotent.
    """
    db = mongo.get_db()
    story = bunny_storage.upload_story_images(story)
    doc = {
        'id': story['id'],
        'title': story['title'],
        'theme': story['theme'],
        'audioUrl': story.get('audioUrl', ''),
        'pages': story['pages'],
        'prompt': story.get('prompt'),
        'additionalContext': story.get('additionalContext'),
        'isDefault': False,
        'visitorId': visitor_id,
        'source': source,
        'createdAt': datetime.now(timezone.utc),
    }
    db.stories.update_one({'id': doc['id']}, {'$set': doc}, upsert=True)
    return _serialize(doc)


def get_story(story_id):
    db = mongo.get_db()
    return _serialize(db.stories.find_one({'id': story_id}))


def list_stories(is_default=None, limit=12):
    db = mongo.get_db()
    query = {}
    if is_default is not None:
        query['isDefault'] = is_default
    cursor = db.stories.find(query).sort('createdAt', -1).limit(limit)
    return [_serialize(doc) for doc in cursor]


def set_default(story_id, is_default):
    db = mongo.get_db()
    result = db.stories.find_one_and_update(
        {'id': story_id},
        {'$set': {'isDefault': bool(is_default)}},
        return_document=ReturnDocument.AFTER,
    )
    return _serialize(result)


def count_stories():
    db = mongo.get_db()
    return db.stories.count_documents({})
