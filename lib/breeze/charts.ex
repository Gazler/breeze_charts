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

  defp class_override(assigns) do
    cond do
      is_binary(assigns[:class]) -> assigns[:class]
      is_binary(assigns[:style]) -> assigns[:style]
      true -> nil
    end
  end
end
