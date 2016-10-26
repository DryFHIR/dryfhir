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
local escape          = require("lapis.util").escape
local inspect         = require("inspect")
local request         = require("lapis.spec.server").request
local tablex          = require("pl.tablex")
local to_json         = require("lapis.util").to_json
local use_test_server = require("lapis.spec").use_test_server
local db              = require("lapis.db")
local sformat         = string.format

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

    it("should respond with the requested #accept headers", function()
        -- GET [base]/[type]/[id]

        local status, _, headers = request("/Patient/"..existing_resource_id, {method = "GET", headers = {["Accept"] = "application/fhir+json"}})

        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))

        status, _, headers = request("/Patient/"..existing_resource_id, {method = "GET", headers = {["Accept"] = "application/fhir+xml"}})

        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "xml", 1, true))

        -- json is default, so return that if nothing is provided
        status, _, headers = request("/Patient/"..existing_resource_id, {method = "GET"})

        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))

        -- lastly, ensure charset is preserved
        status, _, headers = request("/Patient/"..existing_resource_id, {method = "GET", headers = {["Accept"] = "application/fhir+json;charset=UTF-8"}})

        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "charset=UTF-8", 1, true))

        -- and that it doesn't crash if only charset was provided
        status, _, headers = request("/Patient/"..existing_resource_id, {method = "GET", headers = {["Accept"] = "charset=UTF-8"}})

        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "charset=UTF-8", 1, true))
      end)

    it("should handle the #_format parameter override", function()
        -- GET [base]/[type]/[id]

        -- test all cases of json+json
        local status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=json")), {method = "GET", headers = {["Accept"] = "application/fhir+json"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/json")), {method = "GET", headers = {["Accept"] = "application/fhir+json"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/fhir+json")), {method = "GET", headers = {["Accept"] = "application/fhir+json"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))


        -- test all cases of xml+json
        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=json")), {method = "GET", headers = {["Accept"] = "application/fhir+xml"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/json")), {method = "GET", headers = {["Accept"] = "application/fhir+xml"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/fhir+json")), {method = "GET", headers = {["Accept"] = "application/fhir+xml"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "json", 1, true))

        -- test all cases of json+xml
        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=xml")), {method = "GET", headers = {["Accept"] = "application/fhir+json"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "xml", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/xml")), {method = "GET", headers = {["Accept"] = "application/fhir+json"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "xml", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/fhir+xml")), {method = "GET", headers = {["Accept"] = "application/fhir+json"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "xml", 1, true))

        -- test all cases of xml+xml
        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=xml")), {method = "GET", headers = {["Accept"] = "application/fhir+xml"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "xml", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/xml")), {method = "GET", headers = {["Accept"] = "application/fhir+xml"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "xml", 1, true))

        status, _, headers = request(sformat("/Patient/%s?%s", existing_resource_id, escape("_format=application/fhir+xml")), {method = "GET", headers = {["Accept"] = "application/fhir+xml"}})
        assert.same(200, status)
        assert.truthy(string.find(headers["Content-Type"], "xml", 1, true))
      end)

    it("should have a resource #history operation", function()
        -- GET [base]/[type]/[id]/_history/[vid]
        local status, body = request("/Patient/"..existing_resource_id.."/_history/")

        assert.same(200, status)
        assert.truthy(body:match("%f[%a]history%f[%A]"))

        -- check that DryFHIR pads the results with fullUrl's that fhirbase doesn't provide
        assert.truthy(body:match("%f[%a]fullUrl%f[%A]"))
      end)

    it("should have a working #vread operation", function()
        -- GET [base]/[type]/[id]/_history/[vid]

        local status, body = request("/Patient/"..existing_resource_id.."/_history/")
        local existing_resource_version = from_json(body).entry[1].resource.meta.versionId

        status, body = request("/Patient/"..existing_resource_id.."/_history/"..existing_resource_version, {method = "GET"})

        assert.same(200, status)
        assert.truthy(from_json(body).meta.versionId == existing_resource_version)
      end)

    it("should have a working #update operation", function()
        -- PUT [base]/[type]/[id]

        local sent_resource = tablex.deepcopy(existing_resource)
        local status, body, headers = request("/Patient/"..existing_resource_id, {post = to_json(sent_resource), method = "PUT", headers = {["Content-Type"] = "application/fhir+json"}})

        assert.same(200, status)
        assert.truthy(headers["Last-Modified"])

        local new_resource_version = from_json(body).meta.versionId
        assert.truthy(string.find(headers.Location, sformat("Patient/%s/_history/%s", existing_resource_id, new_resource_version), 1, true))

        assert.truthy(headers["ETag"])
        assert.same(sformat('W/"%s"', new_resource_version), headers["ETag"])
      end)

    it("should return 201 on an #update to a non-existing resource", function()
        -- PUT [base]/[type]/[id]

        local sent_resource = tablex.deepcopy(existing_resource)
        local new_resource_id = "patient-update-create-01"
        sent_resource.id = new_resource_id
        local status, body, headers = request("/Patient/"..new_resource_id, {post = to_json(sent_resource), method = "PUT", headers = {["Content-Type"] = "application/fhir+json"}})

        assert.same(201, status)
        assert.truthy(headers["Last-Modified"])

        local new_resource_version = from_json(body).meta.versionId
        assert.truthy(string.find(headers.Location, sformat("Patient/%s/_history/%s", new_resource_id, new_resource_version), 1, true))

        assert.truthy(headers["ETag"])
        assert.same(sformat('W/"%s"', new_resource_version), headers["ETag"])
      end)

    it("should should fail an #update operation without content", function()
        -- PUT [base]/[type]/[id]
        local status, body = request("/Patient/1", {method = "PUT"})

        assert.same(400, status)
      end)

    it("should have a working #delete operation", function()
        -- DELETE [base]/[type]/[id]
        local status, body = request("/Patient/"..existing_resource_id, {method = "DELETE"})

        assert.same(204, status)
      end)

    it("should have a working #create operation", function()
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

        assert.truthy(string.find(headers.Location, sformat("Patient/%s/_history/%s", received_resource.id, received_resource.meta.versionId), 1, true))

        assert.truthy(headers["Last-Modified"])

        assert.truthy(headers["ETag"])
        assert.same(sformat('W/"%s"', received_resource.meta.versionId), headers["ETag"])
      end)

    it("should have a working #read operation", function()
        -- GET [base]/[type]/[id]

        local sent_resource = tablex.deepcopy(generic_small_resource)

        -- create a patient
        local status, received_resource_json = request("/Patient", {post = to_json(sent_resource)})
        assert.same(201, status)

        -- pull new id out
        local resource_id = from_json(received_resource_json).id

        local headers
        status, received_resource_json, headers = request("/Patient/"..resource_id, {method = "GET"})
        local received_resource = from_json(received_resource_json)

        sent_resource.meta = received_resource.meta
        sent_resource.id = received_resource.id
        assert.same(sent_resource, received_resource)

        assert.same(200, status)

        assert.truthy(headers["ETag"])
      end)

    it("should have a working #search operation via GET", function()
        -- GET [base]/[type]
        local status, body = request("/Patient", {method = "GET", headers = {["Content-Type"] = "application/fhir+json"}})

        assert.same(200, status)
        assert.truthy(body:match("%f[%a]searchset%f[%A]"))
        assert.truthy(body:match("Patient"))

        -- check that DryFHIR pads the results with fullUrl's that fhirbase doesn't provide
        assert.truthy(body:match("%f[%a]fullUrl%f[%A]"))
      end)

    it("should have a working #search operation via POST", function()
        -- POST [base]/[type]/_search
        local status, body = request("/Patient/_search", {method = "POST"})

        assert.same(200, status)
        assert.truthy(body:match("%f[%a]searchset%f[%A]"))
        assert.truthy(body:match("Patient"))

        -- check that DryFHIR pads the results with fullUrl's that fhirbase doesn't provide
        assert.truthy(body:match("%f[%a]fullUrl%f[%A]"))
      end)

    it("should have a working #conformance operation via GET", function()
        -- GET [base]/metadata {?_format=[mime-type]}
        local status, body = request("/metadata", {method = "GET"})

        assert.same(200, status)

        local resource = from_json(body)
        assert.truthy(resource.resourceType)
        assert.same(resource.resourceType, "Conformance")
      end)

    it("should return a 400 OperationOutcome on an invalid URL", function()
        local status, body = request("/dfdfdf/adfdfdf/dfddf")

        assert.same(404, status)

        local resource = from_json(body)
        assert.truthy(resource.resourceType)
        assert.same(resource.issue[1].code, "not-supported")
        assert.same(resource.issue[1].severity, "error")
      end)

    it("should respond with a #404 to an invalid resource type", function()
        -- DELETE [base]/[type]/[id]
        local status, body, headers = request("/Patent/"..existing_resource_id)

        assert.same(404, status)
        -- it should at least mention Patient in the list of known resources
        assert.truthy(string.find(body, 'Patient', 1, true))
        assert.truthy(headers["Content-Type"], "application/fhir+json")
      end)


    describe("#conditionalcreate suite of tests", function()
        local test_resource
        setup(function()
            local res = db.query("truncate patient")
            res = db.query("truncate patient_history")

            test_resource = {
                text = {
                    status = "generated",
                    div = "<div xmlns=\"http://www.w3.org/1999/xhtml\"> <h1>Given Lastname</h1> </div>"
                },
                resourceType = "Patient",
                name = {
                {
                  family = {
                    "Lastname"
                  },
                  text = "Given Lastname",
                  given = {
                    "Given"
                  }
                }
                },
                active = true
            }
        end)

        it("should create and return 201 when no resource previously existed", function()
            local status = request("/Patient", {post = to_json(test_resource), method = "POST", headers = {["If-None-Exist"] = "family=Lastname&given=Given"}})
            assert.same(201, status)
        end)

        it("shouldn't change anything and return 200 if one matching resource already exists", function()
            local status = request("/Patient", {post = to_json(test_resource), method = "POST", headers = {["If-None-Exist"] = "family=Lastname&given=Given"}})
            assert.same(200, status)
        end)

        it("shouldn't change anything and return a 412 error if multiple copies of the resource already exist", function()
            local status, body = request("/Patient", {post = to_json(test_resource), method = "POST"})
            assert.same(201, status)
            status, body = request("/Patient", {post = to_json(test_resource), method = "POST", headers = {["If-None-Exist"] = "family=Lastname&given=Given"}})
            assert.same(412, status)
        end)
    end)

    describe("#conditionalcreate suite of tests", function()
        local test_resource
        setup(function()
            local res = db.query("truncate patient")
            res = db.query("truncate patient_history")

            test_resource = {
                text = {
                    status = "generated",
                    div = "<div xmlns=\"http://www.w3.org/1999/xhtml\"> <h1>Given Lastname</h1> </div>"
                },
                resourceType = "Patient",
                name = {
                {
                  family = {
                    "Lastname"
                  },
                  text = "Given Lastname",
                  given = {
                    "Given"
                  }
                }},
                active = true
            }
        end)

        it("should create and return 201 when no resource previously existed", function()
            local status, body = request("/Patient", {post = to_json(test_resource), method = "PUT", headers = {["If-None-Exist"] = "family=Lastname&given=Given"}})
            assert.same(201, status)
            assert.truthy(string.find(body, '"active":true', 1, true))
        end)

        it("should update and return 200 if one matching resource already exists", function()
            test_resource.active = false

            local status, body = request("/Patient", {post = to_json(test_resource), method = "PUT", headers = {["If-None-Exist"] = "family=Lastname&given=Given"}})
            assert.same(200, status)
            assert.truthy(string.find(body, '"active":false', 1, true))
        end)

        it("shouldn't change anything and return a 412 error if multiple copies of the resource already exist", function()
            local status, body = request("/Patient", {post = to_json(test_resource), method = "POST"})
            assert.same(201, status)
            status, body = request("/Patient", {post = to_json(test_resource), method = "PUT", headers = {["If-None-Exist"] = "family=Lastname&given=Given"}})
            assert.same(412, status)
        end)
    end)

    it("should have support for the #prefer header", function()
        local sent_resource = tablex.deepcopy(existing_resource)
        local status, body, headers = request("/Patient/"..existing_resource_id, {post = to_json(sent_resource), method = "PUT", headers = {["Prefer"] = "return=minimal", ["Accept"] = "application/fhir+json"}})

        assert.same(201, status)
        assert.same("", body)
        -- doesn't work yet
        assert.same(nil, headers["Content-Type"])

        status, body, headers = request("/Patient/"..existing_resource_id, {post = to_json(sent_resource), method = "PUT", headers = {["Prefer"] = "return=representation", ["Accept"] = "application/fhir+json"}})

        assert.same(200, status)
        assert.truthy(string.find(body, "Eve Everywoman", 1, true))

        status, body, headers = request("/Patient/"..existing_resource_id, {post = to_json(sent_resource), method = "PUT", headers = {["Prefer"] = "return=OperationOutcome", ["Accept"] = "application/fhir+json"}})

        assert.same(200, status)
        assert.truthy(string.find(body, "OperationOutcome", 1, true))
      end)

    describe("#conditionaldelete suite of tests", function()
        local test_resource
        setup(function()
            test_resource = {
                text = {
                    status = "generated",
                    div = "<div xmlns=\"http://www.w3.org/1999/xhtml\"> <h1>Name Family</h1> </div>"
                },
                resourceType = "Patient",
                name = {
                {
                  family = {
                    "Family"
                  },
                  text = "Name Family",
                  given = {
                    "Name"
                  }
                }},
                active = true
            }
        end)

        it("should delete multiple resources previously created", function()
            local status, body
            status = request("/Patient", {post = to_json(test_resource), method = "POST"})
            assert.same(201, status)
            status = request("/Patient", {post = to_json(test_resource), method = "POST"})
            assert.same(201, status)
            status = request("/Patient", {post = to_json(test_resource), method = "POST"})
            assert.same(201, status)
            status = request("/Patient", {post = to_json(test_resource), method = "POST"})
            assert.same(201, status)

            status = request("/Patient/?name=name", {method = "DELETE"})
            assert.same(204, status)

            status, body = request("/Patient/?name=name", {method = "GET", headers = {["Content-Type"] = "application/fhir+json"}})
            assert.same(200, status)
            assert.same(0, from_json(body).total)
        end)

        it("should delete one resources previously created", function()
            local status, body
            status = request("/Patient", {post = to_json(test_resource), method = "POST"})
            assert.same(201, status)

            status = request("/Patient/?name=name", {method = "DELETE"})
            assert.same(204, status)

            status, body = request("/Patient/?name=name", {method = "GET", headers = {["Content-Type"] = "application/fhir+json"}})
            assert.same(200, status)
            assert.same(0, from_json(body).total)
        end)

        it("should be fine with no resources left to delete", function()
            local status = request("/Patient/?name=name", {method = "DELETE"})
            assert.same(404, status)
        end)
    end)
  end)
