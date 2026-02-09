#!/usr/bin/env python3
"""
MQL5 Auto-Apply System
Automatically applies to MQL5 freelance jobs using discovered API endpoints.

Endpoints discovered:
- POST /job/{id}/request/new - Submit initial application (budget, period)
- POST /job/request/setComment - Send proposal message

Requires: Browser session with MQL5 login (cookies managed by browser)
"""

import json
import re
import sys
import os
import time
import random
import argparse
from datetime import datetime
from pathlib import Path

# Configuration
CONFIG_FILE = Path(__file__).parent.parent / "config" / "auto_apply.json"
TRACKING_FILE = Path(__file__).parent.parent / "proposals" / "STATUS.md"
JOBS_FILE = Path(__file__).parent / "new_jobs.json"
CREDENTIALS_FILE = Path.home() / ".mql5_credentials"

# Default config
DEFAULT_CONFIG = {
    "dry_run": True,  # Safety: start in dry-run mode
    "max_applications_per_run": 5,
    "delay_between_applications": {"min": 30, "max": 90},  # seconds, with jitter
    "active_hours": {"start": 9, "end": 23},  # Only auto-send during these hours
    "tiers": {
        "high_confidence": {
            "budget_min": 30,
            "budget_max": 150,
            "max_competitors": 10,
            "auto_send": True
        },
        "medium_confidence": {
            "budget_min": 150,
            "budget_max": 300,
            "max_competitors": 20,
            "wait_minutes": 15
        },
        "low_confidence": {
            "budget_min": 300,
            "require_approval": True
        }
    },
    "skip_keywords": [
        "buy ea", "buy profitable", "partnership", "looking for profitable",
        "ninjatrader", "quantower", "binary", "robot binario"
    ],
    "github_portfolio": "https://github.com/jimmer89/mql5-portfolio"
}


def load_config():
    """Load configuration, creating default if not exists."""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            config = json.load(f)
            # Merge with defaults for any missing keys
            for key, value in DEFAULT_CONFIG.items():
                if key not in config:
                    config[key] = value
            return config
    else:
        # Create config directory and file
        CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(CONFIG_FILE, 'w') as f:
            json.dump(DEFAULT_CONFIG, f, indent=2)
        print(f"Created default config at {CONFIG_FILE}")
        return DEFAULT_CONFIG


def load_tracking():
    """Load tracking data from STATUS.md."""
    if not TRACKING_FILE.exists():
        return {"applied": [], "stats": {"total": 0, "won": 0, "lost": 0}}
    
    # Parse YAML frontmatter from markdown
    content = TRACKING_FILE.read_text()
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            import yaml
            try:
                return yaml.safe_load(parts[1])
            except:
                pass
    
    return {"applied": [], "stats": {"total": 0, "won": 0, "lost": 0}}


def save_tracking(data):
    """Save tracking data to STATUS.md."""
    TRACKING_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    import yaml
    yaml_content = yaml.dump(data, default_flow_style=False, allow_unicode=True)
    
    # Generate markdown summary
    md_content = f"""---
{yaml_content}---

# MQL5 Proposals Tracking

## Stats
- Total applied: {data['stats']['total']}
- Won: {data['stats']['won']}
- Lost: {data['stats']['lost']}
- Win rate: {(data['stats']['won'] / data['stats']['total'] * 100) if data['stats']['total'] > 0 else 0:.1f}%

## Recent Applications

| Date | Job | Budget | Status |
|------|-----|--------|--------|
"""
    
    # Add last 20 applications
    for app in data['applied'][-20:]:
        md_content += f"| {app.get('date', 'N/A')} | [{app.get('title', 'N/A')[:40]}]({app.get('url', '#')}) | ${app.get('budget', '?')} | {app.get('status', 'applied')} |\n"
    
    TRACKING_FILE.write_text(md_content)


def extract_budget(text):
    """Extract budget from job description."""
    patterns = [
        r'(\d+)\s*-\s*(\d+)\s*USD',
        r'(\d+)\+?\s*USD',
    ]
    for pat in patterns:
        m = re.search(pat, text)
        if m:
            if m.lastindex == 2:
                return (int(m.group(1)) + int(m.group(2))) // 2  # Average
            return int(m.group(1))
    return 30  # Default


def classify_job(job, config):
    """Classify job into confidence tier."""
    budget = extract_budget(job.get('budget', '30 USD'))
    competitors = job.get('applications', 0)
    
    # Check skip keywords
    text = (job.get('title', '') + ' ' + job.get('description', '')).lower()
    for keyword in config['skip_keywords']:
        if keyword in text:
            return 'skip', f"Contains skip keyword: {keyword}"
    
    tiers = config['tiers']
    
    if budget <= tiers['high_confidence']['budget_max'] and \
       competitors <= tiers['high_confidence']['max_competitors']:
        return 'high', None
    
    if budget <= tiers['medium_confidence']['budget_max'] and \
       competitors <= tiers['medium_confidence']['max_competitors']:
        return 'medium', None
    
    if budget >= tiers['low_confidence']['budget_min']:
        return 'low', "High budget - requires approval"
    
    return 'medium', None


def generate_proposal(job, config):
    """Generate a proposal for the job.
    
    In production, this would call an LLM to generate a unique proposal.
    For now, returns a template that should be customized.
    """
    title = job.get('title', 'your project')
    
    # Extract key elements from job for personalization
    job_text = job.get('description', '')
    
    # This is where LLM would generate unique proposal
    # For now, placeholder that MUST be customized
    proposal = f"""Hola,

He revisado tu solicitud "{title}" y me interesa trabajar en ella.

Mi approach:
• Código limpio, documentado y mantenible
• Entrega en el plazo acordado
• Comunicación constante durante el desarrollo
• Soporte post-entrega para ajustes menores

¿Podrías darme más detalles sobre los requisitos específicos? Con esa información puedo darte una estimación más precisa.

Portfolio: {config['github_portfolio']}

Saludos,
Jaume"""
    
    return proposal


def is_within_active_hours(config):
    """Check if current time is within active hours."""
    now = datetime.now()
    start = config['active_hours']['start']
    end = config['active_hours']['end']
    return start <= now.hour < end


def apply_to_job_via_api(job, proposal, budget, period, config, dry_run=False):
    """
    Apply to a job using the MQL5 API endpoints.
    
    This function uses the browser tool to:
    1. Navigate to the job page
    2. Extract CSRF token
    3. POST to /job/{id}/request/new
    4. POST proposal to /job/request/setComment
    
    Returns: dict with success status and details
    """
    job_url = job.get('link', job.get('url', ''))
    job_id = re.search(r'/job/(\d+)', job_url)
    if not job_id:
        return {"success": False, "error": "Could not extract job ID"}
    
    job_id = job_id.group(1)
    
    if dry_run:
        return {
            "success": True,
            "dry_run": True,
            "job_id": job_id,
            "budget": budget,
            "period": period,
            "proposal_preview": proposal[:200] + "..."
        }
    
    # In production, this would use browser automation or API calls
    # For now, return placeholder
    return {
        "success": False,
        "error": "Real API calls not yet implemented - use browser manually or run with --dry-run"
    }


def check_responses(tracking):
    """
    Check for responses to previously submitted applications.
    
    This would:
    1. Navigate to each applied job's discussion page
    2. Check if there are new messages since last check
    3. Return list of jobs with new responses
    
    Returns: list of jobs with responses
    """
    responses = []
    
    for app in tracking.get('applied', []):
        if app.get('status') not in ['applied', 'pending']:
            continue
        
        # In production, this would:
        # 1. Navigate to app['url'] + '/discussion'
        # 2. Check for messages after our last message
        # 3. If found, add to responses list
        
        # For now, this is a placeholder that would be filled
        # when browser integration is complete
        pass
    
    return responses


def update_application_status(tracking, job_id, new_status, notes=None):
    """Update the status of an application in tracking."""
    for app in tracking.get('applied', []):
        if app.get('job_id') == job_id:
            app['status'] = new_status
            app['updated'] = datetime.now().strftime("%Y-%m-%d %H:%M")
            if notes:
                app['notes'] = notes
            
            # Update stats
            if new_status == 'won':
                tracking['stats']['won'] += 1
            elif new_status == 'lost':
                tracking['stats']['lost'] += 1
            break
    
    return tracking


def main():
    parser = argparse.ArgumentParser(description='MQL5 Auto-Apply System')
    parser.add_argument('--dry-run', action='store_true', 
                        help='Simulate without actually applying')
    parser.add_argument('--force', action='store_true',
                        help='Override dry_run setting in config')
    parser.add_argument('--job', type=str,
                        help='Apply to specific job URL only')
    parser.add_argument('--list', action='store_true',
                        help='List available jobs and their classification')
    parser.add_argument('--check-responses', action='store_true',
                        help='Check for responses to previous applications')
    parser.add_argument('--update-status', nargs=3, metavar=('JOB_ID', 'STATUS', 'NOTES'),
                        help='Update status of a job (won/lost/expired)')
    args = parser.parse_args()
    
    print(f"[{datetime.now().isoformat()}] MQL5 Auto-Apply starting...")
    
    # Load config and tracking
    config = load_config()
    tracking = load_tracking()
    
    # Handle status update
    if args.update_status:
        job_id, status, notes = args.update_status
        if status not in ['won', 'lost', 'expired', 'pending', 'applied']:
            print(f"Invalid status: {status}. Use: won, lost, expired, pending, applied")
            return 1
        tracking = update_application_status(tracking, job_id, status, notes)
        save_tracking(tracking)
        print(f"✅ Updated job {job_id} to status: {status}")
        return 0
    
    # Handle response check
    if args.check_responses:
        print("🔍 Checking for responses to previous applications...")
        responses = check_responses(tracking)
        if responses:
            print(f"\n📬 Found {len(responses)} jobs with new responses:")
            for resp in responses:
                print(f"  - {resp.get('title', 'Unknown')}: {resp.get('url', '')}")
        else:
            print("No new responses found.")
        return 0
    
    # Determine dry-run mode
    dry_run = args.dry_run or (config.get('dry_run', True) and not args.force)
    if dry_run:
        print("🔸 DRY-RUN MODE - No actual applications will be sent")
    
    # Load jobs
    if not JOBS_FILE.exists():
        print(f"No jobs file found at {JOBS_FILE}")
        print("Run mql5_monitor.py first to fetch available jobs")
        return 1
    
    with open(JOBS_FILE) as f:
        jobs = json.load(f)
    
    print(f"Found {len(jobs)} jobs to evaluate")
    
    # Get already applied job IDs
    applied_ids = set()
    for app in tracking.get('applied', []):
        if 'job_id' in app:
            applied_ids.add(app['job_id'])
        elif 'url' in app:
            m = re.search(r'/job/(\d+)', app['url'])
            if m:
                applied_ids.add(m.group(1))
    
    # Classify and filter jobs
    to_apply = []
    for job in jobs:
        job_url = job.get('link', job.get('url', ''))
        job_id_match = re.search(r'/job/(\d+)', job_url)
        if not job_id_match:
            continue
        job_id = job_id_match.group(1)
        
        # Skip if already applied
        if job_id in applied_ids:
            continue
        
        tier, reason = classify_job(job, config)
        job['_tier'] = tier
        job['_reason'] = reason
        job['_job_id'] = job_id
        
        if tier != 'skip':
            to_apply.append(job)
    
    print(f"Jobs to consider: {len(to_apply)}")
    
    # List mode
    if args.list:
        print("\n📋 Job Classification:\n")
        for job in to_apply:
            tier = job['_tier']
            emoji = {'high': '🟢', 'medium': '🟡', 'low': '🔴'}.get(tier, '⚪')
            print(f"{emoji} [{tier.upper()}] {job.get('title', 'Unknown')[:50]}")
            print(f"   Budget: {job.get('budget', '?')} | Apps: {job.get('applications', '?')}")
            print(f"   URL: {job.get('link', job.get('url', '?'))}")
            if job['_reason']:
                print(f"   Note: {job['_reason']}")
            print()
        return 0
    
    # Check active hours for auto-send
    if not is_within_active_hours(config) and not args.force:
        print(f"⏰ Outside active hours ({config['active_hours']['start']}:00-{config['active_hours']['end']}:00)")
        print("   Jobs will be queued for next run. Use --force to override.")
        # Still show what would be applied
        for job in to_apply[:config['max_applications_per_run']]:
            print(f"   Would apply to: {job.get('title', 'Unknown')[:50]}")
        return 0
    
    # Apply to jobs
    applied_count = 0
    results = []
    
    for job in to_apply:
        if applied_count >= config['max_applications_per_run']:
            print(f"Reached max applications per run ({config['max_applications_per_run']})")
            break
        
        tier = job['_tier']
        
        # Check tier-specific rules
        if tier == 'low' and config['tiers']['low_confidence'].get('require_approval'):
            print(f"⏸️  PAUSED: {job.get('title', 'Unknown')[:40]} - Requires approval (high budget)")
            results.append({
                "job": job,
                "status": "pending_approval",
                "tier": tier
            })
            continue
        
        # Generate proposal
        proposal = generate_proposal(job, config)
        budget = extract_budget(job.get('budget', '30 USD'))
        period = 3  # Default 3 days, could be smarter
        
        print(f"\n{'🔸 [DRY-RUN]' if dry_run else '📤'} Applying to: {job.get('title', 'Unknown')[:50]}")
        print(f"   Tier: {tier} | Budget: ${budget} | Period: {period} days")
        
        # Apply
        result = apply_to_job_via_api(job, proposal, budget, period, config, dry_run)
        
        if result.get('success'):
            applied_count += 1
            
            # Update tracking
            tracking['applied'].append({
                "job_id": job['_job_id'],
                "url": job.get('link', job.get('url', '')),
                "title": job.get('title', 'Unknown'),
                "budget": budget,
                "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
                "status": "applied" if not dry_run else "dry_run",
                "tier": tier
            })
            tracking['stats']['total'] += 1
            
            if dry_run:
                print(f"   ✅ Would send proposal ({len(proposal)} chars)")
            else:
                print(f"   ✅ Application sent!")
            
            results.append({
                "job": job,
                "status": "applied" if not dry_run else "dry_run",
                "result": result
            })
            
            # Delay between applications (with jitter)
            if applied_count < len(to_apply) and applied_count < config['max_applications_per_run']:
                delay = random.uniform(
                    config['delay_between_applications']['min'],
                    config['delay_between_applications']['max']
                )
                if not dry_run:
                    print(f"   ⏳ Waiting {delay:.0f}s before next application...")
                    time.sleep(delay)
        else:
            print(f"   ❌ Failed: {result.get('error', 'Unknown error')}")
            results.append({
                "job": job,
                "status": "failed",
                "error": result.get('error')
            })
    
    # Save tracking
    save_tracking(tracking)
    
    # Summary
    print(f"\n{'='*50}")
    print(f"📊 Summary:")
    print(f"   Applied: {applied_count}")
    print(f"   Pending approval: {sum(1 for r in results if r['status'] == 'pending_approval')}")
    print(f"   Failed: {sum(1 for r in results if r['status'] == 'failed')}")
    print(f"   Total tracked: {tracking['stats']['total']}")
    
    if dry_run:
        print(f"\n🔸 This was a DRY-RUN. No actual applications were sent.")
        print(f"   To send for real, use --force or set dry_run=false in config.")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
