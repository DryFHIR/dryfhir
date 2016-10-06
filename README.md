<!---
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
-->

# DryFHIR

[DryFHIR](https://github.com/vadi2/dryfhir) is a simple FHIR server, not much more than a learning exersize of the FHIR specification at this stage.

# Releases

No stable releases of the server are available yet as it is under heavy development.

# Running it

See [INSTALL](INSTALL.md) on how to get DryFHIR running.

# Testing

Testing is done with a two-pronged approach: built-in unit tests and [Aegis Touchstone](https://touchstone.aegis.net/touchstone/) testing. To run the built-in tests, run `busted` in the root level of the project. This requires [busted](http://olivinelabs.com/busted/) to be installed. The latest Touchstone results are 992/1064 tests passing from the BasicSTU3--All test setup.

# Further Reading

DryFHIR implements the HL7 FHIR specification, [version 1.4.0](http://hl7.org/fhir/2016May/) (May2016 snapshot).

# Who makes DryFHIR?

DryFHIR is made by Vadim Peretokin, and is licensed under the [Apache License, Version 2.0](LICENSE).

## Contributing

Want to help hack on this? Join the [Gitter](https://gitter.im/dryfhir/Lobby) channel!

### Security disclosures

DryFHIR accepts responsible security disclosures through an email to [dryfhir@gmail.com](mailto:dryfhir@gmail.com).
