defmodule Newt do
  @moduledoc """
  A low-cost abstraction implementing the NewType pattern in Elixir

  There is no way (currently) to define zero-cost NewTypes in Elixir (like you
  can in Rust, Haskell, F#, etc.) because Elixir is dynamically typed. However,
  this library provides a low-cost abstraction that allows you to define
  NewTypes in Elixir with minimal boilerplate.
  """

  @callback validate(value :: any) :: {:ok, any} | {:error, String.t()}

  defprotocol Unwrap do
    @moduledoc """
    A protocol for unwrapping values from NewTypes.
    """

    @doc """
    Unwraps a value from a NewType.
    """
    @spec unwrap(any()) :: any()
    def unwrap(data)
  end

  @spec __using__(keyword(type: term())) :: Macro.t()
  defmacro __using__(opts) do
    opts =
      opts
      |> Keyword.validate!([:type, ecto_type: :string])
      |> Keyword.put_new(:type_name, __CALLER__.module)

    typespec = Keyword.fetch!(opts, :type)
    type_name = Keyword.fetch!(opts, :type_name)

    quote location: :keep do
      alias Phoenix.HTML.Safe, as: HtmlSafe
      use TypedStruct

      @behaviour Newt

      typedstruct enforce: true do
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

      @spec new(t() | unquote(typespec)) :: {:ok, t()} | {:error, String.t()}
      def new(%__MODULE__{} = value), do: {:ok, value}

      def new(value) do
        case validate(value) do
          {:ok, value} -> {:ok, %__MODULE__{value: value}}
          {:error, reason} -> {:error, reason}
        end
      end

      @spec new!(t() | unquote(typespec)) :: t()
      def new!(value) do
        case new(value) do
          {:ok, value} -> value
          {:error, reason} -> raise ArgumentError, reason
        end
      end

      @spec unwrap(%__MODULE__{}) :: unquote(typespec) | {:error, String.t()}
      def unwrap(%__MODULE__{} = type) do
        type.value
      end

      @spec validate_type(any()) :: :ok | {:error, String.t()}
      def validate_type(value) do
        case ensure_type(value) do
          {:ok, _} -> :ok
          {:error, message} -> {:error, message}
        end
      end

      @spec ensure_type(any()) :: {:ok, t()} | {:error, String.t()}
      def ensure_type(%__MODULE__{} = value), do: {:ok, value}

      def ensure_type(value) do
        {:error,
         "Expected a value of type #{inspect(unquote(type_name))}, but got #{inspect(value)}"}
      end

      @spec ensure_type!(any()) :: t()
      def ensure_type!(%__MODULE__{} = value), do: value

      def ensure_type!(value) do
        raise ArgumentError,
              "Expected a value of type #{inspect(unquote(type_name))}, but got #{inspect(value)}"
      end

      unquote(generate_inspect_impl(opts))
      unquote(generate_string_chars_impl(opts))
      unquote(generate_jason_encoder_impl(opts))
      unquote(generate_unwrap_impl(opts))
      unquote(generate_phoenix_param_impl(opts))
      unquote(generate_html_safe_impl(opts))
      unquote(generate_ecto_type(opts))
    end
  end

  defp generate_inspect_impl(opts) do
    type_name = Keyword.fetch!(opts, :type_name)

    quote do
      defimpl Inspect, for: unquote(type_name) do
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
    end
  end

  defp generate_string_chars_impl(opts) do
    type_name = Keyword.fetch!(opts, :type_name)

    quote do
      defimpl String.Chars, for: unquote(type_name) do
        def to_string(%{value: value}) do
          to_string(value)
        end
      end
    end
  end

  defp generate_jason_encoder_impl(opts) do
    type_name = Keyword.fetch!(opts, :type_name)

    quote do
      if Code.ensure_loaded?(Jason.Encoder) do
        defimpl Jason.Encoder, for: unquote(type_name) do
          def encode(%{value: value}, opts) do
            Jason.Encoder.encode(value, opts)
          end
        end
      end
    end
  end

  defp generate_unwrap_impl(opts) do
    type_name = Keyword.fetch!(opts, :type_name)

    quote do
      defimpl Unwrap, for: unquote(type_name) do
        def unwrap(value) do
          unquote(type_name).unwrap(value)
        end
      end
    end
  end

  defp generate_phoenix_param_impl(opts) do
    type_name = Keyword.fetch!(opts, :type_name)

    quote do
      if Code.ensure_loaded?(Phoenix.Param) do
        defimpl Phoenix.Param, for: unquote(type_name) do
          def to_param(%{value: value}) do
            Phoenix.Param.to_param(value)
          end
        end
      end
    end
  end

  defp generate_html_safe_impl(opts) do
    type_name = Keyword.fetch!(opts, :type_name)

    quote do
      if Code.ensure_loaded?(HtmlSafe) do
        defimpl Phoenix.HTML.Safe, for: unquote(type_name) do
          def to_iodata(%{value: value}) do
            HtmlSafe.to_iodata(value)
          end
        end
      end
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp generate_ecto_type(opts) do
    type_name = Keyword.fetch!(opts, :type_name)
    ecto_type = Keyword.fetch!(opts, :ecto_type)

    quote do
      if Code.ensure_loaded?(Ecto.Type) do
        defmodule Ectotype do
          @moduledoc """
          Ecto adapter for the type
          """
          alias unquote(type_name), as: DomainType

          use Ecto.Type

          @type t() :: DomainType.t()

          @impl true
          def type, do: unquote(ecto_type)

          @impl true
          def cast(value) when is_struct(value, unquote(type_name)), do: {:ok, value}

          def cast(value) do
            case DomainType.new(value) do
              {:ok, value} -> {:ok, value}
              {:error, _message} -> :error
            end
          end

          @impl true
          def load(data) do
            DomainType.new(data)
          end

          @impl true
          def dump(value) when is_struct(value, unquote(type_name)) do
            {:ok, DomainType.unwrap(value)}
          end

          def dump(_value) do
            :error
          end
        end
      end
    end
  end

  def maybe_unwrap(data) do
    Unwrap.unwrap(data)
  rescue
    Protocol.UndefinedError -> data
    x -> reraise(x, __STACKTRACE__)
  end
end
