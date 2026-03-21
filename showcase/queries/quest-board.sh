#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format ndjson \
  | jq -r -s '
      def day: 86400;
      def STALE_DAYS: 7;
      def RECENT_FINISHED_DAYS: 7;
      def now_s: (now | floor);

      def is_project_link:
        (.resolved == true and (.resolved_path | startswith("projects/")));

      def task_state:
        if (.tags | index("needs-decision")) then "needs-decision"
        elif (.tags | index("blocked")) then "blocked"
        elif ((.tags | index("wait")) or (.tags | index("waiting")) or (.tags | index("waitingfor"))) then "waiting"
        else null
        end;

      def fmt_date(epoch):
        (epoch | strftime("%Y-%m-%d"));

      def wiki_path(rel_path):
        "[[/" + (rel_path | sub("\\.md$"; "")) + "]]";

      def section_message(section):
        {
          "Needs Decision": "No projects need a decision.",
          "Blocked": "No blocked projects.",
          "Waiting": "No waiting projects.",
          "Stale": "No stale projects.",
          "Active": "No active projects.",
          "Recently Finished": "No recently finished projects."
        }[section];

      def render_reason(task):
        if task == null then ""
        elif (task.source_rank // 0) == 1 then (wiki_path(task.rel_path) + " " + task.text)
        else (task.text // "")
        end;

      def card(p):
        [
          "### " + wiki_path(p.rel_path),
          (if (p.frontmatter.goal // "") != "" then "- Goal: " + (p.frontmatter.goal | tostring) else empty end),
          (if (p.reason // "") != "" then "- Reason: " + (p.reason // "") else empty end),
          "- Counts: open " + (p.counts.open | tostring)
            + ", needs-decision " + (p.counts.needs_decision | tostring)
            + ", blocked " + (p.counts.blocked | tostring)
            + ", waiting " + (p.counts.waiting | tostring),
          "- Updated: " + fmt_date(p.mtime),
          ""
        ] | .[];

      def render_section(name; items):
        [
          "## " + name,
          (if (items | length) == 0 then section_message(name) else empty end),
          "",
          (items[] | card(.))
        ] | .[];

      . as $records
      | ($records | map(select(.type == "page"))) as $pages
      | ($records | map(select(.type == "task" and (.completed | not)))) as $tasks
      | ($records | map(select(.type == "link")) | map(select(is_project_link))) as $links
      | ($pages | map(select(.frontmatter.type == "project"))) as $project_pages
      | (reduce $project_pages[] as $p ({}; .[$p.rel_path] = $p)) as $project_map
      | ($project_pages | map(.rel_path)) as $project_keys
      | (reduce $tasks[] as $t ({}; .[$t.rel_path + ":" + ($t.line | tostring)] = $t)) as $tasks_by_loc
      | (
          $links
          | map(select((.rel_path | startswith("diary/")) and ((.resolved_path as $rp | $project_keys | index($rp)) != null)))
          | map({ target: .resolved_path, loc: (.rel_path + ":" + (.line | tostring)) })
        ) as $diary_project_locs
      | (
          $project_pages
          | map(
              . as $p
              | ($p.rel_path) as $k
              | ($tasks | map(select(.rel_path == $k)) | map(. + {source_rank: 0})) as $own_tasks
              | (
                  $diary_project_locs
                  | map(select(.target == $k))
                  | map(.loc)
                  | unique
                  | map($tasks_by_loc[.])
                  | map(select(. != null))
                  | map(. + {source_rank: 1})
                ) as $linked_diary_tasks
              | ($own_tasks + $linked_diary_tasks | unique_by(.id)) as $rows
              | ($rows
                  | map(. + { state: (task_state) })
                  | map(. + { state: (.state // null) })
                ) as $rows_with_state
              | ($rows_with_state | map(select(.state != null))) as $state_rows
              | ($state_rows | map(select(.state == "needs-decision")) | length) as $needs_decision_count
              | ($state_rows | map(select(.state == "blocked")) | length) as $blocked_count
              | ($state_rows | map(select(.state == "waiting")) | length) as $waiting_count
              | ($rows_with_state | length) as $open_count
              | ($p.file.mtime | tonumber) as $mtime
              | ((now_s - $mtime) / day | floor) as $age_days
              | ($p.frontmatter.status // "") as $status
              | (
                  if $status == "archived" then
                    (if $age_days <= RECENT_FINISHED_DAYS then "Recently Finished" else null end)
                  elif $needs_decision_count > 0 then
                    "Needs Decision"
                  elif $blocked_count > 0 then
                    "Blocked"
                  elif $waiting_count > 0 then
                    "Waiting"
                  elif $age_days > STALE_DAYS then
                    "Stale"
                  elif $open_count > 0 or (($p.frontmatter.next_step // "") != "") then
                    "Active"
                  else
                    null
                  end
                ) as $section
              | (
                  if $section == null then
                    null
                  else
                    (
                      if $section == "Needs Decision" then
                        ($rows_with_state
                          | map(select(.state == "needs-decision"))
                          | sort_by([.source_rank, .rel_path, .line, .id])
                          | .[0])
                      elif $section == "Blocked" then
                        ($rows_with_state
                          | map(select(.state == "blocked"))
                          | sort_by([.source_rank, .rel_path, .line, .id])
                          | .[0])
                      elif $section == "Waiting" then
                        ($rows_with_state
                          | map(select(.state == "waiting"))
                          | sort_by([.source_rank, .rel_path, .line, .id])
                          | .[0])
                      elif $section == "Active" then
                        (
                          if (($p.frontmatter.next_step // "") != "") then
                            { text: ($p.frontmatter.next_step | tostring), rel_path: $k, source_rank: 0 }
                          else
                            ($rows_with_state | sort_by([.source_rank, .rel_path, .line, .id]) | .[0])
                          end
                        )
                      elif $section == "Stale" then
                        (
                          if (($p.frontmatter.next_step // "") != "") then
                            { text: ($p.frontmatter.next_step | tostring), rel_path: $k, source_rank: 0 }
                          else
                            { text: "No recent project-page updates.", rel_path: $k, source_rank: 0 }
                          end
                        )
                      else
                        null
                      end
                    ) as $reason_task
                    | {
                        section: $section,
                        rel_path: $k,
                        frontmatter: ($p.frontmatter // {}),
                        mtime: $mtime,
                        counts: {
                          open: $open_count,
                          needs_decision: $needs_decision_count,
                          blocked: $blocked_count,
                          waiting: $waiting_count
                        },
                        reason: render_reason($reason_task)
                      }
                  end
                )
            )
          | map(select(. != null))
        ) as $projects
      | "# Quest Board",
        "",
        (
          [
            "Needs Decision",
            "Blocked",
            "Waiting",
            "Stale",
            "Active",
            "Recently Finished"
          ]
          | .[]
          | . as $name
          | ($projects | map(select(.section == $name)) | sort_by([.mtime, .rel_path])) as $items
          | render_section($name; $items),
            ""
        )
    '
