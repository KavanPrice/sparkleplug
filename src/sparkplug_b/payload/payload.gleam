import gleam/option.{type Option}
import sparkplug_b/payload/metric.{type Metric}

pub type Payload {
  Payload(
    timestamp: Option(Int),
    metrics: List(Metric),
    seq: Option(Int),
    uuid: Option(String),
    body: Option(BitArray),
  )
}
