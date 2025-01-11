pub type DeviceMessageType {
  DBIRTH
  DDEATH
  DDATA
  DCMD
}

pub fn to_string(message_type: DeviceMessageType) -> String {
  case message_type {
    DBIRTH -> "DBIRTH"
    DDEATH -> "DDEATH"
    DDATA -> "DDATA"
    DCMD -> "DCMD"
  }
}

pub fn from_string(
  message_type_string: String,
) -> Result(DeviceMessageType, DeviceMessageTypeParseError) {
  case message_type_string {
    "DBIRTH" -> Ok(DBIRTH)
    "DDEATH" -> Ok(DDEATH)
    "DDATA" -> Ok(DDATA)
    "DCMD" -> Ok(DCMD)
    _ ->
      Error(DeviceMessageTypeParseError(
        "Couldn't parse string to device message type.",
      ))
  }
}

pub type DeviceMessageTypeParseError {
  DeviceMessageTypeParseError(message: String)
}
