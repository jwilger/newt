defmodule NewtTest do
  alias Newt.ExampleIntegerType
  alias Newt.ExampleStringType
  alias Newt.ExampleUnvalidatedStringType

  use Newt.TestCase
  use ExampleUnvalidatedStringType
  use ExampleStringType

  describe "new/1" do
    test "returns the passed primitive value as the type" do
      {:ok, value} = ExampleUnvalidatedStringType.new(Faker.Lorem.word())
      assert ExampleUnvalidatedStringType.is_type(value)
    end

    property "returns an error if the value is not valid" do
      check all value <- term() |> filter(fn v -> v != "example" end) do
        {:error, "must be 'example'"} = ExampleStringType.new(value)
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

  describe "defimpl/2" do
    test "defines a protocol implementation for the type" do
      {:ok, value} = ExampleIntegerType.new(42)
      assert Add.add_99(value) == 141
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
end
