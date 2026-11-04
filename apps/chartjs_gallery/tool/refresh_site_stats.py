#!/usr/bin/env python3
"""Refresh the local site draft's public GitHub/pub.dev statistics snapshot.

Run from any directory. Requires the GitHub CLI; its authentication stays in gh.
Failures are recorded as unknown, never zero. No runtime network or secrets are
bundled into the Flutter application.
"""
import datetime as dt
import json
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

APP = Path(__file__).resolve().parents[1]
OWN = "artflutter/flutter_ports"
PACKAGES = [
    ("flutter_chartjs_port", OWN, "packages/flutter_chartjs_port"),
    ("flutter_d3_port", OWN, "packages/flutter_d3_port"),
    ("flutter_echarts_port", OWN, "packages/flutter_echarts_port"),
    ("flutter_chartjs_plugin_zoom_port", OWN,
     "packages/flutter_chartjs_plugin_zoom_port"),
    ("highlighting", "akvelon/dart-highlighting", ""),
    ("turf", "dartclub/turf_dart", ""),
    ("supercluster", "rorystephenson/supercluster_dart", ""),
]


def github(endpoint):
    result = subprocess.run(
        ["gh", "api", "--include", endpoint], text=True,
        capture_output=True, timeout=45, check=True,
    )
    headers, body = result.stdout.replace("\r\n", "\n").split("\n\n", 1)
    return headers, json.loads(body)


def count_search(repo, kind):
    _, result = github("search/issues?" + urllib.parse.urlencode({
        "q": f"repo:{repo} is:{kind} is:open", "per_page": 1,
    }))
    if result.get("incomplete_results", True):
        raise ValueError("GitHub search returned incomplete results")
    return result["total_count"]


def commit_stats(repo, path, now):
    query = {"per_page": 1, "until": now.isoformat()}
    if path:
        query["path"] = path
    _, latest = github(f"repos/{repo}/commits?" + urllib.parse.urlencode(query))
    query["since"] = (now - dt.timedelta(days=90)).isoformat()
    headers, recent = github(
        f"repos/{repo}/commits?" + urllib.parse.urlencode(query)
    )
    # With per_page=1, the last page number is the exact result count.
    last = re.search(r'<([^>]+)>; rel="last"', headers, re.IGNORECASE)
    count = len(recent)
    if last:
        count = int(urllib.parse.parse_qs(
            urllib.parse.urlparse(last.group(1)).query
        )["page"][0])
    elif re.search(r'rel="next"', headers, re.IGNORECASE):
        raise ValueError("GitHub pagination omitted the total")
    return {
        "last_commit": latest[0]["commit"]["committer"]["date"] if latest else None,
        "commits_90d": count,
    }


def pub_release(package):
    request = urllib.request.Request(
        f"https://pub.dev/api/packages/{package}",
        headers={"User-Agent": "flutter-ports-site-drafts"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return {"release_status": "unpublished"}
        raise
    latest = result["latest"]
    return {
        "release_status": "published",
        "release_version": latest["version"],
        "release_date": latest["published"],
    }


def main():
    now = dt.datetime.now(dt.timezone.utc)
    repos = {}
    packages = {}
    failed = False
    for package, repo, path in PACKAGES:
        if repo not in repos:
            repos[repo] = {}
            for kind, key in [("issue", "open_issues"), ("pr", "open_prs")]:
                try:
                    repos[repo][key] = count_search(repo, kind)
                except Exception as error:
                    failed = True
                    repos[repo][key] = None
                    print(f"Unavailable: {repo} {key} ({type(error).__name__})",
                          file=sys.stderr)
        row = {"repository": repo, "activity_path": path, **repos[repo]}
        try:
            row.update(commit_stats(repo, path, now))
        except Exception as error:
            failed = True
            print(f"Unavailable: {package} commits ({type(error).__name__})",
                  file=sys.stderr)
        try:
            row.update(pub_release(package))
        except Exception as error:
            failed = True
            row["release_status"] = "unknown"
            print(f"Unavailable: {package} release ({type(error).__name__})",
                  file=sys.stderr)
        packages[package] = row
        print(f"Checked {package}")
    snapshot = {
        "checked_at": now.isoformat(),
        "activity_window_days": 90,
        "packages": packages,
    }
    output = APP / "assets/site_drafts/package_stats.json"
    output.write_text(json.dumps(snapshot, indent=2) + "\n")
    print(f"Wrote {output}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
