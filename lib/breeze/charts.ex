defmodule Breeze.Charts do
  @moduledoc """
  Chart components for Breeze terminal applications.

  Import this module in a view to use its components:

      defmodule Dashboard do
        use Breeze.View
        import Breeze.Charts

        def render(assigns) do
          ~H"<.sparkline values={[2, 4, 3, 8, 6]} />"
        end
      end

  The sparkline component was originally authored by George Guimarães in
  [Breeze PR #57](https://github.com/Gazler/breeze/pull/57).
  The line and bar charts were authored by George in
  [Breeze PR #58](https://github.com/Gazler/breeze/pull/58).
  """

  use Breeze.Component

  @doc """
  Renders a one-row chart with one Unicode bar per numeric value.

  Values are scaled from the smallest (`▁`) to the largest (`█`). Set `min`
  and `max` to share a scale across charts. Values outside those bounds are
  clamped. An empty list renders no bars, and a constant range renders `▁`.
  Changing values or bounds recalculates the bars on the next render.

  The default width is the number of values. A narrower `class` clips the
  right edge without resampling. Colors use the usual `class` and `style`
  attributes.

      <.sparkline values={[2, 4, 3, 8, 6]} class="text-success" />
      <.sparkline values={@cpu_history} min={0} max={100} />
  """
  attr :values, :list, required: true
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :class, :string, default: nil
  attr :style, :any, default: nil
  attr :rest, :global

  def sparkline(assigns) do
    assigns =
      assign(assigns,
        content: sparkline_content(assigns.values, assigns.min, assigns.max),
        class:
          Breeze.Blocks.merge_class(
            "w-#{max(length(assigns.values), 1)} h-1 overflow-hidden text-primary",
            class_override(assigns)
          )
      )

    ~H"""
    <box class={@class} style={Breeze.Blocks.inline_style(assigns)} {@rest}>{@content}</box>
    """
  end

  @doc """
  Renders multiple series as a Braille line chart with shared axes and a legend.

  Uses the same `data` and `series` inputs as `bar_chart/1`. Each data row has
  `:x` and a `:values` map keyed by series. Each series has `:key`, `:name`, and
  an optional `:color` (a theme color, terminal color index, RGB tuple, or
  `"#RGB"` / `"#RRGGBB"` hex string).
  Colors default to `:primary`, `:secondary`, `:success`, `:accent`, `:warning`,
  and `:error` from the active theme, cycling in series order. Set colors
  explicitly to keep them stable across charts with different series orders.

      data = [
        %{x: 1, values: %{input: 420, output: 180}},
        %{x: 2, values: %{input: 610, output: 240}}
      ]

      series = [%{key: :input, name: "Input"}, %{key: :output, name: "Output"}]

  Numeric X values must be nondecreasing. String X values are equally spaced
  categories in data order. Don't mix numeric and string X values. Each row must
  supply a numeric value for every selected series key. Extra keys are ignored.

  `min` and `max` set fixed value bounds. `x_min` and `x_max` set fixed numeric X
  bounds, and aren't supported for string categories. Otherwise bounds are
  inferred across all selected series. Lines are clipped to the visible domain.
  Data, bounds, and dimensions are recalculated on every render.

  `width` and `height` include axes and legend. Supply new dimensions to reproject
  on resize. Overriding the box size with classes only clips the existing plot.
  A terminal cell has one foreground color, so the last series sets the color
  wherever Braille dots from multiple series share a cell.

      <.line_chart data={@data} series={@series} width={50} height={12} min={0} />
  """
  attr :data, :list, required: true
  attr :series, :list, required: true
  attr :width, :integer, required: true
  attr :height, :integer, default: 12
  attr :x_min, :any, default: nil
  attr :x_max, :any, default: nil
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :class, :string, default: nil
  attr :style, :any, default: nil
  attr :rest, :global

  def line_chart(assigns) do
    assigns =
      assign(assigns,
        content:
          Breeze.Charts.Line.render(
            assigns.data,
            assigns.series,
            assigns.width,
            assigns.height,
            assigns
          )
          |> resolve_colors(assigns),
        class:
          Breeze.Blocks.merge_class(
            "w-#{assigns.width} h-#{assigns.height} overflow-hidden",
            class_override(assigns)
          )
      )

    ~H"""
    <box class={@class} style={Breeze.Blocks.inline_style(assigns)} {@rest}>{@content}</box>
    """
  end

  @doc """
  Renders grouped or stacked bars with a shared zero baseline.

  Uses the same `data` and `series` inputs as `line_chart/1`:

      data = [
        %{x: "Run A", values: %{input: 420, output: 180}},
        %{x: "Run B", values: %{input: 610, output: 240}}
      ]

      series = [%{key: :input, name: "Input"}, %{key: :output, name: "Output"}]

  `:x` supplies each category label and `:values` keeps its measurements together.
  Series keys select values by name, so reordering data or series can't attach a
  measurement to the wrong label. Every selected key must be present. Extra keys
  are ignored. Bar values must be nonnegative numbers. An optional series `:color`
  overrides the default theme color described in `line_chart/1`.

  Grouped mode scales against the
  largest individual value. Stacked mode scales against the largest category sum.
  Set a positive `max` for a fixed scale. Values beyond it are visually clipped,
  with a shared numeric Y axis for vertical bars. Horizontal bars label actual
  values or totals, omitting value labels when they cannot fit without truncation.

  Vertical bars place categories along X and values along Y. `width` and `height`
  include axes and legend. Set `orientation="horizontal"` for horizontal bars,
  whose height follows the data and legend instead. Grouped bars use eighth-cell
  ends. Stacked segment boundaries are rounded cumulatively to whole cells, so
  tiny segments may disappear. Data, mode, maximum, and dimensions update on rerender.

      <.bar_chart data={@data} series={@series} mode="stacked" width={50} />
      <.bar_chart data={@data} series={@series} orientation="horizontal" width={50} />
  """
  attr :data, :list, required: true
  attr :series, :list, required: true
  attr :width, :integer, required: true
  attr :height, :integer, default: 12
  attr :orientation, :string, default: "vertical", values: ["vertical", "horizontal"]
  attr :mode, :string, default: "grouped", values: ["grouped", "stacked"]
  attr :max, :any, default: nil
  attr :class, :string, default: nil
  attr :style, :any, default: nil
  attr :rest, :global

  def bar_chart(assigns) do
    content =
      case assigns.orientation do
        "vertical" ->
          Breeze.Charts.Bar.render_vertical(
            assigns.data,
            assigns.series,
            assigns.width,
            assigns.height,
            assigns.mode,
            assigns.max
          )

        "horizontal" ->
          Breeze.Charts.Bar.render(
            assigns.data,
            assigns.series,
            assigns.width,
            assigns.mode,
            assigns.max
          )
      end

    height =
      if assigns.orientation == "vertical" do
        assigns.height
      else
        content |> Enum.map_join(& &1.text) |> String.split("\n") |> length()
      end

    assigns =
      assign(assigns,
        content: resolve_colors(content, assigns),
        class:
          Breeze.Blocks.merge_class(
            "w-#{assigns.width} h-#{height} overflow-hidden",
            class_override(assigns)
          )
      )

    ~H"""
    <box class={@class} style={Breeze.Blocks.inline_style(assigns)} {@rest}>{@content}</box>
    """
  end

  defp sparkline_content([], _minimum, _maximum), do: ""

  defp sparkline_content(values, minimum, maximum) do
    {data_min, data_max} = Enum.min_max(values)
    minimum = minimum || min(data_min, maximum || data_min)
    maximum = maximum || max(data_max, minimum)

    if minimum > maximum do
      raise ArgumentError, "sparkline min must be less than or equal to max"
    end

    bars = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}

    Enum.map_join(values, fn value ->
      index =
        if minimum == maximum do
          0
        else
          value = value |> max(minimum) |> min(maximum)
          round((value - minimum) / (maximum - minimum) * 7)
        end

      elem(bars, index)
    end)
  end

  defp resolve_colors(spans, assigns) do
    theme = get_in(assigns, [:__breeze_caller_assigns__, :breeze, :__render_theme__])

    Enum.map(spans, fn span ->
      color = Map.get(span.style, :foreground_color, :text)
      style = Map.put(span.style, :foreground_color, Breeze.Theme.resolve_color(theme, color))
      %{span | style: style}
    end)
  end

  defp class_override(assigns) do
    cond do
      is_binary(assigns[:class]) -> assigns[:class]
      is_binary(assigns[:style]) -> assigns[:style]
      true -> nil
    end
  end
end
