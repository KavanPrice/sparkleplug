import gleam/result
import gleam/string
import sparkplug_b/device_message_types.{type DeviceMessageType}
import sparkplug_b/node_message_types.{type NodeMessageType}
import sparkplug_b/topic_namespace.{type TopicNamespace}

pub type TopicName {
  NodeMessage(
    namespace: TopicNamespace,
    group_id: String,
    message_type: NodeMessageType,
    node_id: String,
  )

  DeviceMessage(
    namespace: TopicNamespace,
    group_id: String,
    message_type: DeviceMessageType,
    node_id: String,
    device_id: String,
  )

  StateMessage(scada_host_id: String)
}

pub fn from_string(
  topic_string: String,
) -> Result(TopicName, TopicNameParseError) {
  case string.split(topic_string, "/") {
    [namespace_string, group_id, message_type_string, node_id, device_id] -> {
      use namespace <- result.try(
        topic_namespace.from_string(namespace_string)
        |> result.map_error(fn(err) {
          TopicNameParseError("Couldn't parse topic name: " <> err.message)
        }),
      )
      use message_type <- result.try(
        device_message_types.from_string(message_type_string)
        |> result.map_error(fn(err) {
          TopicNameParseError("Couldn't parse topic name: " <> err.message)
        }),
      )
      Ok(DeviceMessage(namespace, group_id, message_type, node_id, device_id))
    }
    [namespace_string, group_id, message_type_string, node_id] -> {
      use namespace <- result.try(
        topic_namespace.from_string(namespace_string)
        |> result.map_error(fn(err) {
          TopicNameParseError("Couldn't parse topic name: " <> err.message)
        }),
      )
      use message_type <- result.try(
        node_message_types.from_string(message_type_string)
        |> result.map_error(fn(err) {
          TopicNameParseError("Couldn't parse topic name: " <> err.message)
        }),
      )
      Ok(NodeMessage(namespace, group_id, message_type, node_id))
    }
    ["STATE", scada_host_id] -> Ok(StateMessage(scada_host_id))
    _ ->
      Error(TopicNameParseError("Couldn't parse topic name from given string."))
  }
}

pub fn to_string(topic_name: TopicName) -> String {
  case topic_name {
    NodeMessage(namespace, group_id, message_type, node_id) ->
      topic_namespace.to_string(namespace)
      <> "/"
      <> group_id
      <> "/"
      <> node_message_types.to_string(message_type)
      <> "/"
      <> node_id
    DeviceMessage(namespace, group_id, message_type, node_id, device_id) ->
      topic_namespace.to_string(namespace)
      <> "/"
      <> group_id
      <> "/"
      <> device_message_types.to_string(message_type)
      <> "/"
      <> node_id
      <> "/"
      <> device_id
    StateMessage(scada_host_id) -> "STATE/" <> scada_host_id
  }
}

pub type TopicNameParseError {
  TopicNameParseError(message: String)
}
