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

local from_json       = require("lapis.util").from_json
local inspect         = require("inspect")
local request         = require("lapis.spec.server").request
local tablex          = require("pl.tablex")
local to_json         = require("lapis.util").to_json
local use_test_server = require("lapis.spec").use_test_server

describe("DryFHIR", function()
    use_test_server()

    local generic_small_resource = {
      text = {
        status = "generated",
        div = "<div xmlns=\"http://www.w3.org/1999/xhtml\"> <h1>Eve Everywoman</h1> </div>"
      },
      resourceType = "Patient",
      name = {
        {
          family = {
            "Everywoman1"
          },
          text = "Eve Everywoman",
          given = {
            "Eve"
          }
        }
      },
      active = true
    }

    local existing_resource, existing_resource_id

    setup(function()
        local sent_resource = tablex.deepcopy(generic_small_resource)

        local status, received_resource_json = request("/Patient", {post = to_json(sent_resource), headers = {["Content-Type"] = "application/fhir+json"}})

        local received_resource = from_json(received_resource_json)

        existing_resource_id = received_resource.id
        existing_resource = received_resource
      end)

    it("should have a resource history operation", function()
        -- GET [base]/[type]/[id]/_history/[vid]
        local status, body = request("/Patient/"..existing_resource_id.."/_history/")

        assert.same(200, status)
        assert.truthy(body:match("%f[%a]history%f[%A]"))
      end)

    it("should have a working vread operation", function()
        -- GET [base]/[type]/[id]/_history/[vid]

        local status, body = request("/Patient/"..existing_resource_id.."/_history/")
        local existing_resource_version = from_json(body).entry[1].resource.meta.versionId

        status, body = request("/Patient/"..existing_resource_id.."/_history/"..existing_resource_version, {method = "GET"})

        assert.same(200, status)
        assert.truthy(from_json(body).meta.versionId == existing_resource_version)
      end)

    it("should have a working update operation", function()
        -- PUT [base]/[type]/[id]

        local sent_resource = tablex.deepcopy(existing_resource)
        local status, body, headers = request("/Patient/"..existing_resource_id, {post = to_json(sent_resource), method = "PUT", headers = {["Content-Type"] = "application/fhir+json"}})

        assert.same(200, status)
        assert.truthy(headers["Last-Modified"])
      end)

    it("should should fail an update operation without content", function()
        -- PUT [base]/[type]/[id]
        local status, body = request("/Patient/1", {method = "PUT"})

        assert.same(400, status)
      end)

    it("should have a working delete operation", function()
        -- DELETE [base]/[type]/[id]
        local status, body = request("/Patient/"..existing_resource_id, {method = "DELETE"})

        assert.same(200, status)
      end)

    it("should have a working create operation", function()
        -- POST [base]/[type]

        local sent_resource = tablex.deepcopy(generic_small_resource)

        local status, received_resource_json, headers = request("/Patient", {post = to_json(sent_resource), headers = {["Content-Type"] = "application/fhir+json"}})

        local received_resource = from_json(received_resource_json)
        -- check if sent_resource is a subset of received_resource instead, perhaps?
        -- for now, copy over properties we're expecting to get added by fhirbase
        sent_resource.meta = received_resource.meta
        sent_resource.id = received_resource.id

        assert.same(sent_resource, received_resource)

        assert.same(201, status)

        assert.truthy(headers.Location)
      end)

    it("should have a working read operation", function()
        -- GET [base]/[type]/[id]

        local sent_resource = tablex.deepcopy(generic_small_resource)

        -- create a patient
        local status, received_resource_json = request("/Patient", {post = to_json(sent_resource)})
        assert.same(201, status)

        -- pull new id out
        local resource_id = from_json(received_resource_json).id

        status, received_resource_json = request("/Patient/"..resource_id, {method = "GET"})
        local received_resource = from_json(received_resource_json)

        sent_resource.meta = received_resource.meta
        sent_resource.id = received_resource.id
        assert.same(sent_resource, received_resource)

        assert.same(200, status)
      end)

    it("should have a working search operation via GET", function()
        -- GET [base]/[type]
        local status, body = request("/Patient", {method = "GET", headers = {["Content-Type"] = "application/fhir+json"}})

        assert.same(200, status)
        assert.truthy(body:match("%f[%a]searchset%f[%A]"))
        assert.truthy(body:match("Patient"))

        -- check that DryFHIR pads the results with fullUrl's that fhirbase doesn't provide
        assert.truthy(body:match("%f[%a]fullUrl%f[%A]"))
      end)

    it("should have a working search operation via POST", function()
        -- POST [base]/[type]/_search
        local status, body = request("/Patient/_search", {method = "POST"})

        assert.same(200, status)
        assert.truthy(body:match("%f[%a]searchset%f[%A]"))
        assert.truthy(body:match("Patient"))

        -- check that DryFHIR pads the results with fullUrl's that fhirbase doesn't provide
        assert.truthy(body:match("%f[%a]fullUrl%f[%A]"))
      end)

    it("should have a working conformance operation via GET", function()
        -- GET [base]/metadata {?_format=[mime-type]}
        local status, body = request("/metadata", {method = "GET"})

        assert.same(200, status)

        local resource = from_json(body)
        assert.truthy(resource.resourceType)
        assert.same(resource.resourceType, "Conformance")
      end)

    it("should return a 400 OperationOutcome on an invalid URL", function()
        local status, body = request("/dfdfdf/adfdfdf/dfddf")

        assert.same(400, status)

        local resource = from_json(body)
        assert.truthy(resource.resourceType)
        assert.same(resource.issue[1].code, "not-supported")
        assert.same(resource.issue[1].severity, "error")
      end)
  end)
