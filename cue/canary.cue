package canary

// Mirrors the cloudwatch_map object type and its three validation blocks in
// ../variables.tf. Kept here as the source of truth: `cue export ./cue --out
// json` produces cloudwatch_map.auto.tfvars.json, which Terraform loads
// automatically. #Canary is a definition (the "#" prefix) so, unlike the
// cloudwatch_map field below, it is never itself part of exported output.
#Canary: {
	name:                 string
	sns_topic_email:      string
	type:                 *"browser" | "api" | "domino"
	method:               *"GET" | string
	start_canary:         *true | bool
	schedule_expression?: string

	// Optional API response assertions (type == "api"). Any unset check is skipped.
	endpoint?:        string
	expected_status?: number
	max_latency_ms?:  number // also used by "domino"
	body_contains?:   string
	json_assertions?: [string]: string
	request_headers?: [string]: string
	request_body?: string

	// Domino Data Lab options (type == "domino").
	project_id?:    string
	workspace_id?:  string // required when domino_action == "workspace"
	domino_action?: "job" | "workspace"
	run_command?:   string
	cleanup?:       bool

	// API key (X-Domino-Api-Key): prefer Secrets Manager over the plaintext fallback.
	api_key_secret_arn?:      string
	api_key_secret_json_key?: string
	api_key?:                 string

	// Run this canary inside the AFT shared VPC (internal/private endpoints).
	vpc_enabled?: bool

	if type == "api" {
		// "!" upgrades an optional field to required-and-concrete, so cue
		// export fails if an api canary omits endpoint.
		endpoint!: string & !=""
	}

	if type == "domino" {
		endpoint!:   string & !=""
		project_id!: string & !=""
		if domino_action == "workspace" {
			workspace_id!: string & !=""
		}
		if api_key_secret_arn == _|_ && api_key == _|_ {
			// Neither key source is set. Force one required so export fails
			// with an "incomplete value" error -- same trick as the "at
			// least one of" idiom in schema/tf/etl.cue's `if != _|_` checks.
			api_key_secret_arn!: string
		}
	}
}

// The map key doubles as the canary name -- unifying it into every entry
// keeps them from ever drifting apart, which plain HCL can't guarantee.
cloudwatch_map: [Name=string]: #Canary & {
	name: Name
}
