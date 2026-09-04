import os
import re
import json
import base64
import requests
from datetime import datetime
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from dotenv import load_dotenv
import google.generativeai as genai
from PIL import Image
import io

load_dotenv()

# Import our custom services
from gemini_image_service import GeminiImageService
from gemini_text_service import GeminiTextService
from feedback_service import FeedbackService
import mongo
import story_repository
import analytics_service
import auth_service
import user_service

app = Flask(__name__)
CORS(app)
# Enhanced API Key Pool with rotation for Python backend
class ApiKeyPool:
    _api_keys = []
    _current_key_index = 0
    _key_usage_count = {}
    _max_requests_per_key = 1000  # Adjust based on your API limits
    _keys_file = 'api_keys_pool.json'  # File to persist keys
    
    @staticmethod
    def _save_keys_to_file():
        """Save API keys to file for persistence"""
        try:
            import json
            data = {
                'api_keys': ApiKeyPool._api_keys,
                'current_key_index': ApiKeyPool._current_key_index,
                'key_usage_count': ApiKeyPool._key_usage_count,
                'timestamp': datetime.now().isoformat()
            }
            with open(ApiKeyPool._keys_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"💾 Saved {len(ApiKeyPool._api_keys)} keys to {ApiKeyPool._keys_file}")
        except Exception as e:
            print(f"❌ Error saving keys to file: {e}")
    
    @staticmethod
    def _load_keys_from_file():
        """Load API keys from file if available"""
        try:
            import json
            import os
            if not os.path.exists(ApiKeyPool._keys_file):
                print(f"📁 No saved keys file found: {ApiKeyPool._keys_file}")
                return False
            
            with open(ApiKeyPool._keys_file, 'r') as f:
                data = json.load(f)
            
            ApiKeyPool._api_keys = data.get('api_keys', [])
            ApiKeyPool._current_key_index = data.get('current_key_index', 0)
            ApiKeyPool._key_usage_count = data.get('key_usage_count', {})
            
            # Validate the loaded keys
            if ApiKeyPool._api_keys:
                print(f"📁 Loaded {len(ApiKeyPool._api_keys)} keys from file")
                print(f"🔑 Keys: {[key[:10] + '...' for key in ApiKeyPool._api_keys]}")
                return True
            else:
                print(f"📁 No valid keys found in saved file")
                return False
        except Exception as e:
            print(f"❌ Error loading keys from file: {e}")
            return False
    
    @staticmethod
    def init(app_name):
        """Initialize API Key Pool with app name"""
        print(f"API Key Pool initialized for app: {app_name}")
        
        # First, try to load keys from file
        if ApiKeyPool._load_keys_from_file():
            print(f"✅ Using saved keys from file")
            return
        
        # Don't override if we already have keys from frontend
        if ApiKeyPool._api_keys:
            print(f"✅ Pool already has {len(ApiKeyPool._api_keys)} keys, skipping fallback initialization")
            return
        
        # This should connect to your actual API Key Pool GitHub package
        # For now, we'll simulate the connection
        try:
            # In a real implementation, this would connect to your GitHub package
            # and retrieve the API keys for the specified app
            fallback_key = ApiKeyPool._get_fallback_key(app_name)
            if fallback_key:
                ApiKeyPool._api_keys = [fallback_key]
                ApiKeyPool._key_usage_count[fallback_key] = 0
                print(f"Fallback API key retrieved for app: {app_name}")
            else:
                print(f"No fallback API key found for app: {app_name}")
        except Exception as e:
            print(f"Error connecting to API Key Pool: {e}")
            ApiKeyPool._api_keys = []
    
    @staticmethod
    def _get_fallback_key(app_name):
        """Get fallback API key from environment or hardcoded"""
        try:
            # Check for environment variable first
            import os
            env_key = os.getenv('GEMINI_API_KEY')
            if env_key and env_key != 'your_gemini_api_key_here':
                return env_key
            
            # For development, check environment variable first
            if app_name == 'ai_storybook_backend':
                # Only use environment variable, no hardcoded fallback
                # This forces the system to use the pool keys from frontend
                return None  # No hardcoded fallback - must use pool keys
            return None
        except Exception as e:
            print(f"Error getting fallback key: {e}")
            return None
    
    @staticmethod
    def update_keys(api_keys):
        """Update the pool with multiple API keys from frontend"""
        if not api_keys or not isinstance(api_keys, list):
            print("❌ Invalid API keys provided")
            return False
        
        # Filter out empty or placeholder keys
        valid_keys = [key for key in api_keys if key and key.strip() and 
                     key != 'your_gemini_api_key_here' and 
                     key != 'your_actual_gemini_api_key_here']
        
        if not valid_keys:
            print("❌ No valid API keys found")
            return False
        
        ApiKeyPool._api_keys = valid_keys
        ApiKeyPool._current_key_index = 0
        ApiKeyPool._key_usage_count = {key: 0 for key in valid_keys}
        
        # Save keys to file for persistence
        ApiKeyPool._save_keys_to_file()
        
        print(f"✅ Updated API key pool with {len(valid_keys)} keys")
        print(f"🔑 Keys: {[key[:10] + '...' for key in valid_keys]}")
        return True
    
    @staticmethod
    def get_key():
        """Get current API key from the pool"""
        if not ApiKeyPool._api_keys:
            print("❌ No API keys available in pool")
            return None
        
        current_key = ApiKeyPool._api_keys[ApiKeyPool._current_key_index]
        
        # Increment usage count
        ApiKeyPool._key_usage_count[current_key] += 1
        
        print(f"🔑 Using pool key {ApiKeyPool._current_key_index + 1}/{len(ApiKeyPool._api_keys)}: {current_key[:10]}... (usage: {ApiKeyPool._key_usage_count[current_key]})")
        
        return current_key
    
    @staticmethod
    def rotate_key():
        """Rotate to the next API key when rate limit is hit"""
        if len(ApiKeyPool._api_keys) <= 1:
            print("⚠️ Only one key available, cannot rotate")
            return False
        
        old_index = ApiKeyPool._current_key_index
        old_key = ApiKeyPool._api_keys[old_index] if ApiKeyPool._api_keys else "None"
        
        # Move to next key
        ApiKeyPool._current_key_index = (ApiKeyPool._current_key_index + 1) % len(ApiKeyPool._api_keys)
        new_key = ApiKeyPool._api_keys[ApiKeyPool._current_key_index]
        
        print(f"🔄 Rotated from key {old_index + 1} ({old_key[:10]}...) to key {ApiKeyPool._current_key_index + 1} ({new_key[:10]}...)")
        
        # Reset the usage count for the rotated key
        ApiKeyPool._key_usage_count[new_key] = 0
        
        # Save updated state to file
        ApiKeyPool._save_keys_to_file()
        
        return True
    
    @staticmethod
    def get_pool_status():
        """Get status of the key pool"""
        return {
            'total_keys': len(ApiKeyPool._api_keys),
            'current_key_index': ApiKeyPool._current_key_index,
            'current_key_preview': ApiKeyPool._api_keys[ApiKeyPool._current_key_index][:10] + '...' if ApiKeyPool._api_keys else 'None',
            'usage_counts': {key[:10] + '...': count for key, count in ApiKeyPool._key_usage_count.items()},
            'available_keys': [key[:10] + '...' for key in ApiKeyPool._api_keys]
        }
    
    @staticmethod
    def handle_rate_limit_error():
        """Handle rate limit error by rotating key"""
        print("🚨 Rate limit detected! Attempting key rotation...")
        success = ApiKeyPool.rotate_key()
        if success:
            # Use helper function to update services
            ApiKeyPool._update_services_with_current_key()
        return success
    
    @staticmethod
    def _update_services_with_current_key():
        """Helper function to update all services with current key"""
        # This will be replaced by the actual function after services are initialized
        pass

# Initialize API Key Pool
ApiKeyPool.init('ai_storybook_backend')

# Initialize services
gemini_api_key = ApiKeyPool.get_key()
gemini_image_service = GeminiImageService()
gemini_text_service = GeminiTextService()

try:
    _mongo_db = mongo.get_db()
    print("MongoDB connected")
except Exception as e:
    _mongo_db = None
    print(f"Warning: MongoDB not available ({e}). Feedback will use the in-memory fallback and story/analytics routes will error until MONGODB_URI is reachable.")

feedback_service = FeedbackService(db=_mongo_db)

if gemini_api_key:
    gemini_image_service.initialize(gemini_api_key)
    gemini_text_service.initialize(gemini_api_key)
    genai.configure(api_key=gemini_api_key)
    print(f"Gemini API configured with key: {gemini_api_key[:10]}...")
else:
    print("Warning: No Gemini API key found. Running in development mode.")

# Now update the helper function to use the initialized services
def _update_services_with_current_key():
    """Helper function to update all services with current key"""
    current_key = ApiKeyPool.get_key()
    if current_key:
        global gemini_api_key
        gemini_api_key = current_key
        gemini_image_service.initialize(current_key)
        gemini_text_service.initialize(current_key)
        genai.configure(api_key=current_key)
        print(f"🔄 Services updated with rotated key: {current_key[:10]}...")

# Update the ApiKeyPool method to use this function
ApiKeyPool._update_services_with_current_key = _update_services_with_current_key

class StoryService:
    def __init__(self):
        self.model = genai.GenerativeModel(model_name='gemini-pro') if gemini_api_key else None
        self.image_model = genai.GenerativeModel(model_name='gemini-pro-vision') if gemini_api_key else None
    
    def generate_story(self, prompt, theme, additional_context=None):
        try:
            print(f"📖 Generating 10-page story for: {prompt}")
            
            # Generate 10 page scripts first
            pages, title = self._generate_10_page_scripts(prompt, theme, additional_context)

            # Images will be generated separately by frontend
            # Initialize all pages with placeholder images
            for page in pages:
                page['imageUrl'] = f'https://via.placeholder.com/400x300/4A90E2/FFFFFF?text=Page+{page["pageNumber"]}'
            
            # Generate audio (placeholder)
            audio_url = self._generate_audio(pages)
            
            return {
                'id': self._generate_id(),
                'title': title,
                'pages': pages,  # Now structured as pages with script + image
                'theme': theme,
                'audioUrl': audio_url,
                'createdAt': datetime.now().isoformat()
            }
        except Exception as e:
            raise Exception(f'Failed to generate story: {str(e)}')
    
    def _generate_10_page_scripts(self, prompt, theme, additional_context=None):
        """Generate exactly 10 page scripts for the story"""
        try:
            print("📝 Generating 10 page scripts...")
            
            story_prompt = f"""
Create a children's story with EXACTLY 10 pages based on this prompt: "{prompt}"
Theme: {theme}
{f"Additional context: {additional_context}" if additional_context else ""}

Requirements:
- Each page should have 2-4 sentences
- Suitable for children aged 4-8
- Clear narrative progression across all 10 pages
- Engaging and age-appropriate content
- Include dialogue and action
- Have a satisfying conclusion on page 10

Format your response as:
Title: [a short, catchy title for the story, under 8 words]
Page 1: [content for page 1]
Page 2: [content for page 2]
...
Page 10: [content for page 10]

Write an engaging {theme.lower()} story that flows naturally across all 10 pages.
"""

            if gemini_api_key:
                story_text = gemini_text_service.generate_text(story_prompt)
                title = self._extract_title(story_text, prompt)
            else:
                # Fallback for development
                story_text = self._generate_fallback_10_pages(prompt, theme)
                title = f"The {theme} Adventure"

            # Parse the response into individual pages
            pages = self._parse_story_pages(story_text)
            
            # Ensure we have exactly 10 pages
            while len(pages) < 10:
                pages.append({
                    'pageNumber': len(pages) + 1,
                    'script': f"And the adventure continued with {prompt}...",
                    'imageUrl': None
                })
            
            # Trim to exactly 10 pages if more were generated
            pages = pages[:10]

            print(f"✅ Generated {len(pages)} page scripts")
            return pages, title

        except Exception as e:
            print(f"❌ Error generating page scripts: {e}")
            return self._generate_fallback_10_pages(prompt, theme), f"The {theme} Adventure"
    
    def _parse_story_pages(self, story_text):
        """Parse AI response into individual pages"""
        pages = []
        lines = story_text.split('\n')
        current_page = 1
        current_content = ""
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            # Check if this line starts a new page
            if line.lower().startswith(f'page {current_page}:'):
                # Extract content after "Page X:"
                content = line.split(':', 1)[1].strip() if ':' in line else line
                if content:
                    pages.append({
                        'pageNumber': current_page,
                        'script': content,
                        'imageUrl': None
                    })
                    current_page += 1
            elif line.lower().startswith('page ') and ':' in line:
                # Handle "Page X:" format
                try:
                    page_num = int(line.lower().replace('page ', '').split(':')[0])
                    content = line.split(':', 1)[1].strip()
                    if content:
                        pages.append({
                            'pageNumber': page_num,
                            'script': content,
                            'imageUrl': None
                        })
                        current_page = page_num + 1
                except:
                    # If parsing fails, treat as content for current page
                    if current_content:
                        current_content += " " + line
                    else:
                        current_content = line
            else:
                # Continue content for current page
                if current_content:
                    current_content += " " + line
                else:
                    current_content = line
        
        # Add any remaining content as the last page
        if current_content and len(pages) < 10:
            pages.append({
                'pageNumber': len(pages) + 1,
                'script': current_content,
                'imageUrl': None
            })
        
        return pages
    
    def _generate_fallback_10_pages(self, prompt, theme):
        """Generate 10 fallback pages for development"""
        pages = []
        for i in range(10):
            pages.append({
                'pageNumber': i + 1,
                'script': f"Page {i + 1}: Once upon a time, there was a {prompt} in a {theme} world. This is page {i + 1} of our amazing story!",
                'imageUrl': None
            })
        return pages
    
    def _generate_images_for_pages(self, pages, theme):
        """Generate an image for each of the 10 pages"""
        try:
            print("🎨 Generating images for all 10 pages...")
            print(f"🔑 API key available: {bool(gemini_api_key)}")
            print(f"🔑 API key preview: {gemini_api_key[:10] if gemini_api_key else 'None'}...")
            
            for i, page in enumerate(pages):
                print(f"🖼️ Generating image for page {page['pageNumber']}...")
                
                # Build image prompt for this specific page
                image_prompt = self._build_image_prompt(page['script'], theme)
                print(f"📝 Image prompt: {image_prompt[:100]}...")
                
                # Generate image using our image service
                if gemini_api_key:
                    result = gemini_image_service.generate_gemini_image(image_prompt)
                    if result['success'] and result.get('imageBytes'):
                        # Convert image bytes to base64 for direct embedding
                        import base64
                        image_base64 = base64.b64encode(result['imageBytes']).decode('utf-8')
                        
                        # Update page with base64 data URL
                        page['imageUrl'] = f"data:image/jpeg;base64,{image_base64}"
                        page['imageBase64'] = image_base64  # Also provide raw base64
                        print(f'✅ Generated image for page {page["pageNumber"]} (base64: {len(image_base64)} chars)')
                    else:
                        print(f'❌ Image generation failed for page {page["pageNumber"]}: {result.get("error")}')
                        # Fallback to placeholder
                        page['imageUrl'] = f'https://via.placeholder.com/400x300/4A90E2/FFFFFF?text=Page+{page["pageNumber"]}'
                else:
                    # Fallback for development
                    page['imageUrl'] = f'https://via.placeholder.com/400x300/4A90E2/FFFFFF?text=Page+{page["pageNumber"]}'
                    
            print(f"✅ Completed image generation for all {len(pages)} pages")
            
        except Exception as e:
            print(f"❌ Error generating images: {e}")
            # Ensure all pages have at least placeholder images
            for i, page in enumerate(pages):
                if not page.get('imageUrl'):
                    page['imageUrl'] = f'https://via.placeholder.com/400x300/4A90E2/FFFFFF?text=Page+{page["pageNumber"]}'
    
    def _build_story_prompt(self, prompt, theme, additional_context):
        theme_prompts = {
            'Adventure': 'Write an exciting adventure story with brave characters, mysterious quests, and thrilling discoveries.',
            'Fantasy': 'Create a magical fantasy story with mystical creatures, enchanted worlds, and powerful magic.',
            'Space': 'Craft a space adventure story with futuristic technology, alien encounters, and cosmic exploration.',
            'Nature': 'Write a nature story about animals, plants, and the beauty of the natural world.',
            'Friendship': 'Create a heartwarming story about friendship, kindness, and helping others.',
            'Science': 'Write an educational story that teaches scientific concepts in an engaging way.',
        }
        
        theme_prompt = theme_prompts.get(theme, 'Write an engaging story')
        context = f' Additional context: {additional_context}' if additional_context else ''
        
        return f"""
{theme_prompt}

Story prompt: {prompt}
{context}

Please write a complete story with:
- An engaging beginning that hooks the reader
- A clear plot with interesting characters
- A satisfying ending
- Age-appropriate content
- Vivid descriptions that can be illustrated
- A title for the story

Make the story approximately 500-800 words long.
"""
    
    def _extract_title(self, story_text, prompt=''):
        """Pull the `Title: ...` line the prompt asked Gemini for. Falls back
        to a short snippet of the user's prompt if the model didn't include one."""
        match = re.search(r'(?im)^\s*title:\s*(.+?)\s*$', story_text)
        if match:
            title = match.group(1).strip().strip('"')
            if len(title) > 80:
                title = title[:80] + '...'
            return title

        fallback = prompt.strip() or 'Amazing Story'
        words = fallback.split()
        if len(words) > 8:
            fallback = ' '.join(words[:8]) + '...'
        return fallback.capitalize()
        return 'Amazing Story'
    
    # Old methods removed - now using 10-page workflow
    
    def _build_image_prompt(self, scene, theme):
        theme_styles = {
            'Adventure': 'adventure, action, exploration',
            'Fantasy': 'fantasy, magical, mystical',
            'Space': 'sci-fi, futuristic, space',
            'Nature': 'nature, peaceful, beautiful',
            'Friendship': 'warm, friendly, heartwarming',
            'Science': 'educational, scientific, colorful',
        }
        
        style = theme_styles.get(theme, 'beautiful, colorful')
        
        return f"""
Create a beautiful, detailed illustration for a children's story:
Scene: {scene}
Style: {style}, child-friendly, vibrant colors, detailed but simple
Format: High-quality digital art suitable for a storybook
"""
    
    def _generate_audio(self, pages):
        # Placeholder for audio generation - could combine all page scripts
        return 'https://example.com/audio/placeholder.mp3'
    
    def _generate_id(self):
        return str(int(datetime.now().timestamp() * 1000))

# Initialize story service
story_service = StoryService()

@app.route('/api/health', methods=['GET'])
def health_check():
    try:
        pool_status = ApiKeyPool.get_pool_status()
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'api_key_configured': bool(gemini_api_key),
            'key_pool_status': pool_status,
            'mongo_connected': mongo.ping()
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/api/keys/update', methods=['POST'])
def update_api_keys():
    """Endpoint to receive and update API keys from frontend"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No data provided'
            }), 400
        
        api_keys = data.get('api_keys', [])
        app_name = data.get('app_name', 'unknown')
        
        print(f"🔑 Received API key update request from: {app_name}")
        print(f"🔑 Number of keys received: {len(api_keys)}")
        
        if not api_keys:
            return jsonify({
                'success': False,
                'error': 'No API keys provided'
            }), 400
        
        # Update the API key pool
        success = ApiKeyPool.update_keys(api_keys)
        
        if success:
            # Immediately switch to using pool keys instead of fallback
            current_key = ApiKeyPool.get_key()
            if current_key:
                global gemini_api_key
                gemini_api_key = current_key  # Update the global variable
                gemini_image_service.initialize(current_key)
                gemini_text_service.initialize(current_key)
                genai.configure(api_key=current_key)
                print(f"✅ Switched to pool key: {current_key[:10]}... (now using {len(api_keys)} keys)")
            else:
                print("❌ Failed to get key from pool after update")
            
            pool_status = ApiKeyPool.get_pool_status()
            return jsonify({
                'success': True,
                'message': f'Successfully updated API key pool with {len(api_keys)} keys',
                'pool_status': pool_status
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to update API key pool'
            }), 400
            
    except Exception as e:
        print(f"❌ Error updating API keys: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/keys/status', methods=['GET'])
def get_key_pool_status():
    """Get current status of the API key pool"""
    try:
        pool_status = ApiKeyPool.get_pool_status()
        return jsonify({
            'success': True,
            'data': pool_status
        }), 200
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/keys/rotate', methods=['POST'])
def manual_rotate_key():
    """Manually rotate to the next API key"""
    try:
        success = ApiKeyPool.rotate_key()
        if success:
            # Reinitialize services with the new key
            current_key = ApiKeyPool.get_key()
            if current_key:
                global gemini_api_key
                gemini_api_key = current_key  # Update the global variable
                gemini_image_service.initialize(current_key)
                gemini_text_service.initialize(current_key)
                genai.configure(api_key=current_key)
            
            pool_status = ApiKeyPool.get_pool_status()
            return jsonify({
                'success': True,
                'message': 'API key rotated successfully',
                'pool_status': pool_status
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to rotate API key'
            }), 400
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/stories/generate', methods=['POST'])
@auth_service.require_user
def generate_story():
    try:
        data = request.get_json()
        
        if not data or 'prompt' not in data or 'theme' not in data:
            return jsonify({'success': False, 'error': 'Missing required fields'}), 400
        
        prompt = data['prompt']
        theme = data['theme']
        additional_context = data.get('additionalContext')
        
        story = story_service.generate_story(prompt, theme, additional_context)
        
        return jsonify({
            'success': True,
            'data': story
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/feedback', methods=['POST'])
def submit_feedback():
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'success': False, 'error': 'Missing data'}), 400
        
        feedback_type = data.get('feedbackType', 'Positive')
        selected_feedback = data.get('selectedFeedback', '')
        custom_feedback = data.get('customFeedback', '')
        story_id = data.get('storyId')
        rating = data.get('rating', 5)
        visitor_id = data.get('visitorId')

        result = feedback_service.submit_feedback(
            feedback_type=feedback_type,
            selected_feedback=selected_feedback,
            custom_feedback=custom_feedback,
            story_id=story_id,
            rating=rating,
            visitor_id=visitor_id
        )
        
        if result['success']:
            return jsonify({
                'success': True,
                'message': result['message']
            })
        else:
            return jsonify({
                'success': False,
                'error': result['error']
            }), 400
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/feedback/options', methods=['GET'])
def get_feedback_options():
    try:
        options = feedback_service.get_feedback_options()
        return jsonify({
            'success': True,
            'data': options
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/feedback/<story_id>', methods=['GET'])
def get_feedback(story_id):
    try:
        feedback = feedback_service.get_feedback_for_story(story_id)
        
        return jsonify({
            'success': True,
            'data': feedback
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/feedback/<story_id>/stats', methods=['GET'])
def get_feedback_stats(story_id):
    try:
        stats = feedback_service.get_feedback_stats(story_id)
        
        return jsonify({
            'success': True,
            'data': stats
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/generate-image', methods=['POST'])
def generate_single_image():
    """Generate a single image for story pages - optimized for Vercel timeout limits"""
    try:
        data = request.get_json()
        
        if not data or 'prompt' not in data:
            return jsonify({'success': False, 'error': 'Missing prompt'}), 400
        
        prompt = data['prompt']
        print(f"🖼️ Generating single image for prompt: {prompt[:100]}...")
        
        if not gemini_api_key:
            return jsonify({
                'success': False,
                'error': 'Gemini API key not configured'
            }), 500
        
        # Generate single image with timeout protection
        result = gemini_image_service.generate_gemini_image(prompt)
        
        if result['success'] and result.get('imageBytes'):
            # Convert image bytes to base64 for JSON response
            image_base64 = base64.b64encode(result['imageBytes']).decode('utf-8')
            print(f"✅ Image generated successfully (base64 length: {len(image_base64)})")
            
            return jsonify({
                'success': True,
                'imageBase64': image_base64
            })
        else:
            error_msg = result.get('error', 'Failed to generate image')
            print(f"❌ Image generation failed: {error_msg}")
            return jsonify({
                'success': False,
                'error': error_msg
            }), 500
            
    except Exception as e:
        print(f"❌ Exception in generate_single_image: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# Keep the old endpoint for backward compatibility
@app.route('/api/images/generate', methods=['POST'])
def generate_image_legacy():
    """Legacy endpoint - redirects to new single image endpoint"""
    return generate_single_image()

@app.route('/api/images/<filename>')
def serve_image(filename):
    """Serve generated images"""
    try:
        image_path = os.path.join('temp_images', filename)
        if os.path.exists(image_path):
            return send_file(image_path, mimetype='image/jpeg')
        else:
            return jsonify({'error': 'Image not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/text/generate', methods=['POST'])
def generate_text():
    try:
        data = request.get_json()
        
        if not data or 'prompt' not in data:
            return jsonify({'success': False, 'error': 'Missing prompt'}), 400
        
        prompt = data['prompt']
        system_instruction = data.get('systemInstruction')
        generation_config = data.get('generationConfig')
        images = data.get('images', [])  # Optional reference images
        
        if not gemini_api_key:
            return jsonify({
                'success': False,
                'error': 'Gemini API key not configured'
            }), 500
        
        generated_text = gemini_text_service.generate_text(
            prompt=prompt,
            system_instruction=system_instruction,
            generation_config=generation_config,
            images=images
        )
        
        return jsonify({
            'success': True,
            'text': generated_text
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/stories/save', methods=['POST'])
@auth_service.require_user
def save_story():
    """Persist a fully-assembled story (real images already merged in by the
    caller, mirroring how the mobile app merges per-page /api/generate-image
    results before display)."""
    try:
        data = request.get_json()
        if not data or 'story' not in data:
            return jsonify({'success': False, 'error': 'Missing story'}), 400

        story = data['story']
        for field in ('id', 'title', 'theme', 'pages'):
            if field not in story:
                return jsonify({'success': False, 'error': f'Story missing field: {field}'}), 400

        saved = story_repository.save_story(
            story,
            visitor_id=data.get('visitorId'),
            user_id=request.user['sub'],
            source=data.get('source', 'website'),
        )
        return jsonify({'success': True, 'data': saved})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/stories/<story_id>', methods=['GET'])
def get_story(story_id):
    try:
        story = story_repository.get_story(story_id)
        if not story:
            return jsonify({'success': False, 'error': 'Story not found'}), 404
        return jsonify({'success': True, 'data': story})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/stories', methods=['GET'])
def list_stories():
    try:
        is_default_param = request.args.get('isDefault')
        theme = request.args.get('theme')
        if is_default_param is not None:
            is_default = is_default_param.lower() == 'true'
        else:
            # No explicit filter requested: public/anonymous callers only ever
            # see admin-curated (isDefault) stories. Only a verified admin
            # token can pull back every story in the database.
            is_default = None if auth_service.try_decode_admin(request) else True
        limit = min(int(request.args.get('limit', 12)), 50)

        stories = story_repository.list_stories(is_default=is_default, limit=limit, theme=theme)
        return jsonify({'success': True, 'data': stories})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/stories/mine', methods=['GET'])
@auth_service.require_user
def list_my_stories():
    try:
        limit = min(int(request.args.get('limit', 50)), 100)
        stories = story_repository.list_stories_by_user(request.user['sub'], limit=limit)
        return jsonify({'success': True, 'data': stories})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/stories/<story_id>/default', methods=['PATCH'])
@auth_service.require_admin
def set_story_default(story_id):
    try:
        data = request.get_json() or {}
        if 'isDefault' not in data:
            return jsonify({'success': False, 'error': 'Missing isDefault'}), 400

        updated = story_repository.set_default(story_id, data['isDefault'])
        if not updated:
            return jsonify({'success': False, 'error': 'Story not found'}), 404
        return jsonify({'success': True, 'data': updated})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/visits', methods=['POST'])
def record_visit():
    try:
        data = request.get_json()
        if not data or not data.get('visitorId'):
            return jsonify({'success': False, 'error': 'Missing visitorId'}), 400

        analytics_service.record_visit(
            visitor_id=data['visitorId'],
            path=data.get('path', '/'),
            event=data.get('event', 'pageview'),
            user_agent=request.headers.get('User-Agent'),
            referrer=data.get('referrer'),
        )
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/auth/signup', methods=['POST'])
def auth_signup():
    try:
        data = request.get_json() or {}
        try:
            user = user_service.signup(data.get('email'), data.get('password'), data.get('name'))
        except ValueError as e:
            return jsonify({'success': False, 'error': str(e)}), 400

        token = auth_service.create_user_token(user)
        return jsonify({'success': True, 'data': {'token': token, 'user': user_service._serialize(user)}}), 201
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/auth/login', methods=['POST'])
def auth_login():
    try:
        data = request.get_json() or {}
        if not data.get('email') or not data.get('password'):
            return jsonify({'success': False, 'error': 'Missing credentials'}), 400

        user = user_service.login(data['email'], data['password'])
        if not user:
            return jsonify({'success': False, 'error': 'Invalid email or password'}), 401

        token = auth_service.create_user_token(user)
        return jsonify({'success': True, 'data': {'token': token, 'user': user_service._serialize(user)}})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/auth/google', methods=['POST'])
def auth_google():
    try:
        data = request.get_json() or {}
        if not data.get('idToken'):
            return jsonify({'success': False, 'error': 'Missing idToken'}), 400

        try:
            claims = auth_service.verify_google_id_token(data['idToken'])
        except Exception:
            return jsonify({'success': False, 'error': 'Invalid Google token'}), 401

        user = user_service.find_or_create_google_user(claims)
        token = auth_service.create_user_token(user)
        return jsonify({'success': True, 'data': {'token': token, 'user': user_service._serialize(user)}})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/auth/logout', methods=['POST'])
def auth_logout():
    # JWTs are stateless; "logout" is the client discarding its token.
    return jsonify({'success': True})


@app.route('/api/auth/me', methods=['GET'])
@auth_service.require_user
def auth_me():
    user = user_service.get_user_by_id(request.user['sub'])
    if not user:
        return jsonify({'success': False, 'error': 'User not found'}), 404
    return jsonify({'success': True, 'data': user_service._serialize(user)})


@app.route('/api/admin/login', methods=['POST'])
def admin_login():
    try:
        data = request.get_json()
        if not data or not data.get('email') or not data.get('password'):
            return jsonify({'success': False, 'error': 'Missing credentials'}), 400

        admin = auth_service.verify_admin(data['email'], data['password'])
        if not admin:
            return jsonify({'success': False, 'error': 'Invalid email or password'}), 401

        token = auth_service.create_token(admin)
        return jsonify({'success': True, 'data': {'token': token, 'email': admin['email']}})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/admin/me', methods=['GET'])
@auth_service.require_admin
def admin_me():
    return jsonify({'success': True, 'data': {'email': request.admin.get('email')}})


@app.route('/api/admin/stats', methods=['GET'])
@auth_service.require_admin
def admin_stats():
    try:
        granularity = request.args.get('granularity', 'day')
        start_param = request.args.get('start')
        end_param = request.args.get('end')

        start = datetime.fromisoformat(start_param) if start_param else None
        end = datetime.fromisoformat(end_param) if end_param else None

        stats = analytics_service.get_stats(start=start, end=end, granularity=granularity)
        return jsonify({'success': True, 'data': stats})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=True, use_reloader=False)
