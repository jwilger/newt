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

      @spec unwrap(t()) :: unquote(typespec)
      def unwrap(%{value: value} = type) when is_struct(type, unquote(module_name)) do
        value
      end

      def unwrap({:error, reason}) do
        {:error, reason}
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

  @spec newtype(atom(), term()) :: Macro.t()
  defmacro newtype(type_name, typespec) do
    quote do
      defmodule unquote(type_name) do
        use Newt, type: unquote(typespec)
      end
    end
  end

  @spec newtype(atom(), term(), do: Macro.t()) :: Macro.t()
  defmacro newtype(type_name, typespec, do: block) do
    quote do
      defmodule unquote(type_name) do
        use Newt, type: unquote(typespec)

        @impl true
        def validate(var!(value)) do
          unquote(block)
        end
      end
    end
  end

  @callback validate(value :: any) :: {:ok, any} | {:error, String.t()}
end
