# Cgcef

A port of the [Cyber Grand Challenge Executable Format verifier][1] to an Elixir
library. This library is useful for processing CGC challenge binaries and
proofs-of-vulnerability prior to analysis.

It is available as both an Elixir module and a command-line application.

[1]: https://github.com/CyberGrandChallenge/cgcef-verify

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add cgcef to your list of dependencies in `mix.exs`:

        def deps do
          [{:cgcef, "~> 0.0.1"}]
        end

  2. Ensure cgcef is started before your application:

        def application do
          [applications: [:cgcef]]
        end

## Usage

### Elixir Module

```elixir
case Cgcef.verify(filename_or_file_handle) do
    :ok -> "success"
    {:error, message} ->
        message
        # either string description of CGC executable format error or
        # symbol of file error
  end
end

case Cgcef.analyze(filename_or_file_handle) do
    result = %Cgcef{} -> IO.inspect(result)
    {:error, message} ->
        message
        # either string description of CGC executable format error or
        # symbol of file error
    end
end
```
