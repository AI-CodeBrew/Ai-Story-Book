import os
import json
import base64
import requests
from typing import Optional, List, Dict, Any
from PIL import Image
import io

class GeminiImageService:
    def __init__(self):
        self._api_key = None
    
    def initialize(self, api_key: str):
        """Initialize the service with API key"""
        self._api_key = api_key
    
    def generate_gemini_image(self, prompt: str, images: Optional[List[bytes]] = None) -> Dict[str, Any]:
        """
        Generate image using Gemini API
        
        Args:
            prompt: Text prompt for image generation
            images: Optional list of image bytes for reference
            
        Returns:
            Dict with success status, image bytes, message, and error
        """
        # Always use API key from pool, not the initialized one
        from app import ApiKeyPool
        api_key = ApiKeyPool.get_key()
        if not api_key:
            # Fallback to initialized key if pool is empty
            if not self._api_key:
                return {
                    'success': False,
                    'error': 'No API key available in pool or initialized'
                }
            api_key = self._api_key
            print(f'Using fallback API key: {api_key[:10] if api_key else "None"}...')
        else:
            print(f'Using API key from pool: {api_key[:10] if api_key else "None"}...')
        
        url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-image:generateContent?key={api_key}'
        
        headers = {'Content-Type': 'application/json'}
        
        # Build request parts
        parts = [{"text": f"Generate a high-quality, detailed image: {prompt}"}]
        
        if images:
            for image_bytes in images:
                # Convert image bytes to base64
                image_base64 = base64.b64encode(image_bytes).decode('utf-8')
                parts.append({
                    "inlineData": {
                        "mimeType": "image/jpeg",
                        "data": image_base64
                    }
                })
        
        body = {
            "contents": [{"parts": parts}],
            "generationConfig": {
                "responseModalities": ["IMAGE", "TEXT"],
                "temperature": 0.7
            }
        }
        
        max_retries = 3
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                # Update URL with current API key (in case it was rotated)
                url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-image:generateContent?key={api_key}'
                
                print(f'Making API request to Gemini for prompt: {prompt} (attempt {retry_count + 1})')
                response = requests.post(url, headers=headers, json=body)
                print(f'API Response status: {response.status_code}')
                print(f'API Response body length: {len(response.text)}')
                
                # Check for rate limit status codes (429) and overload status (503)
                if response.status_code == 429:
                    print("🚨 Rate limit detected (HTTP 429)!")
                    
                    # Try to rotate the key
                    if ApiKeyPool.handle_rate_limit_error():
                        api_key = ApiKeyPool.get_key()
                        print(f"🔄 Retrying with rotated key: {api_key[:10]}...")
                        retry_count += 1
                        continue
                    else:
                        return {
                            'success': False,
                            'error': 'Rate limit exceeded and no alternative keys available'
                        }
                
                # Check for model overload (503)
                if response.status_code == 503:
                    print("🚨 Model overloaded detected (HTTP 503)!")
                    
                    # Try to rotate the key
                    if ApiKeyPool.handle_rate_limit_error():
                        api_key = ApiKeyPool.get_key()
                        print(f"🔄 Retrying with rotated key due to overload: {api_key[:10]}...")
                        retry_count += 1
                        continue
                    else:
                        return {
                            'success': False,
                            'error': 'Model overloaded and no alternative keys available'
                        }
                
                if response.status_code != 200:
                    error_text = response.text.lower()
                    
                    # Check for rate limit or overload in error message
                    if any(keyword in error_text for keyword in ['rate limit', 'quota', 'limit exceeded', 'too many requests', 'overloaded', 'unavailable']):
                        print("🚨 Rate limit or overload detected in error message!")
                        
                        # Try to rotate the key
                        if ApiKeyPool.handle_rate_limit_error():
                            api_key = ApiKeyPool.get_key()
                            print(f"🔄 Retrying with rotated key: {api_key[:10]}...")
                            retry_count += 1
                            continue
                        else:
                            return {
                                'success': False,
                                'error': 'Rate limit/overload exceeded and no alternative keys available'
                            }
                    
                    print(f'API Error: {response.text}')
                    return {
                        'success': False,
                        'error': f'API request failed with status {response.status_code}: {response.text}'
                    }
                
                data = response.json()
                print(f'Decoded response structure: {list(data.keys())}')
                
                # Check if response has candidates
                if 'candidates' not in data or not data['candidates']:
                    return {
                        'success': False,
                        'error': 'No candidates in API response'
                    }
                
                candidate = data['candidates'][0]
                print(f'Candidate keys: {list(candidate.keys())}')
                
                # Check for safety blocks
                if candidate.get('finishReason') in ['SAFETY', 'IMAGE_SAFETY']:
                    print(f"🛡️ Safety filter triggered for prompt: {prompt[:100]}...")
                    return {
                        'success': False,
                        'error': 'Image generation blocked due to safety filters.'
                    }
                
                # Check if content exists
                if 'content' not in candidate or 'parts' not in candidate['content']:
                    return {
                        'success': False,
                        'error': 'No content in API response'
                    }
                
                parts = candidate['content']['parts']
                print(f'Number of parts in response: {len(parts)}')
                
                # Look for image data in any part
                for i, part in enumerate(parts):
                    print(f'Part {i} keys: {list(part.keys())}')
                    
                    if 'inlineData' in part and 'data' in part['inlineData']:
                        base64_image = part['inlineData']['data']
                        print(f'Found image data, base64 length: {len(base64_image)}')
                        
                        try:
                            image_bytes = base64.b64decode(base64_image)
                            print(f'Successfully decoded image bytes: {len(image_bytes)}')
                            
                            # Validate that we have actual image data
                            if len(image_bytes) > 1000:
                                return {
                                    'success': True,
                                    'imageBytes': image_bytes,
                                    'message': 'Image generated successfully'
                                }
                            else:
                                print(f'Image bytes too small: {len(image_bytes)}')
                        except Exception as e:
                            print(f'Error decoding base64: {e}')
                
                return {
                    'success': False,
                    'error': 'No valid image data found in API response'
                }
                
            except Exception as e:
                error_str = str(e).lower()
                print(f'Exception in generate_gemini_image (attempt {retry_count + 1}): {e}')
                
                # Check if it's a rate limit or overload error
                if any(keyword in error_str for keyword in ['rate limit', 'quota', 'limit exceeded', 'too many requests', 'overloaded', 'unavailable']):
                    print("🚨 Rate limit or overload detected in exception!")
                    
                    # Try to rotate the key
                    if ApiKeyPool.handle_rate_limit_error():
                        api_key = ApiKeyPool.get_key()
                        print(f"🔄 Retrying with rotated key: {api_key[:10]}...")
                        retry_count += 1
                        continue
                    else:
                        return {
                            'success': False,
                            'error': 'Rate limit/overload exceeded and no alternative keys available'
                        }
                else:
                    # Non-rate-limit error, don't retry
                    return {
                        'success': False,
                        'error': f'Network or parsing error: {e}'
                    }
        
        return {
            'success': False,
            'error': f'Image generation failed after {max_retries} attempts with key rotation'
        }
