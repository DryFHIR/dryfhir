-- config.lua
local config = require("lapis.config")

config({"development", "heroku", "test", "prod", "dockerdev", "dockerprod"}, {
  email_enabled = false,
  secret = "not-set-yet",
  session_name = "dryfhir_session",
  num_workers = "1",
  logging = {
    queries = true,
    requests = true
  },
  postgres = {
    backend = "pgmoon",
    host = "db",
    port = "5432",
    user = "postgres",
    database = "fhirbase",
  },
  print_stack_to_browser = false
})

config("development", {
  port = 8080,
  print_stack_to_browser = true
})

config("dockerdev", {
  port = 80,
  print_stack_to_browser = true
})

config("heroku", {
  port = os.getenv("PORT"),
  code_cache = "on",
  host = "morning-gorge-82517.herokuapp.com",
})

config("test", {
  postgres = {
    database = "fhirbase-test",
  },
  logging = { queries = false },
  print_stack_to_browser = true
})

config({"prod", "dockerprod"}, {
  port = 80,
  logging = {
    queries = false,
    requests = true
  },
  num_workers = "8",
  code_cache = "on",
})

-- template responses

config({"development", "heroku", "test", "prod", "dockerdev", "dockerprod"}, {
  canned_responses = {
    handle_404 = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "this operation is not supported"
      },
      issue = {
        [1] = {
          severity = "error",
          code = "not-supported"
          -- add what server knows how to handle here
        }
      }
    }, status = 400},
    handle_missing_body = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "resource body is missing in a POST or a PUT operation"
      },
      issue = {
        [1] = {
          severity = "error",
          code = "invalid" -- https://hl7-fhir.github.io/codesystem-issue-type.html#invalid
          -- invalid content, as in, it is missing entirely
        }
      }
    }, status = 400}
  }
})
