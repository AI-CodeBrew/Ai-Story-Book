import os
import google.generativeai as genai
from typing import Optional, List, Dict, Any

class GeminiTextService:
    def __init__(self):
        self._api_key = ''
    
    def initialize(self, api_key: str):
        """Initialize the service with API key"""
        self._api_key = api_key
        genai.configure(api_key=api_key)
    
    def generate_text(self, 
                     prompt: str, 
                     system_instruction: Optional[str] = None,
                     generation_config: Optional[Dict[str, Any]] = None,
                     images: Optional[List[bytes]] = None) -> str:
        """
        Generate text using Gemini API
        
        Args:
            prompt: Text prompt for generation
            system_instruction: Optional system instruction
            generation_config: Optional generation configuration
            images: Optional list of image bytes
            
        Returns:
            Generated text string
        """
        # Always use API key from pool first, then fallback
        from app import ApiKeyPool
        api_key = ApiKeyPool.get_key()
        
        if not api_key:
            # Fallback to initialized key if pool is empty
            if not self._api_key:
                return "Error: No API key available in pool or initialized"
            api_key = self._api_key
            print(f"Using fallback API key: {api_key[:10]}...")
        else:
            print(f"Using API key from pool: {api_key[:10]}...")
        
        max_retries = 3
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                # Reconfigure with current API key
                genai.configure(api_key=api_key)
                
                # Configure the model
                if generation_config:
                    model = genai.GenerativeModel(
                        model_name='gemini-3.6-flash',
                        generation_config=generation_config
                    )
                else:
                    model = genai.GenerativeModel(model_name='gemini-3.6-flash')
                
                # Build content
                content_parts = [prompt]
                
                # Add system instruction if provided
                if system_instruction:
                    content_parts.insert(0, f"System: {system_instruction}")
                
                # Add images if provided
                if images:
                    for image_bytes in images:
                        # Convert bytes to PIL Image
                        from PIL import Image
                        import io
                        image = Image.open(io.BytesIO(image_bytes))
                        content_parts.append(image)
                
                # Generate content
                response = model.generate_content(content_parts)
                return response.text or ""
                
            except Exception as e:
                error_str = str(e).lower()
                print(f"Error in generate_text (attempt {retry_count + 1}): {e}")
                
                # Check if it's a rate limit or overload error
                if any(keyword in error_str for keyword in ['rate limit', 'quota', 'limit exceeded', 'too many requests', 'overloaded', 'unavailable']):
                    print("🚨 Rate limit or overload detected in text service!")
                    
                    # Try to rotate the key
                    if ApiKeyPool.handle_rate_limit_error():
                        api_key = ApiKeyPool.get_key()
                        print(f"🔄 Retrying with rotated key: {api_key[:10]}...")
                        retry_count += 1
                        continue
                    else:
                        print("❌ No more keys available for rotation")
                        return f"Rate limit/overload exceeded and no alternative keys available: {e}"
                else:
                    # Non-rate-limit error, don't retry
                    return f"Error generating text: {e}"
        
        return f"Error generating text after {max_retries} attempts with key rotation"
