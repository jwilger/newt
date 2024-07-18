import Newt

newtype Newt.ExampleStringType, String.t() do
  case value do
    "example" -> {:ok, value}
    _ -> {:error, "must be 'example'"}
  end
end

newtype Newt.ExampleUnvalidatedStringType, String.t()

newtype Newt.ExampleIntegerType, integer() do
  case value do
    42 -> {:ok, value}
    _ -> {:error, "must be 42"}
  end
end
