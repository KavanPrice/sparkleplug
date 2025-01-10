import gleeunit
import gleeunit/should
import sparkleplug

pub fn main() {
  gleeunit.main()
}

pub fn successful_decode_metric_string_datatype_value_test() {
  let metric =
    "{\"name\": \"My Metric\",\"alias\": 1,\"timestamp\": 1479123452194,\"dataType\": \"String\",\"value\": \"This is a test string.\"}"

  sparkleplug.string_to_metric(metric)
  |> should.be_ok
}

pub fn successful_decode_metric_int_datatype_value_test() {
  let metric =
    "{\"name\": \"My Metric\",\"alias\": 1,\"timestamp\": 1479123452194,\"dataType\": 12,\"value\": \"This is a test string.\"}"

  sparkleplug.string_to_metric(metric)
  |> should.be_ok
}

pub fn incorrect_data_type_decode_metric_test() {
  let metric =
    "{\"name\": \"My Metric\",\"alias\": 1,\"timestamp\": 1479123452194,\"dataType\": \"Int\",\"value\": \"This is a test string\"}"

  sparkleplug.string_to_metric(metric)
  |> should.be_error
}

pub fn decode_simple_payload_string_test() {
  let payload =
    "{\"timestamp\": 1486144502122,\"metrics\": [{\"name\": \"My Metric\",\"alias\": 1,\"timestamp\": 1479123452194,\"dataType\": \"String\",\"value\": \"Test\"}],\"seq\": 2}"

  sparkleplug.string_to_sparkplug_payload(payload)
  |> should.be_ok
}

pub fn decode_fail_test() {
  let payload = "{}"

  sparkleplug.string_to_sparkplug_payload(payload)
  |> should.be_error
}
