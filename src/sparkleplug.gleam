import gleam/bit_array
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import sparkleplug/sparkplug_b/payload/dataset
import sparkleplug/sparkplug_b/payload/datatype
import sparkleplug/sparkplug_b/payload/metric
import sparkleplug/sparkplug_b/payload/payload
import sparkleplug/sparkplug_b/payload/propertyset

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
        case list.first(inner_errors) {
          Ok(error) ->
            "Unexpected format: Expected "
            <> error.expected
            <> "; found "
            <> error.found
          Error(_) -> "Unexpected format: No inner errors"
        }
      }
      json.UnexpectedSequence(message) -> "Unexpected sequence: " <> message
      json.UnableToDecode(inner_errors) -> {
        case list.first(inner_errors) {
          Ok(error) ->
            "Unable to decode: Expected "
            <> error.expected
            <> "; found "
            <> error.found
          Error(_) -> "Unable to decode. No inner errors"
        }
      }
    }
  })
}

/// Attempts to convert a string representation of a Sparkplug B metric into a Metric type.
///
/// Returns an error if the string doesn't hold a valid representation.
pub fn string_to_metric(
  metric_string: String,
) -> Result(metric.Metric, json.DecodeError) {
  json.parse(metric_string, metric_decoder())
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
  let sparkplug_decoder = {
    use maybe_timestamp <- decode.optional_field("timestamp", None, decode.optional(decode.int))
    use metrics <- decode.field("metrics", decode.list(metric_decoder()))
    use maybe_seq <- decode.optional_field("seq", None, decode.optional(decode.int))
    use maybe_uuid <- decode.optional_field("uuid", None, decode.optional(decode.string))
    use maybe_body <- decode.optional_field("body", None, decode.optional(decode.string))
    decode.success(payload.Payload(maybe_timestamp, metrics, maybe_seq, maybe_uuid, maybe_body))
  }

  json.parse(json_string, sparkplug_decoder)
}

fn metric_decoder() -> decode.Decoder(metric.Metric) {
  use maybe_name <- decode.optional_field("name", None, decode.optional(decode.string))
  use maybe_alias <- decode.optional_field("alias", None, decode.optional(decode.int))
  use maybe_timestamp <- decode.optional_field("timestamp", None, decode.optional(decode.int))
  use datatype <- decode.optional_field("dataType", datatype.Bytes, datatype_decoder())
  use maybe_is_historical <- decode.optional_field("is_historical", None, decode.optional(decode.bool))
  use maybe_is_transient <- decode.optional_field("is_transient", None, decode.optional(decode.bool))
  use maybe_is_null <- decode.optional_field("is_null", None, decode.optional(decode.bool))
  use maybe_metadata <- decode.optional_field("metadata", None, decode.optional(decode.string))
  use maybe_value <- decode.field("value", decode.optional(value_decoder(datatype)))
  decode.success(metric.Metric(maybe_name, maybe_alias, maybe_timestamp, Some(datatype |> datatype.to_int), maybe_is_historical, maybe_is_transient, maybe_is_null, maybe_metadata, maybe_value))
}

fn datatype_decoder() -> decode.Decoder(datatype.DataType) {
  decode.one_of(decode.int |> decode.map(datatype.from_int), or: [decode.string |> decode.map(datatype.from_string)])
  |> decode.map(fn(result) {
    case result {
      Ok(datatype) -> datatype
      Error(_) -> datatype.Bytes
    }
  })

}

fn value_decoder(datatype: datatype.DataType) -> decode.Decoder(metric.Value) {
  case datatype {
  datatype.Unknown -> decode.bit_array |> decode.map(metric.BytesValue)
  datatype.Int8
 | datatype.Int16
 | datatype.Int32
 | datatype.Int64
 | datatype.UInt8
 | datatype.UInt16
 | datatype.UInt32
 | datatype.UInt64 -> decode.int |> decode.map(metric.IntValue)
 datatype.Float | datatype.Double ->
   decode.float |> decode.map(metric.FloatValue)
 datatype.Boolean -> decode.bool |> decode.map(metric.BooleanValue)
 datatype.String -> decode.string |> decode.map(metric.StringValue)
 datatype.DateTime -> decode.int |> decode.map(metric.IntValue)
 datatype.Text -> decode.string |> decode.map(metric.StringValue)
 datatype.UUID -> decode.string |> decode.map(metric.StringValue)
 datatype.DataSet -> data_set_decoder() |> decode.map(metric.DatasetValue)
 datatype.Bytes | datatype.File ->
   decode.bit_array |> decode.map(metric.BytesValue)
 datatype.Template -> template_decoder() |> decode.map(metric.TemplateValue)
 datatype.PropertySet ->
   property_set_decoder() |> decode.map(metric.PropertySetValue)
 datatype.PropertySetList ->
   property_set_list_decoder() |> decode.map(metric.PropertySetListValue)
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
   decode.bit_array |> decode.map(metric.BytesValue)
  }
}

fn data_set_decoder() -> decode.Decoder(dataset.DataSet) {
  use maybe_num_of_columns <- decode.field("num_of_columns", decode.optional(decode.int))
  use columns <- decode.field("columns", decode.list(decode.string))
  use types <- decode.field("types", decode.list(decode.int))
  use rows <- decode.field("rows", decode.list(row_decoder()))
  decode.success(dataset.DataSet(maybe_num_of_columns, columns, types, rows))
}

fn row_decoder() -> decode.Decoder(dataset.Row) {
  use row <- decode.field("elements", decode.list(data_set_value_decoder()))
  decode.success(dataset.Row(row))
}


fn data_set_value_decoder() -> decode.Decoder(dataset.DataSetValue) {
  use maybe_data_set_value <- decode.field("value", decode.optional(data_value_decoder()))
  decode.success(dataset.DataSetValue(maybe_data_set_value))
}

fn data_value_decoder() -> decode.Decoder(dataset.Value) {
  decode.one_of(decode.int |> decode.map(dataset.IntValue),
    [
      decode.float |> decode.map(dataset.FloatValue),
      decode.bool |> decode.map(dataset.BooleanValue),
      decode.string |> decode.map(dataset.StringValue),
    ])
}

fn template_decoder() -> decode.Decoder(metric.Template) {
  use maybe_version <- decode.field("version", decode.optional(decode.string))
  use metrics <- decode.field("metrics", decode.list(metric_decoder()))
  use parameters <- decode.field("parameters", decode.list(parameter_decoder()))
  use maybe_template_ref <- decode.field("template_ref", decode.optional(decode.string))
  use maybe_is_definition <- decode.field("is_definition", decode.optional(decode.bool))
  decode.success(metric.Template(maybe_version, metrics, parameters, maybe_template_ref, maybe_is_definition))
}

fn parameter_decoder() -> decode.Decoder(metric.Parameter) {
  use maybe_name <- decode.field("name", decode.optional(decode.string))
  use maybe_type <- decode.field("type", decode.optional(decode.string))
  use maybe_value <- decode.field("value", decode.optional(decode.string))
  decode.success(metric.Parameter(maybe_name, maybe_type, maybe_value))
}

fn property_set_decoder() -> decode.Decoder(propertyset.PropertySet) {
  use keys <- decode.field("keys", decode.list(decode.string))
  use values <- decode.field("values", decode.list(property_value_decoder()))
  decode.success(propertyset.PropertySet(keys, values))
}

fn property_value_decoder() -> decode.Decoder(propertyset.PropertyValue) {
  use maybe_type <- decode.field("type", decode.optional(decode.int))
  use maybe_is_null <- decode.field("is_null", decode.optional(decode.bool))
  use maybe_value <- decode.field("value", decode.optional(decode.one_of(decode.int |> decode.map(propertyset.IntValue), [decode.float |> decode.map(propertyset.FloatValue), decode.bool |> decode.map(propertyset.BooleanValue), decode.string |> decode.map(propertyset.StringValue)])))
  decode.success(propertyset.PropertyValue(maybe_type, maybe_is_null, maybe_value))
}

fn property_set_list_decoder() -> decode.Decoder(propertyset.PropertySetList) {
  use property_set_list <- decode.field("propertyset", decode.list(property_set_decoder()))
  decode.success(propertyset.PropertySetList(property_set_list))
}

fn encode_data_set(dataset: dataset.DataSet) -> json.Json {
  json.object([
    #("num_of_columns", json.nullable(dataset.num_of_columns, json.int)),
    #("columns", json.array(dataset.columns, of: json.string)),
    #("types", json.array(dataset.types, of: json.int)),
    #("rows", json.array(dataset.rows, of: encode_row)),
  ])
}

fn encode_row(row: dataset.Row) -> json.Json {
  json.object([
    #("elements", json.array(row.elements, of: encode_data_set_value)),
  ])
}

fn encode_data_set_value(data_set_value: dataset.DataSetValue) -> json.Json {
  json.object([
    #("value", json.nullable(data_set_value.value, encode_data_set_val)),
  ])
}

fn encode_data_set_val(value: dataset.Value) -> json.Json {
  case value {
    dataset.IntValue(val) -> json.int(val)
    dataset.LongValue(val) -> json.int(val)
    dataset.FloatValue(val) -> json.float(val)
    dataset.DoubleValue(val) -> json.float(val)
    dataset.BooleanValue(val) -> json.bool(val)
    dataset.StringValue(val) | dataset.ExtensionValue(val) -> json.string(val)
  }
}

fn encode_template(template: metric.Template) -> json.Json {
  json.object([
    #("version", json.nullable(template.version, json.string)),
    #("metrics", json.array(template.metrics, of: metric_to_json)),
    #("parameters", json.array(template.parameters, of: encode_parameter)),
    #("template_ref", json.nullable(template.template_ref, json.string)),
    #("is_definition", json.nullable(template.is_definition, json.bool)),
  ])
}

fn encode_parameter(parameter: metric.Parameter) -> json.Json {
  json.object([
    #("name", json.nullable(parameter.name, json.string)),
    #("type", json.nullable(parameter.type_, json.string)),
    #("value", json.nullable(parameter.value, json.string)),
  ])
}

fn encode_extension(extension: metric.MetricValueExtension) -> json.Json {
  json.object([#("value", json.string(extension.value))])
}

fn encode_property_set(property_set: propertyset.PropertySet) -> json.Json {
  json.object([
    #("keys", json.array(property_set.keys, of: json.string)),
    #("values", json.array(property_set.values, of: encode_property_value)),
  ])
}

fn encode_property_value(property_value: propertyset.PropertyValue) -> json.Json {
  json.object([
    #("type", json.nullable(property_value.type_, json.int)),
    #("is_null", json.nullable(property_value.is_null, json.bool)),
    #("value", json.nullable(property_value.value, encode_prop_val)),
  ])
}

fn encode_prop_val(prop_val: propertyset.Value) -> json.Json {
  case prop_val {
    propertyset.IntValue(val) -> json.int(val)
    propertyset.LongValue(val) -> json.int(val)
    propertyset.FloatValue(val) -> json.float(val)
    propertyset.DoubleValue(val) -> json.float(val)
    propertyset.BooleanValue(val) -> json.bool(val)
    propertyset.StringValue(val) -> json.string(val)
    propertyset.PropertysetValue(val) -> encode_property_set(val)
    propertyset.PropertysetsValue(val) -> encode_property_set_list(val)
    propertyset.ExtensionValue(val) -> json.string(val)
  }
}

fn encode_property_set_list(
  property_set_list: propertyset.PropertySetList,
) -> json.Json {
  json.object([
    #(
      "propertyset",
      json.array(property_set_list.propertyset, encode_property_set),
    ),
  ])
}
