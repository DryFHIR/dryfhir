--[[
    Copyright 2016 Vadim Peretokin. All Rights Reserved.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS-IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
]]

--[[
  This is only used by init_by_lua* only to setup fhirbase storage once when lapis starts.
  pgmoon is used instead of lapis.db, as lapis.db isn't supported in that context.
]]


io.input("nginx.conf.compiled")
-- read the environment we're using in, as at this point LAPIS_ENVIRONMENT hasn't been set yet
-- (remember we're running this in init_by_lua*)
local environment = io.read("*all"):match("env LAPIS_ENVIRONMENT=(%w+)")
local config  = require("lapis.config").get(environment)
io.input():close()
local pgmoon  = require("pgmoon")

local db = pgmoon.new({
  host = config.postgres.host,
  port = config.postgres.port,
  database = config.postgres.database,
  user = config.postgres.user
})


assert(db:connect())

local init = {config = config}

-- recursively extracts values from a table
init.extract_values = function(tbl, values)
  local values = values or {}

  for _,v in pairs(tbl) do
    if type(v) == "table" then
      init.extract_values(v, values)
    else
      values[#values+1] = v
    end
  end

  return values
end

-- returns a list of resources known to fhirbase. TODO - memoize results
init.get_fhirbase_resources = function()
  local res = db:query("select id from structuredefinition")
  return init.extract_values(res)
end

-- creates fhirbase storage from a list of resources
init.setup_fhirbase = function(known_fhirbase_resources)
  for i = 1, #known_fhirbase_resources do
    local storage = known_fhirbase_resources[i]
    -- it checks if the table already exists for us already
    -- TODO: upgrade fhirbase and use fhir_create_all_storages()
    assert(db:query([[select fhir_create_storage('{"resourceType": "]]..storage..[["}')]]))
  end
end

-- returns true if the given storage exists
init.storage_exists = function(storage)
  return next(db:query("select table_name from information_schema.tables where table_name = ?", storage:lower())) and true or false
end
init.table_exists = init.storage_exists

-- populates up the given ngx shared dictionary's with a key-value list of known resources
init.setup_app_dryfhir = function(known_fhirbase_resources, ngxdict)
  table.sort(known_fhirbase_resources)
  for i = 1, #known_fhirbase_resources do
    local resource = known_fhirbase_resources[i]
    local saved, err = ngxdict:safe_set(resource, true)
    if not saved then ngx.log(ngx.ERR, "Could not record ", resource, " as a known resource - DryFHIR will not realise that it's capable of handling this resource. Nginx error was: ", err) end
  end
end

return init
