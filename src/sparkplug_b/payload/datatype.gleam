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

pub type DataTypeParseError {
  DataTypeParseError(message: String)
}
