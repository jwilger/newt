defmodule NewtTest do
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

  describe "Inspect implementation" do
    test "returns an opaque representation of the type" do
      {:ok, value} = ExampleStringType.new("example")
      assert inspect(value) == "#Newt.ExampleStringType<\"example\">"
    end
  end
end
