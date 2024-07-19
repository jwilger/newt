defmodule Newt do
  @moduledoc """
  A low-cost abstraction implementing the NewType pattern in Elixir

  There is no way (currently) to define zero-cost NewTypes in Elixir (like you
  can in Rust, Haskell, F#, etc.) because Elixir is dynamically typed. However,
  this library provides a low-cost abstraction that allows you to define
  NewTypes in Elixir with minimal boilerplate.
  """

  @spec __using__(keyword(type: term())) :: Macro.t()
  defmacro __using__(opts) do
    opts = Keyword.validate!(opts, [:type])
    typespec = Keyword.fetch!(opts, :type)
    module_name = "Type_#{UUID.uuid4(:hex)}" |> String.to_atom()
    type_name = __CALLER__.module

    quote location: :keep do
      use TypedStruct

      @behaviour Newt

      @opaque t() :: unquote(module_name).t()

      typedstruct enforce: true, opaque: true, module: unquote(module_name) do
        field(:value, unquote(typespec))
      end

      @impl true

      # N.B. This clause of validate should never *actually* be called, but
      # having it prevents a dialyzer warning with the case statement in new/1.
      def validate(
            Newt.StupidPlaceholderValueThatWouldBeRidiculousToEverUseInYourProgramSoDoNotDoItOK
          ) do
        {:error, "418 - I'm a teapot"}
      end

      def validate(value) do
        {:ok, value}
      end

      defoverridable validate: 1

      @spec new(unquote(typespec)) :: {:ok, t()} | {:error, String.t()}
      def new(value) do
        case validate(value) do
          {:ok, value} -> {:ok, %unquote(module_name){value: value}}
          {:error, reason} -> {:error, reason}
        end
      end

      @spec unwrap(any()) :: unquote(typespec) | {:error, String.t()}
      def unwrap(type) when is_struct(type, unquote(module_name)) do
        type.value
      end

      def unwrap(value) do
        raise ArgumentError,
              "Expected a value of type #{inspect(unquote(type_name))}, but got #{inspect(value)}"
      end

      @spec validate_type(any()) :: boolean()
      def validate_type(value) do
        case ensure_type(value) do
          {:ok, _} -> true
          {:error, _} -> false
        end
      end

      @spec ensure_type(any()) :: {:ok, t()} | {:error, String.t()}
      def ensure_type(value) when is_struct(value, unquote(module_name)), do: {:ok, value}

      def ensure_type(value) do
        {:error,
         "Expected a value of type #{inspect(unquote(type_name))}, but got #{inspect(value)}"}
      end

      @spec ensure_type!(any()) :: t()
      def ensure_type!(value) when is_struct(value, unquote(module_name)), do: value

      def ensure_type!(value) do
        raise ArgumentError,
              "Expected a value of type #{inspect(unquote(type_name))}, but got #{inspect(value)}"
      end

      defguard is_type(value) when is_struct(value, unquote(module_name))

      defmacro __using__(_opts \\ []) do
        quote do
          require unquote(__MODULE__)
        end
      end

      defmacro defimpl(protocol, do: block) do
        module_name = unquote(module_name)

        quote do
          defimpl unquote(protocol), for: unquote(module_name) do
            unquote(block)
          end
        end
      end

      defimpl Inspect, for: unquote(module_name) do
        import Inspect.Algebra

        def inspect(%{value: value}, opts) do
          concat([
            "#",
            to_doc(unquote(type_name), opts),
            string("<"),
            to_doc(value, opts),
            string(">")
          ])
        end
      end

      defimpl String.Chars, for: unquote(module_name) do
        def to_string(%{value: value}) do
          to_string(value)
        end
      end

      defimpl Jason.Encoder, for: unquote(module_name) do
        def encode(%{value: value}, opts) do
          Jason.Encoder.encode(value, opts)
        end
      end
    end
  end

  @callback validate(value :: any) :: {:ok, any} | {:error, String.t()}
end
