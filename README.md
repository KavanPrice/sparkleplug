# sparkleplug - A Sparkplug library for Gleam

[![Package Version](https://img.shields.io/hexpm/v/sparkleplug)](https://hex.pm/packages/sparkleplug)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sparkleplug/)

## Overview
This library provides some representations of [Sparkplug B](https://sparkplug.eclipse.org/specification/) objects within the
Gleam type system, as well as some basic utilities for interacting with them.
Both Erlang and Javascript targets are supported.

```sh
gleam add sparkleplug@1
```
```gleam
import sparkleplug

pub fn main() {
  // A simple JSON-encoded Sparkplug B payload.
  let payload_string =
    "{
      \"timestamp\": 1486144502122,
      \"metrics\": [
        {
          \"name\": \"My Metric\",
          \"alias\": 1,
          \"timestamp\": 1479123452194,
          \"dataType\": \"String\",
          \"value\": \"Test\"
        }
      ],
      \"seq\": 2
    }"

    // This gives you a decoded Payload type to use in your Gleam program.
    let assert Ok(decoded_payload) = sparkleplug.string_to_sparkplug_payload(payload)
    ...
  }
}
```

Further documentation can be found at <https://hexdocs.pm/sparkleplug>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
## Limitations
There is currently very limited support for Sparkplug data sets, templates,
property sets, and metric extensions.
