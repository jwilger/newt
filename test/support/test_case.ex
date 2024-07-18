defmodule Newt.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnitProperties
      import AssertMatch
    end
  end
end
