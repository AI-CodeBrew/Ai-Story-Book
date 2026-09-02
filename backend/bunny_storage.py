import base64
import os
import re

import requests

DATA_URL_RE = re.compile(r"^data:image/(?P<ext>[a-zA-Z0-9.+-]+);base64,(?P<data>.+)$", re.DOTALL)


def _config():
    zone = os.environ.get("BUNNY_STORAGE_ZONE")
    hostname = os.environ.get("BUNNY_STORAGE_HOSTNAME", "storage.bunnycdn.com")
    access_key = os.environ.get("BUNNY_STORAGE_ACCESS_KEY")
    pull_zone_hostname = os.environ.get("BUNNY_PULL_ZONE_HOSTNAME")
    if not (zone and access_key and pull_zone_hostname):
        return None
    return {
        "zone": zone,
        "hostname": hostname,
        "access_key": access_key,
        "pull_zone_hostname": pull_zone_hostname,
    }


def is_configured() -> bool:
    return _config() is not None


def upload_data_url(data_url: str, path: str) -> str | None:
    """Uploads a `data:image/...;base64,...` string to Bunny Storage and
    returns its public CDN URL, or None if not configured / upload failed.
    Never raises — callers should fall back to keeping the original data URL.
    """
    config = _config()
    if not config:
        return None

    match = DATA_URL_RE.match(data_url)
    if not match:
        return None

    try:
        ext = match.group("ext").split("+")[0]
        if ext not in ("jpeg", "jpg", "png", "webp"):
            ext = "jpg"
        image_bytes = base64.b64decode(match.group("data"))

        upload_url = f"https://{config['hostname']}/{config['zone']}/{path}.{ext}"
        response = requests.put(
            upload_url,
            data=image_bytes,
            headers={
                "AccessKey": config["access_key"],
                "Content-Type": "application/octet-stream",
            },
            timeout=20,
        )
        if response.status_code not in (200, 201):
            print(f"Bunny upload failed ({response.status_code}): {response.text[:200]}")
            return None

        return f"https://{config['pull_zone_hostname']}/{path}.{ext}"
    except Exception as e:
        print(f"Bunny upload error: {e}")
        return None


def upload_story_images(story: dict) -> dict:
    """Replaces any inline base64 page images with Bunny CDN URLs in-place.
    Pages that fail to upload (or Bunny isn't configured) keep their
    original imageUrl untouched.
    """
    if not is_configured():
        return story

    story_id = story.get("id", "unknown")
    for page in story.get("pages", []):
        image_url = page.get("imageUrl")
        if image_url and image_url.startswith("data:image"):
            path = f"stories/{story_id}/page-{page.get('pageNumber', 0)}"
            cdn_url = upload_data_url(image_url, path)
            if cdn_url:
                page["imageUrl"] = cdn_url
    return story
