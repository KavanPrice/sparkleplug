import gleam/option.{type Option}
import sparkleplug/sparkplug_b/payload/dataset.{type DataSet}
import sparkleplug/sparkplug_b/payload/propertyset

pub type Metric {
  Metric(
    name: Option(String),
    alias: Option(Int),
    timestamp: Option(Int),
    datatype: Option(Int),
    is_historical: Option(Bool),
    is_transient: Option(Bool),
    is_null: Option(Bool),
    metadata: Option(String),
    value: Option(Value),
  )
}

pub type Value {
  IntValue(Int)
  LongValue(Int)
  FloatValue(Float)
  DoubleValue(Float)
  BooleanValue(Bool)
  StringValue(String)
  BytesValue(BitArray)
  DatasetValue(DataSet)
  TemplateValue(Template)
  ExtensionValue(MetricValueExtension)
  PropertySetValue(propertyset.PropertySet)
  PropertySetListValue(propertyset.PropertySetList)
}

pub type MetricValueExtension {
  MetricValueExtension(value: String)
}

pub type Template {
  Template(
    version: Option(String),
    metrics: List(Metric),
    parameters: List(Parameter),
    template_ref: Option(String),
    is_definition: Option(Bool),
  )
}

pub type Parameter {
  Parameter(name: Option(String), type_: Option(String), value: Option(String))
}
