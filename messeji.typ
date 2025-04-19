#let default-theme = (
  timestamp-color: rgb(101, 103, 107),
  timestamp-size: .9em,
  date-changed-color: black,
  date-changed-size: 1.5em,
  me-right: (
    color: white,
    background-color: rgb("#3797F0"),
    quote-color: black,
    quote-background-color: rgb(239, 239, 239),
  ),
  other-left: (
    color: black,
    background-color: rgb(239, 239, 239),
    quote-color: black,
    quote-background-color: rgb(239, 239, 239),
  ),
)

#let _fill_dict_default(
  actual,
  default,
) = {
  // iterate over every key of default

  let result = (:)

  for (key, value) in default.pairs() {
    // if key exists in actual dictionary, use its value
    if key in actual {
      // check for nested dictionary -> recursive call
      if type(actual.at(key)) == dictionary {
        result.insert(key, _fill_dict_default(actual.at(key), default.at(key)))
      } else {
        result.insert(key, actual.at(key))
      }
    } else {
      // insert value from default dictionary
      result.insert(key, value)
    }
  }

  return result
}

#let _to_int(s) = {
  let no_prefix = s.trim("0")
  if no_prefix.len() == 0 {
    return 0
  } else {
    return int(no_prefix)
  }
}

#let _parse_timestamp_iso_8601(s) = {
  let split = s.split("T")
  let day = split.at(0).trim()
  let time = split.at(1).trim()

  let day_parts = day.split("-")
  let time_parts = time.split(":")

  return datetime(
    year: _to_int(day_parts.at(0)),
    month: _to_int(day_parts.at(1)),
    day: _to_int(day_parts.at(2)),
    hour: _to_int(time_parts.at(0)),
    minute: _to_int(time_parts.at(1)),
    second: _to_int(time_parts.at(2)),
  )
}


#let chat-bubble(
  theme, // dictionary, see default-theme
  message,
  quote: "",
  msg-align: "left", // "left" or "right",
  image: none,
) = {
  // Global Settings
  let bubble-inset = 0.75em
  let radius = 0.8em
  let tail = true

  // Rendering
  let is-right = msg-align == "right"
  let curr-theme = theme.other-left
  if is-right {
    curr-theme = theme.me-right
  }

  // optional: quoted message
  align(
    if is-right { right } else { left },
    block(
      breakable: false,
      stack(
        spacing: 2pt,
        // quoted message
        if quote != "" {
          v(2pt)
          align(
            horizon,
            stack(
              dir: ltr,
              spacing: 4pt,
              if not is-right {
                // vertical line next to quoted message
                rect(
                  width: 3pt,
                  height: 20pt,
                  radius: 1.5pt,
                  fill: curr-theme.at("quote-background-color"),
                )
              },
              block(
                width: auto,
                inset: (
                  top: bubble-inset / 2,
                  left: bubble-inset,
                  right: bubble-inset,
                  bottom: bubble-inset / 2,
                ),
                fill: curr-theme.at("quote-background-color"),
                radius: radius,
                align(
                  left,
                  text(
                    curr-theme.at("quote-color"),
                    size: 0.875em,
                    quote,
                  ),
                ),
              ),
              if is-right {
                rect(
                  width: 3pt,
                  height: 20pt,
                  radius: 1.5pt,
                  fill: curr-theme.at("quote-background-color"),
                )
              },
            ),
          )
        },

        // message bubble
        block(
          width: auto,
          radius: (
            top-left: radius,
            top-right: radius,
            bottom-left: if is-right or not tail { radius } else { 0pt },
            bottom-right: if is-right and tail { 0pt } else { radius },
          ),
          inset: bubble-inset / 2,
          fill: curr-theme.at("background-color"),
          stack(
            dir: ttb,
            spacing: 0pt,

            // image (optional)
            if image != none {
              block(
                clip: true, // for rounded corners of image
                width: 50%,
                radius: radius - (bubble-inset / 2), // innerR = outerR - gap
                image,
              )
            },

            // caption
            if message != "" {
              if image != none {
                v(bubble-inset / 2)
              }
              block(
                width: auto,
                inset: (
                  left: bubble-inset / 2,
                  right: bubble-inset / 2,
                ),
                align(
                  left,
                  text(
                    curr-theme.at("color"),
                    size: 0.9375em,
                    message,
                  ),
                ),
              )
            },
          ),
        ),
      ),
    ),
  )
}

#let messeji(
  chat-data: [], // array of messages
  date-changed-format: none,
  timestamp-format: "[year]-[month]-[day] [hour]:[minute]",
  images: (:), // image dictionary, key is filename, value is loaded image
  theme: (:), // theme dictionary, if value is not filled, default is used
) = {
  if chat-data.len() == 0 {
    return
  }

  set block(spacing: 0pt)
  set text(
    top-edge: "ascender",
    bottom-edge: "descender",
  )

  let curr-theme = _fill_dict_default(theme, default-theme)

  let last_day = 0
  let previous_sender = chat-data.first().at("from_me")

  for (i, msg) in chat-data.enumerate() {
    // Alignment
    let msg_align = "left"
    if "from_me" in msg {
      if msg.at("from_me") {
        msg_align = "right"
      }
    }

    let time_str = ""
    let date_str = ""
    if "date" in msg {
      let date_val = msg.at("date")
      let parsed_date = _parse_timestamp_iso_8601(date_val)

      if date-changed-format != none and last_day != parsed_date.day() {
        date_str = parsed_date.display(date-changed-format)
        last_day = parsed_date.day()
      }
      // show time
      time_str = parsed_date.display(timestamp-format)
    }

    // add padding depending on
    if previous_sender != msg.at("from_me") {
      // different sender -> more padding
      previous_sender = msg.at("from_me")
      if not "date" in msg {
        v(16pt)
      } else {
        v(4pt)
      }
    }

    let quote = ""
    if "ref" in msg {
      quote = msg.at("ref")
    }

    let image = none
    if "image" in msg {
      let image-name = msg.at("image")
      image = images.at(image-name)
    }

    let msg_text = ""
    if "msg" in msg {
      msg_text = msg.at("msg")
    }

    block(
      breakable: false,
      width: 100%,
      stack(
        dir: ttb,
        if date_str != "" {
          align(center)[
            #v(16pt)
            #text(curr-theme.at("date-changed-color"), size: curr-theme.at("date-changed-size"), date_str)
            #v(8pt)
          ]
        },
        if time_str != "" {
          align(center)[
            #v(16pt)
            #text(curr-theme.at("timestamp-color"), size: curr-theme.at("timestamp-size"), time_str)
            #v(8pt)
          ]
        },
        chat-bubble(
          curr-theme,
          msg_text,
          image: image,
          quote: quote,
          msg-align: msg_align,
        ),
      ),
    )
  }
}

// Returns a dictionary of image names that are present in the chat data
#let get-image-names(
  chat-data,
) = {
  let results = (:)

  for msg in chat-data {
    if "image" in msg {
      let image-name = msg.at("image")
      results.insert(image-name, none)
    }
  }
  return results
}
