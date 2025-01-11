import gleam/dynamic
import gleam/option.{type Option, Some}
import gleam/result

pub type DataTypeValue {
  DataTypeValue(Option(Int))
}

type DataTypeStringValue {
  DataTypeStringValue(Option(String))
}

pub type DataType {
  Unknown
  Int8
  Int16
  Int32
  Int64
  UInt8
  UInt16
  UInt32
  UInt64
  Float
  Double
  Boolean
  String
  DateTime
  Text
  UUID
  DataSet
  Bytes
  File
  Template
  PropertySet
  PropertySetList
  Int8Array
  Int16Array
  Int32Array
  Int64Array
  UInt8Array
  UInt16Array
  UInt32Array
  UInt64Array
  FloatArray
  DoubleArray
  BooleanArray
  StringArray
  DateTimeArray
}

pub fn to_int(data_type: DataType) -> Int {
  case data_type {
    Unknown -> 0
    Int8 -> 1
    Int16 -> 2
    Int32 -> 3
    Int64 -> 4
    UInt8 -> 5
    UInt16 -> 6
    UInt32 -> 7
    UInt64 -> 8
    Float -> 9
    Double -> 10
    Boolean -> 11
    String -> 12
    DateTime -> 13
    Text -> 14
    UUID -> 15
    DataSet -> 16
    Bytes -> 17
    File -> 18
    Template -> 19
    PropertySet -> 20
    PropertySetList -> 21
    Int8Array -> 22
    Int16Array -> 23
    Int32Array -> 24
    Int64Array -> 25
    UInt8Array -> 26
    UInt16Array -> 27
    UInt32Array -> 28
    UInt64Array -> 29
    FloatArray -> 30
    DoubleArray -> 31
    BooleanArray -> 32
    StringArray -> 33
    DateTimeArray -> 34
  }
}

pub fn from_int(int: Int) -> Result(DataType, DataTypeParseError) {
  case int {
    0 -> Ok(Unknown)
    1 -> Ok(Int8)
    2 -> Ok(Int16)
    3 -> Ok(Int32)
    4 -> Ok(Int64)
    5 -> Ok(UInt8)
    6 -> Ok(UInt16)
    7 -> Ok(UInt32)
    8 -> Ok(UInt64)
    9 -> Ok(Float)
    10 -> Ok(Double)
    11 -> Ok(Boolean)
    12 -> Ok(String)
    13 -> Ok(DateTime)
    14 -> Ok(Text)
    15 -> Ok(UUID)
    16 -> Ok(DataSet)
    17 -> Ok(Bytes)
    18 -> Ok(File)
    19 -> Ok(Template)
    20 -> Ok(PropertySet)
    21 -> Ok(PropertySetList)
    22 -> Ok(Int8Array)
    23 -> Ok(Int16Array)
    24 -> Ok(Int32Array)
    25 -> Ok(Int64Array)
    26 -> Ok(UInt8Array)
    27 -> Ok(UInt16Array)
    28 -> Ok(UInt32Array)
    29 -> Ok(UInt64Array)
    30 -> Ok(FloatArray)
    31 -> Ok(DoubleArray)
    32 -> Ok(BooleanArray)
    33 -> Ok(StringArray)
    34 -> Ok(DateTimeArray)
    _ ->
      Error(DataTypeParseError(
        "No data type corresponding to the given Int value.",
      ))
  }
}

pub fn to_string(data_type: DataType) -> String {
  case data_type {
    Unknown -> "Unknown"
    Int8 -> "Int8"
    Int16 -> "Int16"
    Int32 -> "Int32"
    Int64 -> "Int64"
    UInt8 -> "UInt8"
    UInt16 -> "UInt16"
    UInt32 -> "UInt32"
    UInt64 -> "UInt64"
    Float -> "Float"
    Double -> "Double"
    Boolean -> "Boolean"
    String -> "String"
    DateTime -> "DateTime"
    Text -> "Text"
    UUID -> "UUID"
    DataSet -> "DataSet"
    Bytes -> "Bytes"
    File -> "File"
    Template -> "Template"
    PropertySet -> "PropertySet"
    PropertySetList -> "PropertySetList"
    Int8Array -> "Int8Array"
    Int16Array -> "Int16Array"
    Int32Array -> "Int32Array"
    Int64Array -> "Int64Array"
    UInt8Array -> "UInt8Array"
    UInt16Array -> "UInt16Array"
    UInt32Array -> "UInt32Array"
    UInt64Array -> "UInt64Array"
    FloatArray -> "FloatArray"
    DoubleArray -> "DoubleArray"
    BooleanArray -> "BooleanArray"
    StringArray -> "StringArray"
    DateTimeArray -> "DateTimeArray"
  }
}

pub fn from_string(string: String) -> Result(DataType, DataTypeParseError) {
  case string {
    "Unknown" -> Ok(Unknown)
    "Int8" -> Ok(Int8)
    "Int16" -> Ok(Int16)
    "Int32" -> Ok(Int32)
    "Int64" -> Ok(Int64)
    "UInt8" -> Ok(UInt8)
    "UInt16" -> Ok(UInt16)
    "UInt32" -> Ok(UInt32)
    "UInt64" -> Ok(UInt64)
    "Float" -> Ok(Float)
    "Double" -> Ok(Double)
    "Boolean" -> Ok(Boolean)
    "String" -> Ok(String)
    "DateTime" -> Ok(DateTime)
    "Text" -> Ok(Text)
    "UUID" -> Ok(UUID)
    "DataSet" -> Ok(DataSet)
    "Bytes" -> Ok(Bytes)
    "File" -> Ok(File)
    "Template" -> Ok(Template)
    "PropertySet" -> Ok(PropertySet)
    "PropertySetList" -> Ok(PropertySetList)
    "Int8Array" -> Ok(Int8Array)
    "Int16Array" -> Ok(Int16Array)
    "Int32Array" -> Ok(Int32Array)
    "Int64Array" -> Ok(Int64Array)
    "UInt8Array" -> Ok(UInt8Array)
    "UInt16Array" -> Ok(UInt16Array)
    "UInt32Array" -> Ok(UInt32Array)
    "UInt64Array" -> Ok(UInt64Array)
    "FloatArray" -> Ok(FloatArray)
    "DoubleArray" -> Ok(DoubleArray)
    "BooleanArray" -> Ok(BooleanArray)
    "StringArray" -> Ok(StringArray)
    "DateTimeArray" -> Ok(DateTimeArray)
    _ ->
      Error(DataTypeParseError(
        "No data type corresponding to the given String value.",
      ))
  }
}

pub fn decode_datatype_value(
  data: dynamic.Dynamic,
) -> Result(DataTypeValue, dynamic.DecodeErrors) {
  let maybe_string_value =
    data
    |> dynamic.decode1(
      DataTypeStringValue,
      dynamic.optional_field("dataType", dynamic.string),
    )

  case maybe_string_value {
    Ok(string_val) -> {
      convert_datatype_value(string_val)
      |> result.map_error(fn(_) {
        [dynamic.DecodeError(expected: "", found: "", path: [])]
      })
    }
    Error(_) -> {
      data
      |> dynamic.decode1(
        DataTypeValue,
        dynamic.optional_field("dataType", dynamic.int),
      )
    }
  }
}

fn convert_datatype_value(
  data_type_string_value: DataTypeStringValue,
) -> Result(DataTypeValue, DataTypeParseError) {
  let DataTypeStringValue(maybe_string) = data_type_string_value

  option.map(maybe_string, fn(string_value) {
    from_string(string_value) |> result.map(to_int)
  })
  |> option.to_result(DataTypeParseError(
    "Couldn't convert String value to Int datatype representation.",
  ))
  |> result.flatten
  |> result.map(fn(int_val) { DataTypeValue(Some(int_val)) })
}

pub type DataTypeParseError {
  DataTypeParseError(message: String)
}
