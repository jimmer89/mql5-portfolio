#!/usr/bin/env python3
"""
MQL5 Browser API Helper
Uses browser automation to interact with MQL5 API endpoints.

This script is called by the main auto_apply system to:
1. Ensure browser is logged in
2. Extract CSRF tokens from pages
3. Submit applications via API endpoints

Requires: clawdbot browser with active MQL5 session
"""

import json
import subprocess
import time
import sys

def run_clawdbot_browser(action, **kwargs):
    """Execute a clawdbot browser action via CLI."""
    # Build the command - this would normally use the clawdbot API
    # For now, we output instructions for manual integration
    return {"error": "Direct browser API not yet integrated - use JS evaluation"}


def check_login_status():
    """
    Check if browser is logged into MQL5.
    Returns dict with login status.
    """
    # This would check the browser session
    # For now returns placeholder
    return {
        "logged_in": True,  # Assume logged in if browser has cookies
        "user": "whitechocolate"
    }


def get_csrf_token(job_url):
    """
    Navigate to job page and extract CSRF token.
    Returns: dict with signature token
    """
    # In production, this would:
    # 1. Navigate to job_url
    # 2. Extract __signature from form
    # 3. Return the token
    return {
        "success": False,
        "error": "Use browser tool directly from Clawdbot"
    }


def submit_application(job_id, signature, budget, period):
    """
    Submit initial application to MQL5 job.
    
    POST /job/{job_id}/request/new
    
    Args:
        job_id: Job ID number
        signature: CSRF token from page
        budget: Budget amount in USD
        period: Deadline in days
    
    Returns: dict with success status
    """
    endpoint = f"https://www.mql5.com/es/job/{job_id}/request/new"
    
    # This would POST to the endpoint
    # For now, returns the JS code needed
    js_code = f'''
async () => {{
    const formData = new FormData();
    formData.append('__signature', '{signature}');
    formData.append('budget', '{budget}');
    formData.append('period', '{period}');
    formData.append('confirm', 'on');
    
    const resp = await fetch('{endpoint}', {{
        method: 'POST',
        body: formData,
        credentials: 'include'
    }});
    
    return {{
        status: resp.status,
        redirected: resp.redirected,
        url: resp.url
    }};
}}
'''
    return {
        "js_code": js_code,
        "endpoint": endpoint
    }


def submit_proposal(request_id, signature, body):
    """
    Submit proposal message to discussion.
    
    POST /job/request/setComment
    
    Args:
        request_id: The JobRequestID from the discussion page
        signature: CSRF token from page
        body: Proposal text
    
    Returns: dict with success status
    """
    endpoint = "https://www.mql5.com/es/job/request/setComment"
    
    # Escape the body for JS
    body_escaped = body.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    
    js_code = f'''
async () => {{
    const formData = new FormData();
    formData.append('__signature', '{signature}');
    formData.append('body', '{body_escaped}');
    formData.append('requestId', '{request_id}');
    formData.append('id', '');
    
    const resp = await fetch('{endpoint}', {{
        method: 'POST',
        body: formData,
        credentials: 'include'
    }});
    
    const text = await resp.text();
    return {{
        status: resp.status,
        body: text
    }};
}}
'''
    return {
        "js_code": js_code,
        "endpoint": endpoint
    }


def extract_page_data(page_type='job'):
    """
    Extract necessary data from current page.
    
    For job page: __signature, job_id
    For discussion page: __signature, requestId, JobRequestID
    """
    if page_type == 'job':
        js_code = '''
() => {
    const sig = document.querySelector('form[action*="request/new"] input[name="__signature"]');
    const form = sig ? sig.closest('form') : null;
    const actionMatch = form ? form.action.match(/job\\/(\\d+)/) : null;
    
    return {
        signature: sig ? sig.value : null,
        job_id: actionMatch ? actionMatch[1] : null,
        form_action: form ? form.action : null
    };
}
'''
    else:  # discussion
        js_code = '''
() => {
    const sig = document.querySelector('form[action*="setComment"] input[name="__signature"]');
    const reqId = document.querySelector('#requestId') || document.querySelector('input[name="requestId"]');
    const jobReqId = document.querySelector('#JobRequestID') || document.querySelector('input[name="JobRequestID"]');
    const urlMatch = window.location.href.match(/id=(\\d+)/);
    
    return {
        signature: sig ? sig.value : null,
        requestId: reqId ? reqId.value : (urlMatch ? urlMatch[1] : null),
        jobRequestId: jobReqId ? jobReqId.value : (urlMatch ? urlMatch[1] : null)
    };
}
'''
    return {"js_code": js_code}


# CLI interface for testing
if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='MQL5 Browser API Helper')
    parser.add_argument('action', choices=['check-login', 'get-token', 'apply', 'propose'],
                        help='Action to perform')
    parser.add_argument('--job-id', help='Job ID for apply action')
    parser.add_argument('--budget', type=int, default=30, help='Budget in USD')
    parser.add_argument('--period', type=int, default=3, help='Period in days')
    parser.add_argument('--message', help='Proposal message')
    args = parser.parse_args()
    
    if args.action == 'check-login':
        result = check_login_status()
    elif args.action == 'get-token':
        result = extract_page_data('job')
    elif args.action == 'apply':
        if not args.job_id:
            print("Error: --job-id required for apply action")
            sys.exit(1)
        result = submit_application(args.job_id, 'TOKEN_HERE', args.budget, args.period)
    elif args.action == 'propose':
        result = submit_proposal('REQUEST_ID', 'TOKEN_HERE', args.message or 'Test message')
    
    print(json.dumps(result, indent=2))
