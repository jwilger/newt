defmodule Newt.MixProject do
  use Mix.Project

  def project do
    [
      app: :newt,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      deps: deps(),
      name: "Newt",
      source_url: "https://github.com/jwilger/newt",
      homepage_url: "https://github.com/jwilger/newt/blob/main/README.md",
      docs: [
        output: "priv/static/docs",
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:assert_match, "~> 1.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.21", only: :dev, runtime: false},
      {:ex_check, "~> 0.15", only: :dev, runtime: false},
      {:ex_doc, "~> 0.30", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.18"},
      {:mix_audit, "~> 2.1", only: :dev, runtime: false},
      {:mix_test_interactive, "~> 2.0", only: :dev, runtime: false},
      {:stream_data, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:vex, "~> 0.9"}
    ]
  end

  defp aliases do
    [
      setup: [
        "cmd ln -sf ../../dev-scripts/pre-commit-hook .git/hooks/pre-commit",
        "deps.get"
      ],
      test: ["test --warnings-as-errors"],
      compile: ["compile --warnings-as-errors"],
      dialyzer: ["compile", "dialyzer --list-unused-filters --force-check"],
      credo: ["credo --strict"],
      check_formatting: ["format --check-formatted"],
      check: ["clean", "deps.get", "deps.compile", "check"]
    ]
  end
end
