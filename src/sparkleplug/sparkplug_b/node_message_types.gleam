pub type NodeMessageType {
  NBIRTH
  NDEATH
  NDATA
  NCMD
}

pub fn to_string(message_type: NodeMessageType) -> String {
  case message_type {
    NBIRTH -> "NBIRTH"
    NDEATH -> "NDEATH"
    NDATA -> "NDATA"
    NCMD -> "NCMD"
  }
}

pub fn from_string(
  message_type_string: String,
) -> Result(NodeMessageType, NodeMessageTypeParseError) {
  case message_type_string {
    "NBIRTH" -> Ok(NBIRTH)
    "NDEATH" -> Ok(NDEATH)
    "NDATA" -> Ok(NDATA)
    "NCMD" -> Ok(NCMD)
    _ ->
      Error(NodeMessageTypeParseError(
        "Couldn't parse string to node message type.",
      ))
  }
}

pub type NodeMessageTypeParseError {
  NodeMessageTypeParseError(message: String)
}
