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
      |> Keyword.put_new(
        :module_name,
        "#{__CALLER__.module}_InnerType_#{UUID.uuid4(:hex)}" |> String.to_atom()
      )

    typespec = Keyword.fetch!(opts, :type)
    module_name = Keyword.fetch!(opts, :module_name)
    type_name = Keyword.fetch!(opts, :type_name)

    quote location: :keep do
      alias Phoenix.HTML.Safe, as: HtmlSafe
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

      @spec new(unquote(module_name).t() | unquote(typespec)) :: {:ok, t()} | {:error, String.t()}
      def new(value) when is_struct(value, unquote(module_name)), do: {:ok, value}

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

      @spec validate_type(any()) :: :ok | {:error, String.t()}
      def validate_type(value) do
        case ensure_type(value) do
          {:ok, _} -> :ok
          {:error, message} -> {:error, message}
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
    module_name = Keyword.fetch!(opts, :module_name)

    quote do
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
    end
  end

  defp generate_string_chars_impl(opts) do
    module_name = Keyword.fetch!(opts, :module_name)

    quote do
      defimpl String.Chars, for: unquote(module_name) do
        def to_string(%{value: value}) do
          to_string(value)
        end
      end
    end
  end

  defp generate_jason_encoder_impl(opts) do
    module_name = Keyword.fetch!(opts, :module_name)

    quote do
      if Code.ensure_loaded?(Jason.Encoder) do
        defimpl Jason.Encoder, for: unquote(module_name) do
          def encode(%{value: value}, opts) do
            Jason.Encoder.encode(value, opts)
          end
        end
      end
    end
  end

  defp generate_unwrap_impl(opts) do
    module_name = Keyword.fetch!(opts, :module_name)

    quote do
      defimpl Unwrap, for: unquote(module_name) do
        def unwrap(%{value: value}) do
          value
        end
      end
    end
  end

  defp generate_phoenix_param_impl(opts) do
    module_name = Keyword.fetch!(opts, :module_name)

    quote do
      if Code.ensure_loaded?(Phoenix.Param) do
        defimpl Phoenix.Param, for: unquote(module_name) do
          def to_param(%{value: value}) do
            Phoenix.Param.to_param(value)
          end
        end
      end
    end
  end

  defp generate_html_safe_impl(opts) do
    module_name = Keyword.fetch!(opts, :module_name)

    quote do
      if Code.ensure_loaded?(HtmlSafe) do
        defimpl Phoenix.HTML.Safe, for: unquote(module_name) do
          def to_iodata(%{value: value}) do
            HtmlSafe.to_iodata(value)
          end
        end
      end
    end
  end

  defp generate_ecto_type(opts) do
    type_name = Keyword.fetch!(opts, :type_name)
    ecto_type = Keyword.fetch!(opts, :ecto_type)
    module_name = Keyword.fetch!(opts, :module_name)

    quote do
      if Code.ensure_loaded?(Ecto.Type) do
        defmodule Ectotype do
          @moduledoc """
          Ecto adapter for the type
          """
          alias unquote(type_name), as: DomainType

          use Ecto.Type

          @impl true
          def type, do: unquote(ecto_type)

          @impl true
          def cast(value) when is_struct(value, unquote(module_name)), do: {:ok, value}

          def cast(_value), do: :error

          @impl true
          def load(data) do
            DomainType.new(data)
          end

          @impl true
          def dump(value) when is_struct(value, unquote(module_name)) do
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
