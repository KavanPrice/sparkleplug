import gleam/bit_array
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{None, Some}
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

/// Serialise a Payload into a JSON string.
pub fn sparkplug_payload_to_json_string(payload: payload.Payload) -> String {
  // If a None value is present in `uuid` or `body`, then we want to set the
  // JSON value to be an empty string.
  let encode_nullable_string = fn(
    nullable_bitarray_field: option.Option(String),
  ) -> json.Json {
    case nullable_bitarray_field {
      Some(val) -> val |> json.string
      None -> "" |> json.string
    }
  }

  json.object([
    #("timestamp", json.nullable(payload.timestamp, json.int)),
    #("metrics", json.array(payload.metrics, metric_to_json)),
    #("seq", json.nullable(payload.seq, json.int)),
    #("uuid", encode_nullable_string(payload.uuid)),
    #("body", encode_nullable_string(payload.body)),
  ])
  |> json.to_string
}

/// Serialise a Metric into a JSON string.
pub fn metric_to_json_string(metric: metric.Metric) -> String {
  metric_to_json(metric)
  |> json.to_string
}

fn metric_to_json(metric: metric.Metric) -> json.Json {
  // If a None value is present in `is_historical`, `is_transient`, or
  // `is_null`, then we want to set the JSON value to False. This is for
  // consistency in encoding and decoding representations.
  let encode_nullable_bool = fn(nullable_bool_field: option.Option(Bool)) -> json.Json {
    case nullable_bool_field {
      Some(val) -> json.bool(val)
      None -> json.bool(False)
    }
  }

  // If a None value is present in `metadata`, then we want to set the JSON
  // value to be an empty string.
  let encode_nullable_string = fn(
    nullable_bitarray_field: option.Option(String),
  ) -> json.Json {
    case nullable_bitarray_field {
      Some(val) -> val |> json.string
      None -> "" |> json.string
    }
  }

  json.object([
    #("name", json.nullable(metric.name, json.string)),
    #("alias", json.nullable(metric.alias, json.int)),
    #("timestamp", json.nullable(metric.timestamp, json.int)),
    #("dataType", json.nullable(metric.datatype, json.int)),
    #("is_historical", encode_nullable_bool(metric.is_historical)),
    #("is_transient", encode_nullable_bool(metric.is_transient)),
    #("is_null", encode_nullable_bool(metric.is_null)),
    #("metadata", encode_nullable_string(metric.metadata)),
    #("value", json.nullable(metric.value, value_to_json)),
  ])
}

fn value_to_json(value: metric.Value) -> json.Json {
  case value {
    metric.IntValue(val) -> json.int(val)
    metric.LongValue(val) -> json.int(val)
    metric.FloatValue(val) -> json.float(val)
    metric.DoubleValue(val) -> json.float(val)
    metric.BooleanValue(val) -> json.bool(val)
    metric.StringValue(val) -> json.string(val)
    metric.BytesValue(val) -> bit_array.base64_encode(val, True) |> json.string
    metric.DatasetValue(val) -> encode_data_set(val)
    metric.TemplateValue(val) -> encode_template(val)
    metric.ExtensionValue(val) -> encode_extension(val)
    metric.PropertySetValue(val) -> encode_property_set(val)
    metric.PropertySetListValue(val) -> encode_property_set_list(val)
  }
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
      dynamic.optional_field("body", dynamic.string),
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
    dynamic.optional_field("metadata", dynamic.string),
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

fn encode_data_set(dataset: dataset.DataSet) -> json.Json {
  todo
}

fn encode_template(template: metric.Template) -> json.Json {
  todo
}

fn encode_extension(extension: metric.MetricValueExtension) -> json.Json {
  todo
}

fn encode_property_set(property_set: propertyset.PropertySet) -> json.Json {
  todo
}

fn encode_property_set_list(
  property_set_list: propertyset.PropertySetList,
) -> json.Json {
  todo
}
