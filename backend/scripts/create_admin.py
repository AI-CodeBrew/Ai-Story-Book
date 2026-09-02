"""One-off CLI to seed (or update) a single admin account.

Usage:
    python scripts/create_admin.py <email> <password>

Run from the backend/ directory so `mongo.py` and the .env file resolve.
"""
import os
import sys
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from werkzeug.security import generate_password_hash

import mongo


def main():
    if len(sys.argv) != 3:
        print('Usage: python scripts/create_admin.py <email> <password>')
        sys.exit(1)

    email, password = sys.argv[1], sys.argv[2]
    if len(password) < 8:
        print('Password must be at least 8 characters.')
        sys.exit(1)

    db = mongo.get_db()
    db.admins.update_one(
        {'email': email},
        {'$set': {
            'email': email,
            'passwordHash': generate_password_hash(password),
            'createdAt': datetime.now(timezone.utc),
        }},
        upsert=True,
    )
    print(f'Admin account ready: {email}')


if __name__ == '__main__':
    main()
