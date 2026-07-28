# Build each canary's deployment zip from its source .py at plan time so the
# .py file is the single source of truth (no hand-built zips to drift).
# Browser canaries use their own src/<name>.py; API canaries all share the
# generic src/api_canary.py (parameterized at runtime via environment variables).
# archive_file places the .py at the zip root, matching the handler layout.
data "archive_file" "canary" {
  for_each = var.cloudwatch_map

  type        = "zip"
  source_file = "${path.module}/src/${local.canaries[each.key].source_name}.py"
  output_path = "${path.module}/build/${each.value.name}.zip"
}
