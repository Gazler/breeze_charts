# Breeze.Charts

Chart components for [Breeze](https://github.com/Gazler/breeze). Includes sparklines,
Braille line charts, and grouped or stacked bar charts in either orientation.

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
<.bar_chart data={@data} series={@series} width={50} height={12} />
<.bar_chart data={@data} series={@series} width={50} mode="stacked" orientation="horizontal" />
```

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

Browse the sparkline, line chart, and bar chart examples:

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
