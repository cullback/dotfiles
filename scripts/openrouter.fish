#!/usr/bin/env fish

function call_api
    set -l options 'm/model=' 's/schema='
    argparse $options -- $argv
    or return 1

    set -l prompt_file $argv[1]
    set -l data_file $argv[2]

    if test -z "$prompt_file"; or not test -f "$prompt_file"
        set_color red >&2
        echo "Error: Prompt file '$prompt_file' not found." >&2
        set_color normal >&2
        return 1
    end
    if test -z "$data_file"; or not test -f "$data_file"
        set_color red >&2
        echo "Error: Data file '$data_file' not found." >&2
        set_color normal >&2
        return 1
    end

    set -l model google/gemini-3-flash-preview
    if set -q _flag_model
        set model $_flag_model
    end

    # 5. Prepare Payload & Auto-wrap Schema
    set -l prompt_content (cat $prompt_file)
    set -l data_content (jq -Rs . < $data_file)
    set -l final_prompt $prompt_content

    if set -q _flag_schema
        # This takes your array schema and wraps it: {"result": [your_schema]}
        set -l wrapped_schema (jq -n --argjson sch (cat $_flag_schema) '{result: $sch}' | jq -c .)
        set final_prompt "$prompt_content. 
        IMPORTANT: Your response must be valid JSON matching this schema: 
        $wrapped_schema"
    end

    # --- LOGGING: Request Sent ---
    set -l timestamp (date "+%H:%M:%S")
    set_color cyan >&2
    echo "[$timestamp] SENDING: $data_file to $model" >&2
    set_color normal >&2

    # 6. Execute API Call
    set -l response (curl -s https://openrouter.ai/api/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -d "{
        \"model\": \"$model\",
        \"messages\": [
          {\"role\": \"system\", \"content\": $(echo $final_prompt | jq -Rs .)},
          {\"role\": \"user\", \"content\": $data_content}
        ],
        \"response_format\": { \"type\": \"json_object\" }
      }")

    # 7. Process Output
    set -l raw_json (echo $response | jq -r '.choices[0].message.content // empty')

    if test -z "$raw_json"
        set_color red >&2
        echo "[$timestamp] ERROR: No content for $data_file" >&2
        set_color normal >&2
        return 1
    end

    # --- LOGGING: Response Received ---
    set_color green >&2
    echo "[$timestamp] RECEIVED: $data_file" >&2
    set_color normal >&2

    # 8. Output to Final Stream (stdout)
    # Automatically unpacks the 'result' key we forced in the schema
    if echo $raw_json | jq -e '.result' >/dev/null 2>&1
        echo $raw_json | jq -c '.result[]'
    else
        echo $raw_json
    end
end

call_api $argv
