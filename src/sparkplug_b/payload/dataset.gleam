import gleam/option.{type Option}

pub type DataSet {
  DataSet(
    num_of_columns: Option(Int),
    columns: List(String),
    types: List(Int),
    rows: List(Row),
  )
}

pub type Row {
  Row(elements: List(DataSetValue))
}

pub type DataSetValue {
  DataSetValue(value: Option(Value))
}

pub type Value {
  IntValue(Int)
  LongValue(Int)
  FloatValue(Float)
  DoubleValue(Float)
  BooleanValue(Bool)
  StringValue(String)
  ExtensionValue(DataSetValueExtension)
}

pub type DataSetValueExtension
