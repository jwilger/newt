defmodule NewtTest do
  alias Newt.ExampleIntegerType
  alias Newt.ExampleOverriddenNewFunctionType
  alias Newt.ExampleStringType
  alias Newt.ExampleUnvalidatedStringType
  alias Newt.ValidationError
  alias Phoenix.HTML.Safe, as: HtmlSafe

  require ExampleUnvalidatedStringType
  require ExampleStringType
  require Newt

  use Newt.TestCase

  describe "new/1" do
    test "returns the passed primitive value as the type" do
      {:ok, value} = ExampleUnvalidatedStringType.new(Faker.Lorem.word())
      assert is_struct(value, ExampleUnvalidatedStringType)
    end

    test "returns the argument if the argument is already the type" do
      {:ok, value} = ExampleUnvalidatedStringType.new(Faker.Lorem.word())
      assert {:ok, ^value} = ExampleUnvalidatedStringType.new(value)
    end

    property "returns an error if the value is not valid" do
      check all value <- term() |> filter(fn v -> v != "example" end) do
        {:error, %ValidationError{message: "must be 'example'"}} =
          ExampleStringType.new(value)
      end
    end

    test "can be overridden by the type" do
      {:ok, value} = ExampleOverriddenNewFunctionType.new(Faker.Lorem.word())
      assert value == "Not what you expected."
    end
  end

  describe "new!/1" do
    test "returns the passed primitive value as the type" do
      value = ExampleUnvalidatedStringType.new!(Faker.Lorem.word())
      assert is_struct(value, ExampleUnvalidatedStringType)
    end

    test "returns the argument if the argument is already the type" do
      value = ExampleUnvalidatedStringType.new!(Faker.Lorem.word())
      assert ^value = ExampleUnvalidatedStringType.new!(value)
    end

    property "returns an error if the value is not valid" do
      check all value <- term() |> filter(fn v -> v != "example" end) do
        assert_raise(ValidationError, "must be 'example'", fn ->
          ExampleStringType.new!(value)
        end)
      end
    end
  end

  describe "unwrap/1" do
    test "returns the wrapped value" do
      {:ok, value} = ExampleStringType.new("example")
      assert ExampleStringType.unwrap(value) == "example"

      {:ok, value} = ExampleIntegerType.new(42)
      assert ExampleIntegerType.unwrap(value) == 42
    end
  end

  describe "Inspect implementation" do
    test "returns an opaque representation of the type" do
      {:ok, value} = ExampleStringType.new("example")
      assert inspect(value) == "#Newt.ExampleStringType<\"example\">"

      {:ok, value} = ExampleIntegerType.new(42)
      assert inspect(value) == "#Newt.ExampleIntegerType<42>"
    end
  end

  describe "String.Chars implementation" do
    test "returns the wrapped value as a string" do
      {:ok, value} = ExampleStringType.new("example")
      assert to_string(value) == "example"

      {:ok, value} = ExampleIntegerType.new(42)
      assert to_string(value) == "42"
    end
  end

  describe "Jason.Encoder implementation" do
    test "encodes the wrapped value" do
      {:ok, value} = ExampleStringType.new("example")
      assert Jason.encode!(value) == "\"example\""

      {:ok, value} = ExampleIntegerType.new(42)
      assert Jason.encode!(value) == "42"
    end
  end

  describe "maybe_unwrap/1" do
    test "returns the wrapped value if it is a type" do
      {:ok, value} = ExampleStringType.new("example")
      assert Newt.maybe_unwrap(value) == "example"

      {:ok, value} = ExampleIntegerType.new(42)
      assert Newt.maybe_unwrap(value) == 42
    end

    test "returns the value if it is not a type" do
      assert Newt.maybe_unwrap("example") == "example"
      assert Newt.maybe_unwrap(42) == 42
    end
  end

  describe "Phoenix.Param implementation" do
    test "returns the wrapped value converted to a param" do
      {:ok, value} = ExampleStringType.new("example")
      assert Phoenix.Param.to_param(value) == Phoenix.Param.to_param("example")

      {:ok, value} = ExampleIntegerType.new(42)
      assert Phoenix.Param.to_param(value) == Phoenix.Param.to_param(42)
    end
  end

  describe "Phoenix.HTML.Safe implementatin" do
    test "returns the wrapped value as a safe string" do
      {:ok, value} = ExampleStringType.new("example")
      assert HtmlSafe.to_iodata(value) == HtmlSafe.to_iodata("example")

      {:ok, value} = ExampleIntegerType.new(42)
      assert HtmlSafe.to_iodata(value) == HtmlSafe.to_iodata(42)
    end
  end

  describe "Ecto.Type implementation" do
    test "type/0" do
      assert ExampleStringType.Ectotype.type() == :string
      assert ExampleIntegerType.Ectotype.type() == :integer
    end

    test "cast/1" do
      {:ok, value} = ExampleStringType.new("example")
      assert ExampleStringType.Ectotype.cast(value) == {:ok, value}

      {:ok, value} = ExampleIntegerType.new(42)
      assert ExampleIntegerType.Ectotype.cast(value) == {:ok, value}

      assert ExampleStringType.Ectotype.cast("example") ==
               {:ok, ExampleStringType.new!("example")}
    end

    test "load/1" do
      {:ok, value} = ExampleStringType.new("example")
      assert ExampleStringType.Ectotype.load("example") == {:ok, value}

      {:ok, value} = ExampleIntegerType.new(42)
      assert ExampleIntegerType.Ectotype.load(42) == {:ok, value}

      assert {:error, %ValidationError{message: "must be 'example'"}} =
               ExampleStringType.Ectotype.load([1])
    end

    test "dump/1" do
      {:ok, value} = ExampleStringType.new("example")
      assert ExampleStringType.Ectotype.dump(value) == {:ok, "example"}

      {:ok, value} = ExampleIntegerType.new(42)
      assert ExampleIntegerType.Ectotype.dump(value) == {:ok, 42}

      assert ExampleStringType.Ectotype.dump("example") == :error
    end
  end

  describe "type!/2 macro" do
    test "returns true if the argument is of the given type" do
      arg = ExampleStringType.new!("example")

      func = fn
        arg when Newt.type!(arg, ExampleStringType) -> true
        _ -> false
      end

      assert func.(arg)
    end

    test "returns false if the argument is not of the given type" do
      arg = ExampleStringType.new!("example")

      func = fn
        arg when Newt.type!(arg, ExampleIntegerType) -> true
        _ -> false
      end

      refute func.(arg)
    end

    test "returns false if the argument is not a Newt type" do
      check all arg <-
                  term()
                  |> filter(fn
                    arg when is_struct(arg) ->
                      try do
                        :ok != Protocol.assert_impl!(Newt, arg)
                      rescue
                        ArgumentError -> true
                      end

                    _ ->
                      true
                  end) do
        func = fn
          arg when Newt.type!(arg, ExampleIntegerType) -> true
          _ -> false
        end

        refute func.(arg)
      end
    end
  end
end
