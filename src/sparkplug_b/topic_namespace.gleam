pub type TopicNamespace {
  SpAv10
  SpBv10
}

pub fn from_string(
  namespace_string: String,
) -> Result(TopicNamespace, TopicNamespaceParseError) {
  case namespace_string {
    "SpAv1.0" -> Ok(SpAv10)
    "SpBv1.0" -> Ok(SpBv10)
    _ ->
      Error(TopicNamespaceParseError(
        "Couldn't parse topic namespace from string.",
      ))
  }
}

pub fn to_string(topic_namespace: TopicNamespace) -> String {
  case topic_namespace {
    SpAv10 -> "SpAv1.0"
    SpBv10 -> "SpBv1.0"
  }
}

pub type TopicNamespaceParseError {
  TopicNamespaceParseError(message: String)
}
