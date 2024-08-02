defmodule Newt.ExampleStringType do
  @moduledoc false
  use Newt, type: String.t()

  @impl true
  def validate(value) do
    case value do
      "example" -> {:ok, value}
      _ -> {:error, "must be 'example'"}
    end
  end
end

defmodule Newt.ExampleUnvalidatedStringType do
  @moduledoc false
  use Newt, type: String.t()
end

defmodule Newt.ExampleIntegerType do
  @moduledoc false
  use Newt, type: integer(), ecto_type: :integer

  def validate(value) do
    case value do
      42 -> {:ok, value}
      _ -> {:error, "must be 42"}
    end
  end
end
