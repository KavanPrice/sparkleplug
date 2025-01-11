import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import sparkleplug
import sparkplug_b/payload/metric
import sparkplug_b/payload/payload

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
    "{\"name\": \"My Metric\",\"alias\": 1,\"timestamp\": 1479123452194,\"dataType\": \"Float\",\"value\": \"This is a test string\"}"

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

pub fn successful_encode_metric_test() {
  let metric =
    metric.Metric(
      name: Some("My Metric"),
      alias: Some(1),
      timestamp: Some(123),
      datatype: Some(17),
      is_historical: None,
      is_transient: None,
      is_null: Some(False),
      metadata: None,
      value: Some(metric.StringValue("Test value")),
    )

  sparkleplug.metric_to_json_string(metric)
  |> should.equal(
    "{\"name\":\"My Metric\",\"alias\":1,\"timestamp\":123,\"dataType\":17,\"is_historical\":false,\"is_transient\":false,\"is_null\":false,\"metadata\":\"\",\"value\":\"Test value\"}",
  )
}

pub fn successful_encode_decode_metric_test() {
  let metric =
    metric.Metric(
      name: Some("My Metric"),
      alias: Some(1),
      timestamp: Some(123),
      datatype: Some(12),
      is_historical: Some(False),
      is_transient: Some(False),
      is_null: Some(False),
      metadata: Some(""),
      value: Some(metric.StringValue("Test value")),
    )

  sparkleplug.metric_to_json_string(metric)
  |> sparkleplug.string_to_metric
  |> should.equal(Ok(metric))
}

pub fn successful_encode_payload_test() {
  let metric =
    metric.Metric(
      name: Some("My Metric"),
      alias: Some(1),
      timestamp: Some(123),
      datatype: Some(17),
      is_historical: None,
      is_transient: None,
      is_null: Some(False),
      metadata: None,
      value: Some(metric.StringValue("Test value")),
    )
  let payload =
    payload.Payload(
      timestamp: Some(456),
      metrics: [metric],
      seq: Some(0),
      uuid: None,
      body: None,
    )

  sparkleplug.sparkplug_payload_to_json_string(payload)
  |> should.equal(
    "{\"timestamp\":456,\"metrics\":[{\"name\":\"My Metric\",\"alias\":1,\"timestamp\":123,\"dataType\":17,\"is_historical\":false,\"is_transient\":false,\"is_null\":false,\"metadata\":\"\",\"value\":\"Test value\"}],\"seq\":0,\"uuid\":\"\",\"body\":\"\"}",
  )
}

pub fn successful_encode_decode_payload_test() {
  let metric =
    metric.Metric(
      name: Some("My Metric"),
      alias: Some(1),
      timestamp: Some(123),
      datatype: Some(12),
      is_historical: Some(False),
      is_transient: Some(False),
      is_null: Some(False),
      metadata: Some(""),
      value: Some(metric.StringValue("Test value")),
    )
  let payload =
    payload.Payload(
      timestamp: Some(456),
      metrics: [metric],
      seq: Some(0),
      uuid: Some(""),
      body: Some(""),
    )

  sparkleplug.sparkplug_payload_to_json_string(payload)
  |> sparkleplug.string_to_sparkplug_payload
  |> should.equal(Ok(payload))
}
