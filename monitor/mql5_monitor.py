#!/usr/bin/env python3
"""
MQL5 Freelance Job Monitor
Scrapes MQL5 freelance jobs and filters for projects we can do.
Outputs new jobs as JSON for proposal generation.
"""

import json
import re
import sys
import os
from datetime import datetime
from pathlib import Path

# Try to use requests + bs4, fall back to urllib
try:
    import requests
    from bs4 import BeautifulSoup
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False
    import urllib.request
    import urllib.error

JOBS_BASE_URL = "https://www.mql5.com"
PAGES_TO_SCAN = 3  # Scan first 3 pages per language

# Languages to scan (priority order - Spanish first for less competition)
LANGUAGES = [
    ("es", "Spanish"),
    ("en", "English"),
    ("pt", "Portuguese"),
    ("de", "German"),
]

STATE_FILE = Path(__file__).parent / "seen_jobs.json"
OUTPUT_FILE = Path(__file__).parent / "new_jobs.json"

# Jobs we SKIP (can't do or not worth it)
SKIP_KEYWORDS = [
    "withdraw", "visa card", "webmoney",  # financial help, not coding
    "personal job",  # private jobs we can't apply to
    "buying profitable ea", "buy ea",  # people buying, not hiring
    "copy trading", "copy trade",  # usually need live account access
    "looking for profitable",  # buying EAs
]

# Jobs we CAN do
CAN_DO_KEYWORDS = [
    "expert advisor", "ea", "indicator", "script",
    "mql5", "mql4", "metatrader", "mt4", "mt5",
    "trading bot", "robot", "strategy",
    "panel", "dashboard", "alert",
    "convert", "modify", "fix", "update", "optimize",
    "backtest", "tester",
    "ema", "rsi", "macd", "bollinger", "stochastic",
    "scalping", "grid", "martingale", "hedging",
    "breakout", "trend", "pullback",
    "risk management", "lot size", "stop loss", "take profit",
]


def fetch_page_simple(url):
    """Fetch page without requests library."""
    req = urllib.request.Request(url, headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read().decode('utf-8', errors='replace')
    except Exception as e:
        print(f"Error fetching {url}: {e}", file=sys.stderr)
        return None


def parse_jobs_from_html(html, lang_code="en"):
    """Parse job listings from MQL5 freelance page HTML."""
    jobs = []
    seen_links = set()
    
    # MQL5 uses a specific structure - extract job blocks
    # Pattern: title, budget, description, applications count
    
    # Try with BeautifulSoup if available
    if HAS_DEPS:
        soup = BeautifulSoup(html, 'html.parser')
        # MQL5 job cards - look for job links in any language
        for card in soup.select('.jobItem, .job-item, [class*="job"]'):
            # Find link that points to actual job (ends with number ID)
            # Match any language: /en/job/123, /es/job/123, /pt/job/123, etc.
            title_el = None
            for a in card.select('a[href*="/job/"]'):
                href = a.get('href', '')
                # Only accept links ending in a job ID (number)
                if re.search(r'/[a-z]{2}/job/\d+$', href):
                    title_el = a
                    break
            
            if not title_el:
                continue
            
            link = title_el.get('href', '')
            if not link.startswith('http'):
                link = f"https://www.mql5.com{link}"
            
            # Deduplicate by link
            if link in seen_links:
                continue
            seen_links.add(link)
            
            title = title_el.get_text(strip=True)
            desc = card.get_text(' ', strip=True)
            budget = extract_budget(desc)
            apps = extract_applications(desc)
            
            jobs.append({
                'title': title,
                'link': link,
                'budget': budget,
                'applications': apps,
                'description': desc[:500],
            })
    
    # Fallback: regex-based parsing from the markdown/text content
    if not jobs:
        jobs = parse_jobs_from_text(html)
    
    return jobs


def parse_jobs_from_text(text, lang_code="en"):
    """Parse jobs from text/markdown format (from web_fetch)."""
    jobs = []
    # Split by budget patterns which separate job listings
    # Pattern: lines with "USD" amounts followed by descriptions
    
    # Simple approach: split by application counts
    blocks = re.split(r'\n\s*\d+\s+(Applications?|Solicitudes?|Candidaturas?|Bewerbungen?)\s*\n', text, flags=re.IGNORECASE)
    
    for block in blocks:
        block = block.strip()
        if not block or len(block) < 50:
            continue
        
        # Extract budget
        budget = extract_budget(block)
        
        # First line is usually the title or start of description
        lines = block.split('\n')
        title = lines[0].strip()[:100]
        desc = ' '.join(lines).strip()[:500]
        
        if budget or any(kw in desc.lower() for kw in ['mql', 'mt4', 'mt5', 'ea', 'indicator', 'trading', 'indicador', 'robot']):
            jobs.append({
                'title': title,
                'budget': budget,
                'applications': extract_applications(block),
                'description': desc,
                'link': f"{JOBS_BASE_URL}/{lang_code}/job",  # Fallback link
            })
    
    return jobs


def extract_budget(text):
    """Extract budget range from text."""
    patterns = [
        r'(\d[\d,]*)\s*-\s*(\d[\d,]*)\s*USD',
        r'(\d[\d,]*)\+?\s*USD',
    ]
    for pat in patterns:
        m = re.search(pat, text)
        if m:
            return m.group(0)
    return "Unknown"


def extract_applications(text):
    """Extract number of applications."""
    # English: "X Applications", Spanish: "X Solicitudes", Portuguese: "X Candidaturas", German: "X Bewerbungen"
    m = re.search(r'(\d+)\s+(Applications?|Solicitudes?|Candidaturas?|Bewerbungen?)', text, re.IGNORECASE)
    return int(m.group(1)) if m else 0


def extract_job_id(link):
    """Extract numeric job ID from link for deduplication across languages."""
    m = re.search(r'/job/(\d+)', link)
    return m.group(1) if m else None


def should_skip(job):
    """Check if we should skip this job."""
    text = (job.get('title', '') + ' ' + job.get('description', '')).lower()
    return any(kw in text for kw in SKIP_KEYWORDS)


def can_we_do(job):
    """Check if this is a project we can handle."""
    text = (job.get('title', '') + ' ' + job.get('description', '')).lower()
    return any(kw in text for kw in CAN_DO_KEYWORDS)


def load_seen():
    """Load previously seen job hashes."""
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return []


def save_seen(seen):
    """Save seen job hashes."""
    STATE_FILE.write_text(json.dumps(seen[-200:], indent=2))  # Keep last 200


def job_hash(job):
    """Create a hash for dedup."""
    return hash(job.get('title', '') + job.get('budget', ''))


def main():
    print(f"[{datetime.now().isoformat()}] MQL5 Job Monitor starting...")
    print(f"Scanning {PAGES_TO_SCAN} pages × {len(LANGUAGES)} languages...")
    
    all_jobs = []
    seen_links = set()
    
    for lang_code, lang_name in LANGUAGES:
        jobs_url = f"{JOBS_BASE_URL}/{lang_code}/job"
        print(f"\n📍 {lang_name} ({lang_code}):")
        
        for page in range(1, PAGES_TO_SCAN + 1):
            url = jobs_url if page == 1 else f"{jobs_url}/page{page}"
            print(f"  Fetching page {page}: {url}")
            
            # Fetch the page
            if HAS_DEPS:
                try:
                    resp = requests.get(url, headers={
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                    }, timeout=15)
                    html = resp.text
                except Exception as e:
                    print(f"  Error on page {page}: {e}", file=sys.stderr)
                    continue
            else:
                html = fetch_page_simple(url)
                if not html:
                    continue
            
            # Parse jobs from this page
            page_jobs = parse_jobs_from_html(html, lang_code)
            
            # Deduplicate across pages and languages (same job ID = same job)
            for job in page_jobs:
                # Normalize link to extract job ID for dedup
                job_id = extract_job_id(job['link'])
                if job_id and job_id not in seen_links:
                    seen_links.add(job_id)
                    job['language'] = lang_name
                    all_jobs.append(job)
                elif not job_id and job['link'] not in seen_links:
                    seen_links.add(job['link'])
                    job['language'] = lang_name
                    all_jobs.append(job)
            
            print(f"    Found {len(page_jobs)} jobs on page {page}")
    
    print(f"\nFound {len(all_jobs)} total unique job listings across all languages")
    
    # Filter
    seen = load_seen()
    new_jobs = []
    
    for job in all_jobs:
        h = str(job_hash(job))
        if h in seen:
            continue
        if should_skip(job):
            print(f"  SKIP: {job.get('title', 'Unknown')[:60]}")
            continue
        if can_we_do(job):
            new_jobs.append(job)
            lang_flag = {"Spanish": "🇪🇸", "English": "🇬🇧", "Portuguese": "🇧🇷", "German": "🇩🇪"}.get(job.get('language', ''), "🌐")
            print(f"  ✅ NEW {lang_flag}: {job.get('title', 'Unknown')[:55]} | {job.get('budget', '?')}")
        else:
            print(f"  ❓ UNCLEAR: {job.get('title', 'Unknown')[:60]}")
            # Still include unclear ones since our filter is low
            new_jobs.append(job)
        
        seen.append(h)
    
    # Save state
    save_seen(seen)
    
    # Output new jobs
    if new_jobs:
        OUTPUT_FILE.write_text(json.dumps(new_jobs, indent=2, ensure_ascii=False))
        print(f"\n🆕 {len(new_jobs)} new jobs found! Saved to {OUTPUT_FILE}")
    else:
        print("\nNo new jobs found.")
    
    # Return count for cron
    return len(new_jobs)


if __name__ == '__main__':
    count = main()
    sys.exit(0 if count >= 0 else 1)
