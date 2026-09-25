defmodule BreezeCharts.MixProject do
  use Mix.Project

  @version "0.1.0"
  @docs_ref "78d2b946d29cf928b7d72873bfef829696ccf30e"
  @source_url "https://github.com/Gazler/breeze_charts"

  def project do
    [
      app: :breeze_charts,
      version: @version,
      description: "Chart components for Breeze terminal applications",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [docs: &generate_docs/1],
      name: "Breeze Charts",
      source_url: @source_url,
      docs: [
        main: "readme",
        extras: ["README.md", "doc_src/generated/charts.md", "LICENCE.md"],
        source_ref: "v#{@version}",
        before_closing_head_tag: &docs_head/1,
        before_closing_body_tag: &docs_body/1
      ],
      package: [
        files: ~w(lib .formatter.exs mix.exs README.md LICENCE.md),
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url}
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:breeze, "~> 0.5.3"},
      {:file_system, "~> 1.1", only: :dev},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:breeze_doc_support,
       github: "Gazler/breeze",
       ref: @docs_ref,
       sparse: "doc_support",
       only: :dev,
       runtime: false,
       app: false,
       compile: false},
      {:breeze_doc_assets,
       github: "Gazler/breeze",
       ref: @docs_ref,
       sparse: "doc_src/assets",
       only: :dev,
       runtime: false,
       app: false,
       compile: false}
    ]
  end

  defp generate_docs(args) do
    Mix.Task.run("compile")
    Code.require_file(Path.join(Mix.Project.deps_paths()[:breeze_doc_support], "docs_assets.ex"))
    Code.require_file("doc_support/chart_previews.ex", __DIR__)
    apply(Breeze.Charts.Docs.Previews, :write!, [])

    config =
      Keyword.update!(Mix.Project.config(), :docs, fn docs ->
        Keyword.put(docs, :assets, %{Mix.Project.deps_paths()[:breeze_doc_assets] => "assets"})
      end)

    Mix.Tasks.Docs.run(args, config, &ExDoc.generate/4)
  end

  defp docs_head(:html), do: apply(Breeze.Docs.Assets, :head_html, [])
  defp docs_head(_), do: ""
  defp docs_body(:html), do: apply(Breeze.Docs.Assets, :body_html, [])
  defp docs_body(_), do: ""
end
