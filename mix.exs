defmodule ExCloudflarePhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_cloudflare_phoenix,
      version: "0.1.0",
      elixir: "~> 1.17",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/nshkrdotcom/ex_cloudflare_phoenix"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExCloudflarePhoenix.Application, []}
    ]
  end

  defp deps do
    [
      # Phoenix core (but not the full framework)
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},

      # Our Cloudflare modules
      {:ex_cloudflare_calls, path: "../ex_cloudflare_calls"},
      {:ex_cloudflare_durable, path: "../ex_cloudflare_durable"},

      # JSON handling
      {:jason, "~> 1.4"},

      # Development tools
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Phoenix components and behaviors for Cloudflare integration."
  end

  defp package() do
    [
      name: "Cloudflare Phoenix",
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      maintainers: ["nshkrdotcom"],
      links: %{"GitHub" => "https://github.com/nshkrdotcom/ex_cloudflare_phoenix"}
    ]
  end
end
