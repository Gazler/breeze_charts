defmodule Breeze.Charts.Docs.Previews do
  @moduledoc false

  @output Path.expand("../doc_src/generated/charts.md", __DIR__)
  @themes [
    {:greenscreen, "Greenscreen"},
    {:nebula, "Nebula"},
    {:catppuccin, "Catppuccin Mocha"},
    {:dracula, "Dracula"},
    {:commander, "Commander Blue"},
    {:gruvbox, "Gruvbox Dark"},
    {:nord, "Nord"},
    {:solarized_light, "Solarized Light"},
    {:solarized_dark, "Solarized Dark"}
  ]

  defmodule Sparkline do
    use Breeze.View
    import Breeze.Charts

    def render(assigns) do
      ~H"""
      <box class="bg-panel">
        <box class="bold">Automatic scale</box>
        <.sparkline values={[12, 18, 14, 24, 32, 28, 42, 36, 48, 40, 52, 44]} class="text-success"/>
        <box class="bold pt-1">Shared scale: 0–100%</box>
        <box class="inline">
          <box class="w-8">CPU</box>
          <.sparkline values={[10, 15, 20, 18, 35, 55, 70, 85, 60, 45, 30, 20]} min={0} max={100}/>
        </box>
        <box class="inline">
          <box class="w-8">Memory</box>
          <.sparkline values={~c"(*+-0247:<>A"} min={0} max={100} class="text-accent"/>
        </box>
      </box>
      """
    end
  end

  def chart_series do
    [%{key: :input, name: "Input"}, %{key: :output, name: "Output"}]
  end

  def line_chart_data do
    [
      %{x: 0, values: %{input: 180, output: 120}},
      %{x: 1, values: %{input: 260, output: 180}},
      %{x: 2, values: %{input: 220, output: 150}},
      %{x: 3, values: %{input: 420, output: 280}},
      %{x: 4, values: %{input: 300, output: 220}}
    ]
  end

  def bar_chart_data do
    [
      %{x: "Run A", values: %{input: 420, output: 180}},
      %{x: "Run B", values: %{input: 610, output: 240}},
      %{x: "Run C", values: %{input: 350, output: 210}}
    ]
  end

  defmodule LineChartPreview do
    use Breeze.View
    import Breeze.Charts

    def mount(_opts, term), do: {:ok, term}
    def handle_event(_, _, term), do: {:noreply, term}

    def render(assigns) do
      assigns =
        assign(assigns,
          data: Breeze.Charts.Docs.Previews.line_chart_data(),
          series: Breeze.Charts.Docs.Previews.chart_series()
        )

      ~H"""
      <.line_chart data={@data} series={@series} width={44} height={10} min={0} max={500}/>
      """
    end
  end

  defmodule GroupedBarChartPreview do
    use Breeze.View
    import Breeze.Charts

    def mount(_opts, term), do: {:ok, term}
    def handle_event(_, _, term), do: {:noreply, term}

    def render(assigns) do
      assigns =
        assign(assigns,
          data: Breeze.Charts.Docs.Previews.bar_chart_data(),
          series: Breeze.Charts.Docs.Previews.chart_series()
        )

      ~H"""
      <.bar_chart data={@data} series={@series} width={44} height={10} mode="grouped"/>
      """
    end
  end

  defmodule StackedBarChartPreview do
    use Breeze.View
    import Breeze.Charts

    def mount(_opts, term), do: {:ok, term}
    def handle_event(_, _, term), do: {:noreply, term}

    def render(assigns) do
      assigns =
        assign(assigns,
          data: Breeze.Charts.Docs.Previews.bar_chart_data(),
          series: Breeze.Charts.Docs.Previews.chart_series()
        )

      ~H"""
      <.bar_chart data={@data} series={@series} width={44} height={10} mode="stacked"/>
      """
    end
  end

  defmodule HorizontalGroupedBarChartPreview do
    use Breeze.View
    import Breeze.Charts

    def mount(_opts, term), do: {:ok, term}
    def handle_event(_, _, term), do: {:noreply, term}

    def render(assigns) do
      assigns =
        assign(assigns,
          data: Breeze.Charts.Docs.Previews.bar_chart_data(),
          series: Breeze.Charts.Docs.Previews.chart_series()
        )

      ~H"""
      <.bar_chart data={@data} series={@series} width={44} mode="grouped" orientation="horizontal"/>
      """
    end
  end

  defmodule HorizontalStackedBarChartPreview do
    use Breeze.View
    import Breeze.Charts

    def mount(_opts, term), do: {:ok, term}
    def handle_event(_, _, term), do: {:noreply, term}

    def render(assigns) do
      assigns =
        assign(assigns,
          data: Breeze.Charts.Docs.Previews.bar_chart_data(),
          series: Breeze.Charts.Docs.Previews.chart_series()
        )

      ~H"""
      <.bar_chart data={@data} series={@series} width={44} mode="stacked" orientation="horizontal"/>
      """
    end
  end

  def write! do
    options =
      Enum.map_join(@themes, "\n", fn {id, label} ->
        selected = if id == :gruvbox, do: " selected", else: ""
        ~s(<option value="#{id}"#{selected}>#{label}</option>)
      end)

    File.mkdir_p!(Path.dirname(@output))

    File.write!(@output, """
    # Chart previews

    These previews are generated from `Breeze.Charts` using Breeze's renderer.
    Change the theme to see how chart colors follow the application's palette.

    <div class="breeze-theme-picker">
      <label for="breeze-component-theme">Preview theme</label>
      <select id="breeze-component-theme" data-breeze-theme-select>#{options}</select>
    </div>

    ## Sparkline

    See `Breeze.Charts.sparkline/1` for attributes and scaling behavior.

    <div class="breeze-ansi" data-ansi-preview="true">
      <script type="application/json" class="breeze-ansi-sources">[#{sources(Sparkline, {36, 6})}]</script>
    </div>

    <a href="#" class="breeze-code-toggle" aria-expanded="false">Show code</a>

    ```elixir
    import Breeze.Charts

    # Automatic bounds
    <.sparkline values={[12, 18, 14, 24, 32, 28, 42, 36, 48, 40, 52, 44]} class="text-success" />

    # Fixed bounds shared across charts
    <.sparkline values={[10, 15, 20, 18, 35, 55, 70, 85, 60, 45, 30, 20]} min={0} max={100} />
    ```

    #{chart_section("Line chart", LineChartPreview, :line_chart, line_chart_data(), "min={0} max={500}")}
    #{chart_section("Grouped bars", GroupedBarChartPreview, :bar_chart, bar_chart_data(), ~s|mode="grouped"|)}
    #{chart_section("Stacked bars", StackedBarChartPreview, :bar_chart, bar_chart_data(), ~s|mode="stacked"|)}
    #{chart_section("Horizontal grouped bars", HorizontalGroupedBarChartPreview, :bar_chart, bar_chart_data(), ~s|mode="grouped" orientation="horizontal"|)}
    #{chart_section("Horizontal stacked bars", HorizontalStackedBarChartPreview, :bar_chart, bar_chart_data(), ~s|mode="stacked" orientation="horizontal"|)}

    Originally authored by [George Guimarães](https://github.com/georgeguimaraes)
    in [Breeze PR #57](https://github.com/Gazler/breeze/pull/57) and
    [Breeze PR #58](https://github.com/Gazler/breeze/pull/58).
    """)
  end

  defp chart_section(title, view, component, data, attrs) do
    """
    ## #{title}

    See `Breeze.Charts.#{component}/1` for attributes and scaling behavior.

    <div class="breeze-ansi" data-ansi-preview="true">
      <script type="application/json" class="breeze-ansi-sources">[#{sources(view, {44, 12})}]</script>
    </div>

    <a href="#" class="breeze-code-toggle" aria-expanded="false">Show code</a>

    ```elixir
    import Breeze.Charts

    data = #{inspect(data, pretty: true, limit: :infinity)}
    series = #{inspect(chart_series())}

    <.#{component} data={@data} series={@series} width={44} height={10} #{attrs} />
    ```
    """
  end

  defp sources(view, size) do
    Enum.map_join(@themes, ",", fn {id, _label} ->
      theme = Breeze.Theme.builtin(id)
      session = Breeze.Test.start!(view, size: size, theme: theme)

      content =
        try do
          session |> Breeze.Test.render!() |> Base.encode64()
        after
          Breeze.Test.stop(session)
        end

      # IDs and RGB colors are controlled values; ANSI content is base64 encoded.
      ~s({"theme":"#{id}","background":"#{color(theme, :background)}","foreground":"#{color(theme, :text)}","content":"#{content}"})
    end)
  end

  defp color(theme, name) do
    case Breeze.Theme.resolve_color(theme, name) do
      {red, green, blue} -> "rgb(#{red}, #{green}, #{blue})"
      "#" <> _ = color -> color
      _ -> "inherit"
    end
  end
end
