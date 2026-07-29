# Build each canary's deployment zip from its source .py at plan time so the
# .py file is the single source of truth (no hand-built zips to drift).
# Browser canaries use their own src/<name>.py; API canaries all share the
# generic src/api_canary.py (parameterized at runtime via environment variables).
# The Synthetics Python runtime loads the handler module from a top-level
# "python/" folder inside the zip, so the .py must live at python/<name>.py
# (the module name must match the handler's "<name>.handler").
#
# aws_synthetics_canary only diffs the zip_file *path*, not its contents, so the
# source hash is baked into output_path. That way any edit to a canary .py yields
# a new path and forces the canary to re-upload its code on the next apply.
data "archive_file" "canary" {
  for_each = var.cloudwatch_map

  type        = "zip"
  output_path = "${path.module}/build/${each.value.name}-${filemd5(local.canaries[each.key].source_path)}.zip"

  source {
    content  = file(local.canaries[each.key].source_path)
    filename = "python/${local.canaries[each.key].source_name}.py"
  }
}
