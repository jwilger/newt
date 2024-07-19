require Newt.ExampleIntegerType

defprotocol Add do
  def add_99(value)
end

Newt.ExampleIntegerType.defimpl Add do
  def add_99(value) do
    number = Newt.ExampleIntegerType.unwrap(value)
    number + 99
  end
end
