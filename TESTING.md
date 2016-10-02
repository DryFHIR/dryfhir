# Testing and test policy

Appropriate unit tests for any new features must be written in spec/tests.lua right upon feature creation. Creating tests ensures quality of the codebase, allows for frequent refactoring improvement and makes the codebase much more friendlier to new developers.

## Running tests

```bash
# run DryFHIR in test mode at least once manually to initialise database
lapis server test

# then, just use the 'busted' command while in dryfhir/ to run all tests available
busted
```
