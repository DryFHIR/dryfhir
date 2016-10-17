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

-- app.lua
local config      = require("lapis.config").get()
local console     = require("lapis.console")
local db          = require("lapis.db")
local lapis       = require("lapis")
local pretty      = require("pl.pretty")
local respond_to  = require("lapis.application").respond_to
local routes      = require("views.routes")

-- while inotifywait -e close_write app.lua; do busted; done
-- httperf --server=127.0.0.1 --port=8080 --num-calls=1000 --num-conns=8

local app        = lapis.Application()
app:enable("etlua")


--[[
  Routes are searched first by precedence, then by the order they were defined. Route precedence from highest to lowest is:

  Literal routes /hello/world
  Variable routes /hello/:variable
  Splat routes routes /hello/*

  http://leafo.net/lapis/reference/actions.html#routes-and-url-patterns/route-precedence
]]



app:match("homepage", "(/)", respond_to({
  GET = function()
    return "<h1>Welcome to DryFHIR! The server is still under development, please check back later.</h1>"
  end
}))

app:match("/console", console.make())

-- check that this is a valid resource type
app:before_filter(function(self)
  if self.params.type then
    if not ngx.shared.known_resources:get(self.params.type) then
      self.resource_list = ngx.shared.known_resources:get_keys()
      self:write({layout = "404", status = 404})
    end
  end
end)

app:get("get-metadata", "/metadata(/)", routes.metadata)

app:post("post-search", "/:type/_search(/)", routes.search)

app:get("history-resource", "/:type/:id/_history(/)", routes.get_resource_history)

-- TODO: add test
app:get("vread", "/:type/:id/_history(/:versionId)", routes.vread_resource)

app:match("type/id", "/:type/:id(/)", respond_to({
  GET    = routes.read_resource,
  PUT    = routes.update_resource,
  DELETE = routes.delete_resource
}))

app:match("type", "/:type(/)", respond_to({
  PUT = routes.conditional_update_resource,
  DELETE = function(self)
    local operation = {name = "conditional delete", definition = "http://hl7.org/fhir/http.html#2.1.0.12.1"}

    return { json = {operation.name, self.params} }
  end,
  POST = routes.create_resource,
  GET  = routes.search
}))

app.handle_404 = function()
  return { json = config.canned_responses.handle_404[1], status = config.canned_responses.handle_404.status}
end

if not config.print_stack_to_browser then
    -- http://leafo.net/lapis/reference/actions.html
    app.handle_error = function(_, _, _)
        ngx.say("Sorry, an error occured.")
    end
end

return app
