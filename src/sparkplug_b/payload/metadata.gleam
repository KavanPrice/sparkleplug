import gleam/option.{type Option}

pub type MetaData {
  MetaData(
    is_multi_part: Option(Bool),
    content_type: Option(String),
    size: Option(Int),
    seq: Option(Int),
    file_name: Option(String),
    file_type: Option(String),
    md5: Option(String),
    description: Option(String),
  )
}
