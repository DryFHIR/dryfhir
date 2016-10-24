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
    port = "5432",
    database = "fhirbase",
  },
  print_stack_to_browser = false,
  conditinal_delete_max_resouces = 1000000, -- max # of resources to delete in one go for multiple matches in a conditinal resource

  -- fhir-related variables
  fhir_conformance_status = "draft",    -- http://hl7-fhir.github.io/conformance-definitions.html#Conformance.status
  fhir_conformance_experimental = true, -- http://hl7-fhir.github.io/conformance-definitions.html#Conformance.experimental
  fhir_multiple_conditional_delete = true, -- when enabled, deletes all resources that match a conditional delete. when disabled,
                                           -- errors if multiple resources match a conditional delete

})

config({"development", "heroku", "test", "prod"}, {
  postgres = {
    host = "127.0.0.1",
    user = "postgres",
  },
  resolver_string = ""
})

config({"dockerdev", "dockerprod"}, {
  postgres = {
    host = "db",
    user = "fhirbase",
  },
  resolver_string = "resolver 127.0.0.11;"
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
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">This operation or resource is unsupported. Known resources are: %s</div>"
      },
      issue = {
        [1] = {
          severity = "error",
          code = "not-supported",
          diagnostics = "This operation or resource is unsupported. Known resources are: %s"
        }
      }
    }, status = 404},
    handle_missing_body = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">resource body is missing in a POST or a PUT operation</div>"
      },
      issue = {
        [1] = {
          severity = "error",
          code = "invalid" -- https://hl7-fhir.github.io/codesystem-issue-type.html#invalid
          -- invalid content, as in, it is missing entirely
        }
      }
    }, status = 400},
    conditional_create_resource_already_exists = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">a resource matching the If-None-Exist query already exists</div>"
      }
    }, status = 200},
    conditinal_update_many_resources_exist = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Failed to conditionally update the resource because this search matched 2 or more resources</div>"
      },
      issue = {{
        severity = "error",
        code = "processing",
        diagnostics = "Failed to conditionally update the resource because this search matched 2 or more resources"
      }}
    }, status = 412},
    prefer_successful_operationoutcome = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">The operation has been successfully executed</div>"
      },
      issue = {{
        severity = "information",
        code = "informational",
        diagnostics = "The operation has been successfully executed"
      }}
    }, status = 200},
    conditional_delete_resource_missing = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">No resources exist that match this search parameter</div>"
      },
      issue = {{
        severity = "information",
        code = "informational",
        diagnostics = "No resources exist that match this search parameter"
      }}
    }, status = 404},
    conditional_delete_multiple_disallowed = {
    {
      resourceType = "OperationOutcome",
      text = {
        status = "generated",
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Multiple resources matched this deletion request - only one match is allowed</div>"
      },
      issue = {{
        severity = "error",
        code = "processing",
        diagnostics = "Multiple resources matched this deletion request - only one match is allowed"
      }}
    }, status = 404},
  }
})
