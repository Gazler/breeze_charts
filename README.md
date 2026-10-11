# Breeze.Charts

Chart components for [Breeze](https://github.com/Gazler/breeze). Includes sparklines,
Braille line charts, proportional pie charts, color heat maps, and grouped or
stacked bar charts in either orientation.

## Usage

Add `breeze_charts` to your dependencies in `mix.exs`:

```elixir
{:breeze_charts, "~> 0.1.0"}
```

Import the components in your view:

```elixir
defmodule Dashboard do
  use Breeze.View
  import Breeze.Charts

  def render(assigns) do
    ~H"""
    <.sparkline values={[2, 4, 3, 8, 6]} class="text-success" />
    <.sparkline values={[10, 35, 70, 55]} min={0} max={100} />
    """
  end
end
```

Empty data renders no bars. Constant values render `▁`. Values outside fixed
bounds are clamped. Width defaults to the number of values; a narrower `class`
clips the chart without resampling it. Existing `class` and `style` overrides
are supported.

Line and bar charts share keyed data and series definitions:

```elixir
data = [
  %{x: "Run A", values: %{input: 420, output: 180}},
  %{x: "Run B", values: %{input: 610, output: 240}}
]

series = [%{key: :input, name: "Input"}, %{key: :output, name: "Output"}]
```

Assign these to your view, then render:

```heex
<.line_chart data={@data} series={@series} width={50} height={12} min={0} />
<.line_chart data={@samples} series={@series} width={50} height={12} display="points" />
<.bar_chart data={@data} series={@series} width={50} height={12} />
<.bar_chart data={@data} series={@series} width={50} mode="stacked" orientation="horizontal" />
```

Set `display="points"` on a line chart to render a scatter plot using the same
Braille canvas, numeric axes, bounds, series colors, and legend. Points are not
connected, and numeric X values may be supplied in any order in this mode.

Heat maps render numeric matrices as color intensity. Two terminal columns are
used for each value by default so cells appear approximately square:

```heex
<.heatmap
  data={@request_counts}
  row_labels={["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]}
  column_labels={["00", "04", "08", "12", "16", "20"]}
  low_color={:surface}
  high_color={:primary}
  min={0}
  max={1000}
/>
```

Rows must have equal lengths. Values may be numbers or `nil`; missing values are
left transparent. Bounds are inferred when `min` and `max` are omitted.

For multi-stop scales, pass two or more colors instead of `low_color` and
`high_color`:

```heex
<.heatmap
  data={@temperatures}
  row_labels={@times}
  column_labels={@months}
  colors={["#2563EB", "#22C55E", "#FACC15", "#F97316", "#DC2626"]}
  min={-5}
  max={25}
/>
```

Pie charts use a simpler list of named slices:

```elixir
pie_data = [
  %{name: "Mocha Marvels", value: 32.9},
  %{name: "Caramel Swirls", value: 24.4},
  %{name: "PB Bliss", value: 19.0},
  %{name: "Choco Chippers", value: 9.0},
  %{name: "Mint Melts", value: 7.4},
  %{name: "Berry Bursts", value: 7.2}
]
```

```heex
<.pie_chart data={@pie_data} width={52} height={14} />
```

Pie charts use eight Braille subpixels per terminal cell and combine foreground
and background colors at slice boundaries. This keeps curved edges smooth while
preserving the colors on both sides of a boundary. The legend moves below the
chart when it cannot fit to the right; set `show_legend={false}` to devote the
entire component area to the pie.

Series colors cycle through the active theme’s primary, secondary, success,
accent, warning, and error colors. Override them with `:color` using a theme
color name, terminal color index, RGB tuple, or hex string:

```elixir
series = [
  %{key: :input, name: "Input", color: "#4DA3FF"},
  %{key: :output, name: "Output", color: "#f8a"}
]
```

Labels and legend text use the theme’s text color; axes use its border color.
Legend markers retain their series colors. See the component API docs for
bounds, sizing, and clipping behavior.

Run the interactive example from this checkout:

```sh
mix deps.get
mix run examples/sparkline.exs
```

For live line and bar charts using the same changing data:

```sh
mix run examples/charts.exs
```

## Storybook

Browse the sparkline, line chart, bar chart, heat-map, and pie chart examples:

```sh
mix breeze.storybook
```

## Documentation

Build the API reference and rendered chart previews with:

```sh
mix docs
```

## Credits

The sparkline component, its original tests, and the example content were
created by **[George Guimarães](https://github.com/georgeguimaraes)** in
[Breeze PR #57](https://github.com/Gazler/breeze/pull/57), commit
[`9f16c3e`](https://github.com/Gazler/breeze/commit/9f16c3e194f78ac5a645fb38b9953a4440ffe7c8).

The line and bar charts, their original tests, and story examples were also
created by **George Guimarães** in
[Breeze PR #58](https://github.com/Gazler/breeze/pull/58).

Licensed under the MIT license. See [LICENCE.md](LICENCE.md).
