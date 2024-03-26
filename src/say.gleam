import gleam/io
import argv
import gleam/string
import gleam/bool
import glint
import glint/flag
import gleam/function

fn remove_end_string(str) {
  let split =
    str
    |> string.split_once("\\c")
  case split {
    Ok(#(first_substring, _)) -> first_substring
    Error(_) -> str
  }
}

fn parse_string(str) {
  str
  |> string.replace("\\\\", "\\")
  |> remove_end_string
  |> string.replace("\\a", "\u{000007}")
  |> string.replace("\\b", "\u{000008}")
  |> string.replace("\\e", "\u{00001B}")
  |> string.replace("\\f", "\f")
  |> string.replace("\\n", "\n")
  |> string.replace("\\r", "\r")
  |> string.replace("\\t", "\t")
  |> string.replace("\\v", "\u{00000B}")
}

type Args {
  Version
  Echo(input: String, newline: Bool, escape: Bool)
}

fn parse_args(input: glint.CommandInput) {
  let assert Ok(version) = flag.get_bool(from: input.flags, for: "version")
  use <- bool.guard(version, Version)
  let assert Ok(enable_escape) = flag.get_bool(from: input.flags, for: "e")
  let assert Ok(disable_escape) = flag.get_bool(from: input.flags, for: "E")
  let assert Ok(disable_newline) = flag.get_bool(from: input.flags, for: "n")
  let newline = !disable_newline
  let escape = case disable_escape {
    True -> False
    False -> enable_escape
  }
  let input =
    input.args
    |> string.join(" ")
  Echo(input, newline, escape)
}

fn flag(flag, name) {
  glint.flag(
    flag,
    name,
    flag.bool()
      |> flag.default(False),
  )
}

pub fn main() {
  glint.new()
  |> glint.with_name("say")
  |> glint.add(
    at: [],
    do: glint.command(fn(input: glint.CommandInput) {
        let args = parse_args(input)
        case args {
          Version -> io.println("0.1.0")
          Echo(input, newline, escape) ->
            input
            |> case escape {
              True -> parse_string
              False -> function.identity
            }
            |> case newline {
              True -> io.println
              False -> io.print
            }
        }
      })
      |> flag("version")
      |> flag("n")
      |> flag("e")
      |> flag("E"),
  )
  |> glint.run(argv.load().arguments)
}
