import os
from llama_stack_client import LlamaStackClient
from openai import OpenAI

class F5SecurityAPI:
    """F5 API Security client with dual endpoints: fixed LlamaStack + configurable OpenAI chat."""
    
    def __init__(self):
        # FIXED LlamaStack endpoint for document operations (NEVER changes)
        self.llamastack_endpoint = "http://llamastack:8321"
        self.llamastack_client = LlamaStackClient(base_url=self.llamastack_endpoint)
        
        # User-configurable chat endpoint (defaults to LlamaStack, can be F5 proxy)
        self.chat_endpoint = os.getenv(
            "CHAT_COMPLETIONS_ENDPOINT", 
            "http://llamastack:8321"
        )
        self.openai_client = OpenAI(
            base_url=self.chat_endpoint,
            api_key="dummy-key"  # RHOAI endpoint doesn't require real key
        )
    
    def get_chat_endpoint(self):
        """Get the current chat completions endpoint."""
        return self.chat_endpoint
    
    def get_llamastack_endpoint(self):
        """Get the FIXED LlamaStack endpoint (read-only)."""
        return self.llamastack_endpoint
    
    def get_llamastack_client(self):
        """Get the FIXED LlamaStack client for document operations."""
        return self.llamastack_client
    
    def get_openai_client(self):
        """Get the configurable OpenAI client for chat completions."""
        return self.openai_client
    
    def get_current_endpoint(self):
        """Get the current LlamaStack endpoint (for compatibility with upload.py)."""
        return self.llamastack_endpoint

# Global API instance
f5_security_api = F5SecurityAPI()

# Alias for compatibility with chat.py imports
llama_stack_api = f5_security_api
