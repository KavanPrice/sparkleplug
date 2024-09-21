import gleam/option.{type Option}
import sparkplug_b/payload/dataset.{type DataSet}
import sparkplug_b/payload/propertyset.{type PropertySet}

pub type Metric {
  Metric(
    name: Option(String),
    alias: Option(Int),
    timestamp: Option(Int),
    datatype: Option(Int),
    is_historical: Option(Bool),
    is_transient: Option(Bool),
    is_null: Option(Bool),
    metadata: Option(BitArray),
    properties: Option(PropertySet),
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
}

pub type MetricValueExtension

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
