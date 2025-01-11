import gleam/option.{type Option}
import sparkleplug/sparkplug_b/payload/metric.{type Metric}

pub type Payload {
  Payload(
    timestamp: Option(Int),
    metrics: List(Metric),
    seq: Option(Int),
    uuid: Option(String),
    body: Option(String),
  )
}
