# Newt

A low-cost abstraction implementing the NewType pattern in Elixir

There is no way (currently) to define zero-cost NewTypes in Elixir (like you
can in Rust, Haskell, F#, etc.) because Elixir is dynamically typed. However,
this library provides a low-cost abstraction that allows you to define NewTypes
in Elixir with minimal boilerplate.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `newt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:newt, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/newt>.
