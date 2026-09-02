from datetime import datetime, timedelta, timezone

import mongo

VALID_EVENTS = {'pageview', 'story_generated', 'pdf_export', 'share', 'feedback_submitted'}
VALID_GRANULARITIES = {'day', 'week', 'month'}


def record_visit(visitor_id, path, event='pageview', user_agent=None, referrer=None):
    if not visitor_id:
        raise ValueError('visitorId is required')
    if event not in VALID_EVENTS:
        event = 'pageview'
    db = mongo.get_db()
    db.visits.insert_one({
        'visitorId': visitor_id,
        'path': path,
        'event': event,
        'userAgent': user_agent,
        'referrer': referrer,
        'createdAt': datetime.now(timezone.utc),
    })


def get_total_users():
    db = mongo.get_db()
    return len(db.visits.distinct('visitorId'))


def get_visitor_series(start, end, granularity='day'):
    if granularity not in VALID_GRANULARITIES:
        granularity = 'day'
    db = mongo.get_db()
    pipeline = [
        {'$match': {'createdAt': {'$gte': start, '$lte': end}}},
        {'$group': {
            '_id': {
                'period': {'$dateTrunc': {'date': '$createdAt', 'unit': granularity, 'timezone': 'UTC'}},
                'visitorId': '$visitorId',
            },
        }},
        {'$group': {'_id': '$_id.period', 'visitors': {'$sum': 1}}},
        {'$sort': {'_id': 1}},
    ]
    results = list(db.visits.aggregate(pipeline))
    return [
        {'period': row['_id'].isoformat() if isinstance(row['_id'], datetime) else row['_id'], 'visitors': row['visitors']}
        for row in results
    ]


def get_stats(start=None, end=None, granularity='day'):
    now = datetime.now(timezone.utc)
    if end is None:
        end = now
    if start is None:
        start = end - timedelta(days=30)

    db = mongo.get_db()
    series = get_visitor_series(start, end, granularity)

    return {
        'totalUsers': get_total_users(),
        'totalStories': db.stories.count_documents({}),
        'totalFeedback': db.feedback.count_documents({}),
        'rangeVisitors': len(db.visits.distinct('visitorId', {'createdAt': {'$gte': start, '$lte': end}})),
        'rangeVisits': db.visits.count_documents({'createdAt': {'$gte': start, '$lte': end}}),
        'start': start.isoformat(),
        'end': end.isoformat(),
        'granularity': granularity,
        'series': series,
    }
