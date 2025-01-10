import gleam/bit_array
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/result
import sparkplug_b/payload/dataset
import sparkplug_b/payload/datatype
import sparkplug_b/payload/metric
import sparkplug_b/payload/payload
import sparkplug_b/payload/propertyset

/// Attempts to convert a bit array representation of a Sparkplug B payload into a Payload type.
///
/// Returns an error if the bit array doesn't hold a valid representation.
pub fn bit_array_to_sparkplug_payload(
  payload_bit_array: BitArray,
) -> Result(payload.Payload, String) {
  bit_array.to_string(payload_bit_array)
  |> result.map_error(fn(_) { "Couldn't convert the bit array into a string." })
  |> result.try(string_to_sparkplug_payload)
}

/// Attempts to convert a string representation of a Sparkplug B payload into a Payload type.
///
/// Returns an error if the string doesn't hold a valid representation.
pub fn string_to_sparkplug_payload(
  payload_string: String,
) -> Result(payload.Payload, String) {
  json_to_sparkplug_payload(payload_string)
  |> result.map_error(fn(error_val) {
    case error_val {
      json.UnexpectedEndOfInput -> "Unexpected end of input"
      json.UnexpectedByte(message) -> "Unexpected byte: " <> message
      json.UnexpectedFormat(inner_errors) -> {
        let maybe_first_error = list.first(inner_errors)
        case maybe_first_error {
          Ok(error) ->
            "Unexpected format: Expected "
            <> error.expected
            <> "; found "
            <> error.found
          Error(_) -> "Unexpected format: No inner errors"
        }
      }
      json.UnexpectedSequence(message) -> "Unexpected sequence: " <> message
    }
  })
}

/// Attempts to convert a string representation of a Sparkplug B metric into a Metric type.
///
/// Returns an error if the string doesn't hold a valid representation.
pub fn string_to_metric(
  metric_string: String,
) -> Result(metric.Metric, json.DecodeError) {
  json.decode(metric_string, metric)
}

fn json_to_sparkplug_payload(
  json_string: String,
) -> Result(payload.Payload, json.DecodeError) {
  let sparkplug_decoder =
    dynamic.decode5(
      payload.Payload,
      dynamic.optional_field("timestamp", dynamic.int),
      dynamic.field("metrics", dynamic.list(metric)),
      dynamic.optional_field("seq", dynamic.int),
      dynamic.optional_field("uuid", dynamic.string),
      dynamic.optional_field("body", dynamic.bit_array),
    )

  json.decode(json_string, sparkplug_decoder)
}

fn metric(data: dynamic.Dynamic) -> Result(metric.Metric, dynamic.DecodeErrors) {
  let metric_datatype = {
    case dynamic.field("dataType", dynamic.string)(data) {
      Ok(str) -> {
        datatype.from_string(str)
        |> result.unwrap(datatype.Bytes)
      }
      Error(_) ->
        dynamic.field("dataType", dynamic.int)(data)
        |> result.unwrap(17)
        |> datatype.from_int
        |> result.unwrap(datatype.Bytes)
    }
  }

  dynamic.decode9(
    metric.Metric,
    dynamic.optional_field("name", dynamic.string),
    dynamic.optional_field("alias", dynamic.int),
    dynamic.optional_field("timestamp", dynamic.int),
    dynamic.optional_field("dataType", fn(data) {
      case dynamic.string(data) {
        Ok(str) -> {
          Ok(
            datatype.from_string(str)
            |> result.map(datatype.to_int)
            |> result.unwrap(17),
          )
        }
        Error(_) -> dynamic.int(data)
      }
    }),
    dynamic.optional_field("is_historical", dynamic.bool),
    dynamic.optional_field("is_transient", dynamic.bool),
    dynamic.optional_field("is_null", dynamic.bool),
    dynamic.optional_field("metadata", dynamic.bit_array),
    dynamic.optional_field("value", fn(data) -> Result(
      metric.Value,
      dynamic.DecodeErrors,
    ) {
      value(data, metric_datatype)
    }),
  )(data)
}

fn value(
  data: dynamic.Dynamic,
  data_type: datatype.DataType,
) -> Result(metric.Value, dynamic.DecodeErrors) {
  case data_type {
    datatype.Unknown -> dynamic.bit_array(data) |> result.map(metric.BytesValue)
    datatype.Int8
    | datatype.Int16
    | datatype.Int32
    | datatype.Int64
    | datatype.UInt8
    | datatype.UInt16
    | datatype.UInt32
    | datatype.UInt64 -> dynamic.int(data) |> result.map(metric.IntValue)
    datatype.Float | datatype.Double ->
      dynamic.float(data) |> result.map(metric.FloatValue)
    datatype.Boolean -> dynamic.bool(data) |> result.map(metric.BooleanValue)
    datatype.String -> dynamic.string(data) |> result.map(metric.StringValue)
    datatype.DateTime -> dynamic.int(data) |> result.map(metric.IntValue)
    datatype.Text -> dynamic.string(data) |> result.map(metric.StringValue)
    datatype.UUID -> dynamic.string(data) |> result.map(metric.StringValue)
    datatype.DataSet -> data_set(data) |> result.map(metric.DatasetValue)
    datatype.Bytes | datatype.File ->
      dynamic.bit_array(data) |> result.map(metric.BytesValue)
    datatype.Template -> template(data) |> result.map(metric.TemplateValue)
    datatype.PropertySet ->
      property_set(data) |> result.map(metric.PropertySetValue)
    datatype.PropertySetList ->
      property_set_list(data) |> result.map(metric.PropertySetListValue)
    datatype.Int8Array
    | datatype.Int16Array
    | datatype.Int32Array
    | datatype.Int64Array
    | datatype.UInt8Array
    | datatype.UInt16Array
    | datatype.UInt32Array
    | datatype.UInt64Array
    | datatype.FloatArray
    | datatype.DoubleArray
    | datatype.BooleanArray
    | datatype.StringArray
    | datatype.DateTimeArray ->
      dynamic.bit_array(data) |> result.map(metric.BytesValue)
  }
}

fn data_set(
  data: dynamic.Dynamic,
) -> Result(dataset.DataSet, dynamic.DecodeErrors) {
  todo
}

fn template(
  data: dynamic.Dynamic,
) -> Result(metric.Template, dynamic.DecodeErrors) {
  todo
}

fn property_set(
  data: dynamic.Dynamic,
) -> Result(propertyset.PropertySet, dynamic.DecodeErrors) {
  todo
}

fn property_set_list(
  data: dynamic.Dynamic,
) -> Result(propertyset.PropertySetList, dynamic.DecodeErrors) {
  todo
}
