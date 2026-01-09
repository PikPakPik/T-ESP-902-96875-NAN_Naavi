#!/usr/bin/env python3
"""
GitLab KPIs Exporter for Prometheus
Export raw metrics for issues, merge requests, milestones, branches, tags, commits, etc.
All data is exported as individual entities, aggregations are done in Grafana.
"""

import os
import time
import logging
from datetime import datetime, timezone
from typing import Dict, Any
import gitlab
from prometheus_client import start_http_server
from prometheus_client.core import GaugeMetricFamily, REGISTRY

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class GitLabKPICollector:
    """Collector for GitLab KPIs - exports raw data for Grafana aggregation"""

    def __init__(self, gitlab_url: str, gitlab_token: str, group_name: str, include_subgroups: bool = True):
        self.gitlab_url = gitlab_url
        self.group_name = group_name
        self.include_subgroups = include_subgroups
        self.gl = gitlab.Gitlab(gitlab_url, private_token=gitlab_token)
        self.gl.auth()
        logger.info(f"Connected to GitLab as {self.gl.user.username}")

    def collect(self):
        """Collect all metrics"""
        logger.info("Starting metrics collection...")

        try:
            # Get the main group
            group = self.gl.groups.get(self.group_name)
            logger.info(f"Found group: {group.full_path}")

            # Get all projects (including subgroups if requested)
            projects = group.projects.list(
                include_subgroups=self.include_subgroups,
                all=True
            )
            logger.info(f"Found {len(projects)} projects")

            # Initialize metric families
            metrics = self._initialize_metrics()

            # Initialize counters for summary
            summary = {
                'projects': len(projects),
                'issues': 0,
                'merge_requests': 0,
                'milestones': 0,
                'branches': 0,
                'tags': 0,
                'commits': 0,
                'issue_assignees': 0
            }

            # Collect metrics for each project
            for project_data in projects:
                try:
                    project = self.gl.projects.get(project_data.id)
                    project_summary = self._collect_project_metrics(project, metrics)
                    # Add to global summary
                    for key in summary:
                        if key != 'projects':
                            summary[key] += project_summary.get(key, 0)
                except Exception as e:
                    logger.error(f"Error collecting metrics for project {project_data.name}: {e}")
                    continue

            # Display summary
            logger.info("=" * 60)
            logger.info("RÉSUMÉ DE L'EXPORT")
            logger.info("=" * 60)
            logger.info(f"Projets traités:        {summary['projects']}")
            logger.info(f"Issues exportées:       {summary['issues']}")
            logger.info(f"Merge Requests exportées: {summary['merge_requests']}")
            logger.info(f"Milestones exportés:     {summary['milestones']}")
            logger.info(f"Branches exportées:     {summary['branches']}")
            logger.info(f"Tags exportés:          {summary['tags']}")
            logger.info(f"Commits exportés:       {summary['commits']}")
            logger.info(f"Assignations d'issues:  {summary['issue_assignees']}")
            logger.info("=" * 60)

            # Return all metrics
            for metric in metrics.values():
                yield metric

        except Exception as e:
            logger.error(f"Error during collection: {e}")
            raise

    def _initialize_metrics(self) -> Dict[str, Any]:
        """Initialize all metric families"""
        return {
            # Project info
            'project_info': GaugeMetricFamily(
                'gitlab_project_info',
                'GitLab project information',
                labels=['project_id', 'project', 'namespace', 'visibility', 'default_branch', 'created_at']
            ),

            # Individual issues
            'issue': GaugeMetricFamily(
                'gitlab_issue',
                'Individual GitLab issue with all metadata',
                labels=[
                    'project_id', 'project', 'namespace',
                    'issue_iid', 'issue_id', 'title', 'state',
                    'author', 'assignees', 'labels',
                    'created_at', 'updated_at', 'closed_at',
                    'milestone', 'web_url'
                ]
            ),

            # Individual merge requests
            'merge_request': GaugeMetricFamily(
                'gitlab_merge_request',
                'Individual GitLab merge request with all metadata',
                labels=[
                    'project_id', 'project', 'namespace',
                    'mr_iid', 'mr_id', 'title', 'state',
                    'author', 'assignees', 'reviewers', 'labels',
                    'source_branch', 'target_branch',
                    'created_at', 'updated_at', 'merged_at', 'closed_at',
                    'draft', 'work_in_progress', 'milestone', 'web_url'
                ]
            ),

            # Individual milestones
            'milestone': GaugeMetricFamily(
                'gitlab_milestone',
                'Individual GitLab milestone with all metadata',
                labels=[
                    'project_id', 'project', 'namespace',
                    'milestone_id', 'milestone_iid', 'title', 'state',
                    'created_at', 'updated_at', 'due_date', 'start_date',
                    'web_url'
                ]
            ),

            # Individual branches
            'branch': GaugeMetricFamily(
                'gitlab_branch',
                'Individual GitLab branch with all metadata',
                labels=[
                    'project_id', 'project', 'namespace',
                    'branch_name', 'protected', 'merged', 'default',
                    'commit_sha', 'commit_author', 'commit_date'
                ]
            ),

            # Individual tags
            'tag': GaugeMetricFamily(
                'gitlab_tag',
                'Individual GitLab tag with all metadata',
                labels=[
                    'project_id', 'project', 'namespace',
                    'tag_name', 'message', 'target',
                    'commit_sha', 'commit_author', 'commit_date',
                    'release'
                ]
            ),

            # Individual commits
            'commit': GaugeMetricFamily(
                'gitlab_commit',
                'Individual GitLab commit with all metadata',
                labels=[
                    'project_id', 'project', 'namespace',
                    'commit_sha', 'short_id',
                    'author_name', 'author_email',
                    'committer_name', 'committer_email',
                    'created_at', 'title', 'message_first_line',
                    'web_url'
                ]
            ),

            # Issue assignees (one metric per assignee for aggregation)
            'issue_assignee': GaugeMetricFamily(
                'gitlab_issue_assignee',
                'Individual GitLab issue assignee for aggregation',
                labels=[
                    'project_id', 'project', 'namespace',
                    'issue_iid', 'issue_id', 'assignee', 'state'
                ]
            ),
        }

    def _safe_str(self, value, max_length=200):
        """Convert value to string safely, with truncation"""
        if value is None:
            return ''
        s = str(value)
        if len(s) > max_length:
            return s[:max_length-3] + '...'
        return s

    def _safe_join(self, items, attr='username', max_items=5):
        """Safely join a list of items"""
        if not items:
            return ''
        try:
            if isinstance(items, list):
                if isinstance(items[0], dict):
                    names = [item.get(attr, '') for item in items[:max_items]]
                else:
                    names = [str(item)[:50] for item in items[:max_items]]
                result = ','.join(filter(None, names))
                if len(items) > max_items:
                    result += f',+{len(items) - max_items}more'
                return result[:200]
        except Exception as e:
            logger.debug(f"Error joining items: {e}")
        return ''

    def _collect_project_metrics(self, project, metrics: Dict[str, Any]) -> Dict[str, int]:
        """Collect metrics for a single project"""
        project_id = str(project.id)
        project_name = project.path
        namespace = project.namespace['full_path']

        logger.info(f"Collecting metrics for {namespace}/{project_name}")

        # Project info
        metrics['project_info'].add_metric(
            [
                project_id, project_name, namespace,
                project.visibility,
                self._safe_str(project.default_branch),
                self._safe_str(project.created_at)
            ],
            1
        )

        # Initialize project summary
        project_summary = {
            'issues': 0,
            'merge_requests': 0,
            'milestones': 0,
            'branches': 0,
            'tags': 0,
            'commits': 0,
            'issue_assignees': 0
        }

        # Issues
        project_summary['issues'], project_summary['issue_assignees'] = self._collect_issues(
            project, project_id, project_name, namespace, metrics
        )

        # Merge Requests
        project_summary['merge_requests'] = self._collect_merge_requests(
            project, project_id, project_name, namespace, metrics
        )

        # Milestones
        project_summary['milestones'] = self._collect_milestones(
            project, project_id, project_name, namespace, metrics
        )

        # Branches
        project_summary['branches'] = self._collect_branches(
            project, project_id, project_name, namespace, metrics
        )

        # Tags
        project_summary['tags'] = self._collect_tags(
            project, project_id, project_name, namespace, metrics
        )

        # Commits
        project_summary['commits'] = self._collect_commits(
            project, project_id, project_name, namespace, metrics
        )

        return project_summary

    def _collect_issues(self, project, project_id: str, project_name: str, namespace: str, metrics: Dict[str, Any]) -> tuple[int, int]:
        """Collect all issues as individual metrics
        Returns: (number of issues, number of assignees)"""
        try:
            # Get all issues (opened + closed)
            issues = project.issues.list(all=True)
            logger.info(f"  Found {len(issues)} issues")

            assignee_count = 0

            for issue in issues:
                # Get assignees
                assignees = ''
                assignee_list = []
                if hasattr(issue, 'assignees') and issue.assignees:
                    assignee_list = issue.assignees if isinstance(issue.assignees, list) else [issue.assignees]
                    assignees = self._safe_join(assignee_list, 'username')
                elif hasattr(issue, 'assignee') and issue.assignee:
                    assignee_list = [issue.assignee] if isinstance(issue.assignee, dict) else []
                    assignees = issue.assignee.get('username', '') if isinstance(issue.assignee, dict) else ''

                # Get labels
                labels = self._safe_join(issue.labels if hasattr(issue, 'labels') else [])

                # Get milestone
                milestone = ''
                if hasattr(issue, 'milestone') and issue.milestone:
                    milestone = issue.milestone.get('title', '')

                # Add metric for this issue
                metrics['issue'].add_metric(
                    [
                        project_id, project_name, namespace,
                        str(issue.iid), str(issue.id),
                        self._safe_str(issue.title, 150),
                        issue.state,
                        issue.author.get('username', 'unknown'),
                        assignees,
                        labels,
                        self._safe_str(issue.created_at),
                        self._safe_str(issue.updated_at),
                        self._safe_str(getattr(issue, 'closed_at', '')),
                        milestone,
                        self._safe_str(issue.web_url)
                    ],
                    1
                )

                # Add individual metrics for each assignee (for aggregation)
                for assignee in assignee_list:
                    assignee_username = assignee.get('username', '') if isinstance(assignee, dict) else str(assignee)
                    if assignee_username:
                        metrics['issue_assignee'].add_metric(
                            [
                                project_id, project_name, namespace,
                                str(issue.iid), str(issue.id),
                                assignee_username,
                                issue.state
                            ],
                            1
                        )
                        assignee_count += 1

            return len(issues), assignee_count

        except Exception as e:
            logger.error(f"Error collecting issues for {namespace}/{project_name}: {e}")
            return 0, 0

    def _collect_merge_requests(self, project, project_id: str, project_name: str, namespace: str, metrics: Dict[str, Any]) -> int:
        """Collect all merge requests as individual metrics
        Returns: number of merge requests"""
        try:
            # Get all MRs
            mrs = project.mergerequests.list(all=True)
            logger.info(f"  Found {len(mrs)} merge requests")

            for mr in mrs:
                # Get assignees
                assignees = ''
                if hasattr(mr, 'assignees') and mr.assignees:
                    assignees = self._safe_join(mr.assignees, 'username')
                elif hasattr(mr, 'assignee') and mr.assignee:
                    assignees = mr.assignee.get('username', '')

                # Get reviewers
                reviewers = ''
                if hasattr(mr, 'reviewers') and mr.reviewers:
                    reviewers = self._safe_join(mr.reviewers, 'username')

                # Get labels
                labels = self._safe_join(mr.labels if hasattr(mr, 'labels') else [])

                # Get milestone
                milestone = ''
                if hasattr(mr, 'milestone') and mr.milestone:
                    milestone = mr.milestone.get('title', '')

                # Check if draft/WIP
                draft = str(getattr(mr, 'draft', False)).lower()
                wip = str(getattr(mr, 'work_in_progress', False)).lower()

                # Add metric for this MR
                metrics['merge_request'].add_metric(
                    [
                        project_id, project_name, namespace,
                        str(mr.iid), str(mr.id),
                        self._safe_str(mr.title, 150),
                        mr.state,
                        mr.author.get('username', 'unknown'),
                        assignees,
                        reviewers,
                        labels,
                        self._safe_str(mr.source_branch),
                        self._safe_str(mr.target_branch),
                        self._safe_str(mr.created_at),
                        self._safe_str(mr.updated_at),
                        self._safe_str(getattr(mr, 'merged_at', '')),
                        self._safe_str(getattr(mr, 'closed_at', '')),
                        draft,
                        wip,
                        milestone,
                        self._safe_str(mr.web_url)
                    ],
                    1
                )

            return len(mrs)

        except Exception as e:
            logger.error(f"Error collecting merge requests for {namespace}/{project_name}: {e}")
            return 0

    def _collect_milestones(self, project, project_id: str, project_name: str, namespace: str, metrics: Dict[str, Any]) -> int:
        """Collect all milestones as individual metrics
        Returns: number of milestones"""
        try:
            milestones = project.milestones.list(all=True)
            logger.info(f"  Found {len(milestones)} milestones")

            for milestone in milestones:
                metrics['milestone'].add_metric(
                    [
                        project_id, project_name, namespace,
                        str(milestone.id),
                        str(milestone.iid),
                        self._safe_str(milestone.title, 150),
                        milestone.state,
                        self._safe_str(milestone.created_at),
                        self._safe_str(milestone.updated_at),
                        self._safe_str(getattr(milestone, 'due_date', '')),
                        self._safe_str(getattr(milestone, 'start_date', '')),
                        self._safe_str(milestone.web_url)
                    ],
                    1
                )

            return len(milestones)

        except Exception as e:
            logger.error(f"Error collecting milestones for {namespace}/{project_name}: {e}")
            return 0

    def _collect_branches(self, project, project_id: str, project_name: str, namespace: str, metrics: Dict[str, Any]) -> int:
        """Collect all branches as individual metrics
        Returns: number of branches"""
        try:
            branches = project.branches.list(all=True)
            logger.info(f"  Found {len(branches)} branches")

            for branch in branches:
                # Get commit info
                commit = branch.commit if hasattr(branch, 'commit') else {}
                commit_sha = commit.get('id', '') if isinstance(commit, dict) else ''
                commit_author = commit.get('author_name', '') if isinstance(commit, dict) else ''
                commit_date = commit.get('created_at', '') if isinstance(commit, dict) else ''

                is_default = 'true' if branch.name == project.default_branch else 'false'

                metrics['branch'].add_metric(
                    [
                        project_id, project_name, namespace,
                        self._safe_str(branch.name),
                        str(branch.protected).lower(),
                        str(getattr(branch, 'merged', False)).lower(),
                        is_default,
                        self._safe_str(commit_sha),
                        self._safe_str(commit_author),
                        self._safe_str(commit_date)
                    ],
                    1
                )

            return len(branches)

        except Exception as e:
            logger.error(f"Error collecting branches for {namespace}/{project_name}: {e}")
            return 0

    def _collect_tags(self, project, project_id: str, project_name: str, namespace: str, metrics: Dict[str, Any]) -> int:
        """Collect all tags as individual metrics
        Returns: number of tags"""
        try:
            tags = project.tags.list(all=True)
            logger.info(f"  Found {len(tags)} tags")

            for tag in tags:
                # Get commit info
                commit = tag.commit if hasattr(tag, 'commit') else {}
                commit_sha = commit.get('id', '') if isinstance(commit, dict) else ''
                commit_author = commit.get('author_name', '') if isinstance(commit, dict) else ''
                commit_date = commit.get('created_at', '') if isinstance(commit, dict) else ''

                # Check if tag has a release
                has_release = 'true' if hasattr(tag, 'release') and tag.release else 'false'

                metrics['tag'].add_metric(
                    [
                        project_id, project_name, namespace,
                        self._safe_str(tag.name),
                        self._safe_str(getattr(tag, 'message', ''), 100),
                        self._safe_str(tag.target),
                        self._safe_str(commit_sha),
                        self._safe_str(commit_author),
                        self._safe_str(commit_date),
                        has_release
                    ],
                    1
                )

            return len(tags)

        except Exception as e:
            logger.error(f"Error collecting tags for {namespace}/{project_name}: {e}")
            return 0

    def _collect_commits(self, project, project_id: str, project_name: str, namespace: str, metrics: Dict[str, Any]) -> int:
        """Collect commits as individual metrics
        Returns: number of commits"""
        try:
            # Get recent commits from default branch (limit to avoid too much data)
            # You can adjust per_page to get more/less commits
            commits = project.commits.list(
                ref_name=project.default_branch,
                per_page=100,
                all=False
            )
            logger.info(f"  Found {len(commits)} recent commits")

            for commit in commits:
                # Get first line of commit message
                message_lines = commit.message.split('\n') if hasattr(commit, 'message') else []
                first_line = message_lines[0] if message_lines else ''

                metrics['commit'].add_metric(
                    [
                        project_id, project_name, namespace,
                        self._safe_str(commit.id),
                        self._safe_str(commit.short_id),
                        self._safe_str(commit.author_name),
                        self._safe_str(commit.author_email),
                        self._safe_str(commit.committer_name),
                        self._safe_str(commit.committer_email),
                        self._safe_str(commit.created_at),
                        self._safe_str(commit.title, 100),
                        self._safe_str(first_line, 150),
                        self._safe_str(commit.web_url)
                    ],
                    1
                )

            return len(commits)

        except Exception as e:
            logger.error(f"Error collecting commits for {namespace}/{project_name}: {e}")
            return 0


def main():
    """Main function"""
    # Configuration from environment variables
    gitlab_url = os.getenv('GITLAB_URL', 'https://gitlab.com')
    gitlab_token = os.getenv('GITLAB_TOKEN')
    group_name = os.getenv('GITLAB_GROUP', 'epitech-msc-2026')
    include_subgroups = os.getenv('INCLUDE_SUBGROUPS', 'true').lower() == 'true'
    port = int(os.getenv('PORT', '8080'))
    refresh_interval = int(os.getenv('REFRESH_INTERVAL', '3600'))  # Default: 1 hour

    if not gitlab_token:
        logger.error("GITLAB_TOKEN environment variable is required")
        exit(1)

    logger.info(f"Starting GitLab KPIs Exporter...")
    logger.info(f"GitLab URL: {gitlab_url}")
    logger.info(f"Group: {group_name}")
    logger.info(f"Include subgroups: {include_subgroups}")
    logger.info(f"Refresh interval: {refresh_interval} seconds")
    logger.info(f"Port: {port}")

    # Create collector
    collector = GitLabKPICollector(gitlab_url, gitlab_token, group_name, include_subgroups)

    # Register collector
    REGISTRY.register(collector)

    # Start HTTP server
    start_http_server(port)
    logger.info(f"Metrics server started on port {port}")
    logger.info(f"Metrics available at http://localhost:{port}/metrics")

    # Keep the server running
    try:
        while True:
            time.sleep(refresh_interval)
            logger.info("Metrics will be refreshed on next scrape")
    except KeyboardInterrupt:
        logger.info("Shutting down...")


if __name__ == '__main__':
    main()
