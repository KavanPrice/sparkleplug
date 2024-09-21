import gleam/option.{type Option}

pub type PropertySet {
  PropertySet(keys: List(String), values: List(PropertyValue))
}

pub type PropertyValue {
  PropertyValue(type_: Option(Int), is_null: Option(Bool), value: Option(Value))
}

pub type Value {
  IntValue(Int)
  LongValue(Int)
  FloatValue(Float)
  DoubleValue(Float)
  BooleanValue(Bool)
  StringValue(String)
  PropertysetValue(PropertySet)
  PropertysetsValue(PropertySetList)
  ExtensionValue(PropertyValueExtension)
}

pub type PropertySetList {
  PropertySetList(propertyset: List(PropertySet))
}

pub type PropertyValueExtension
