package canary

cloudwatch_map: {
	google: sns_topic_email:  "alerts-primary@example.com"
	youtube: sns_topic_email: "alerts-secondary@example.com"

	"httpbin-api": {
		type:            "api"
		sns_topic_email: "alerts-primary@example.com"
		endpoint:        "https://httpbin.org/status/200"
		expected_status: 200
		max_latency_ms:  3000
	}

	"httpbin-json": {
		type:            "api"
		sns_topic_email: "alerts-primary@example.com"
		endpoint:        "https://httpbin.org/json"
		expected_status: 200
		max_latency_ms:  3000
		body_contains:   "slideshow"
		json_assertions: "slideshow.title": "Sample Slide Show"
	}

	// Domino Data Lab canaries -- placeholders, disabled until a real
	// deployment URL + secret are available. Flip start_canary to true once set.
	"domino-start-job": {
		type:                "domino"
		sns_topic_email:     "alerts-primary@example.com"
		endpoint:            "https://REPLACE-ME.domino.example.com"
		api_key_secret_arn:  "arn:aws:secretsmanager:us-east-1:123456789012:secret:domino/api-key-REPLACE"
		project_id:          "REPLACE_WITH_PROJECT_ID"
		domino_action:       "job"
		run_command:         "main.py"
		max_latency_ms:      10000
		start_canary:        false
		schedule_expression: "rate(1 hour)"
	}

	"domino-start-workspace": {
		type:                "domino"
		sns_topic_email:     "alerts-primary@example.com"
		endpoint:            "https://REPLACE-ME.domino.example.com"
		api_key_secret_arn:  "arn:aws:secretsmanager:us-east-1:123456789012:secret:domino/api-key-REPLACE"
		project_id:          "REPLACE_WITH_PROJECT_ID"
		workspace_id:        "REPLACE_WITH_WORKSPACE_ID"
		domino_action:       "workspace"
		max_latency_ms:      15000
		start_canary:        false
		schedule_expression: "rate(1 hour)"
	}
}
