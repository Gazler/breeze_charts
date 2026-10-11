defmodule Breeze.Charts.Pie do
  @moduledoc false

  alias BackBreeze.TextSpan
  alias Breeze.Charts.Text

  import BackBreeze.Utils, only: [string_length: 1]

  @colors {:primary, :secondary, :success, :accent, :warning, :error}
  @braille_bits {{0x01, 0x08}, {0x02, 0x10}, {0x04, 0x20}, {0x40, 0x80}}
  @start_angle -:math.pi() / 2
  @finish_angle 3 * :math.pi() / 2

  def render(data, width, height, show_legend \\ true) do
    slices = normalize(data)
    validate_dimensions!(width, height)

    total = Enum.sum(Enum.map(slices, & &1.value))

    if slices == [] or total == 0 do
      []
    else
      slices = add_angles(slices, total)
      layout = layout(slices, width, height, show_legend)
      chart = rasterize(slices, layout.chart_width, layout.chart_height)
      legend = legend(slices, total, layout.legend_width, layout.legend_height)

      combine(chart, legend, layout, width, height)
    end
  end

  defp normalize(data) when is_list(data) do
    data
    |> Enum.with_index()
    |> Enum.map(fn
      {%{name: name, value: value} = slice, index}
      when is_binary(name) and is_number(value) and value >= 0 ->
        if Regex.match?(~r/[\x00-\x1f\x7f]/u, name) do
          raise ArgumentError, "pie_chart slice names must be single-line strings"
        end

        %{
          name: name,
          value: value,
          color: Map.get(slice, :color, elem(@colors, rem(index, tuple_size(@colors))))
        }

      _ ->
        raise ArgumentError,
              "pie_chart data must contain slices with a string :name and nonnegative numeric :value"
    end)
  end

  defp normalize(_data), do: raise(ArgumentError, "pie_chart data must be a list")

  defp validate_dimensions!(width, height) do
    unless is_integer(width) and width > 0 do
      raise ArgumentError, "pie_chart width must be a positive integer"
    end

    unless is_integer(height) and height > 0 do
      raise ArgumentError, "pie_chart height must be a positive integer"
    end
  end

  defp add_angles(slices, total) do
    {slices, _angle} =
      Enum.map_reduce(slices, @start_angle, fn slice, start_angle ->
        finish_angle = start_angle + slice.value / total * 2 * :math.pi()
        {Map.merge(slice, %{start_angle: start_angle, finish_angle: finish_angle}), finish_angle}
      end)

    slices
  end

  defp layout(_slices, width, height, false) do
    %{
      chart_width: width,
      chart_height: height,
      legend_width: 0,
      legend_height: 0,
      position: :none
    }
  end

  defp layout(slices, width, height, true) do
    wanted_legend_width =
      slices
      |> Enum.map(fn slice -> string_length(slice.name) + 9 end)
      |> Enum.max()
      |> min(max(width - 4, 0))

    if width >= 16 and height >= length(slices) and width - wanted_legend_width - 2 >= 4 do
      %{
        chart_width: width - wanted_legend_width - 2,
        chart_height: height,
        legend_width: wanted_legend_width,
        legend_height: height,
        position: :right
      }
    else
      legend_height = min(length(slices), max(height - 2, 0))

      %{
        chart_width: width,
        chart_height: height - legend_height,
        legend_width: width,
        legend_height: legend_height,
        position: :bottom
      }
    end
  end

  defp rasterize(_slices, width, height) when width <= 0 or height <= 0, do: []

  defp rasterize(slices, width, height) do
    diameter = min(width * 2, height * 4)
    radius = diameter / 2
    left = (width * 2 - diameter) / 2
    top = (height * 4 - diameter) / 2
    center_x = left + radius
    center_y = top + radius

    for row <- 0..(height - 1) do
      for column <- 0..(width - 1) do
        samples =
          for y <- 0..3, x <- 0..1 do
            sample(
              slices,
              column * 2 + x + 0.5,
              row * 4 + y + 0.5,
              center_x,
              center_y,
              radius
            )
          end

        cell(samples, slices)
      end
    end
  end

  defp sample(slices, x, y, center_x, center_y, radius) do
    dx = x - center_x
    dy = y - center_y

    if dx * dx + dy * dy <= radius * radius do
      angle = normalize_angle(:math.atan2(dy, dx))
      Enum.find_index(slices, &(angle < normalize_finish(&1.finish_angle))) || length(slices) - 1
    end
  end

  defp normalize_angle(angle) when angle < @start_angle, do: angle + 2 * :math.pi()
  defp normalize_angle(angle), do: angle

  defp normalize_finish(angle) when angle > @finish_angle, do: @finish_angle
  defp normalize_finish(angle), do: angle

  defp cell(samples, slices) do
    counts = Enum.frequencies(samples)
    outside = Map.get(counts, nil, 0)
    colored = counts |> Map.delete(nil) |> Enum.sort_by(fn {index, count} -> {-count, index} end)

    case colored do
      [] ->
        TextSpan.new(" ")

      [{index, 8}] ->
        TextSpan.new(" ", %{background_color: Enum.at(slices, index).color})

      [{index, _count} | _rest] when outside > 0 ->
        mask = mask(samples, index)
        TextSpan.new(<<0x2800 + mask::utf8>>, %{foreground_color: Enum.at(slices, index).color})

      [{background, _count}, {foreground, _count2} | _rest] ->
        mask = mask(samples, foreground)

        TextSpan.new(<<0x2800 + mask::utf8>>, %{
          foreground_color: Enum.at(slices, foreground).color,
          background_color: Enum.at(slices, background).color
        })

      [{index, _count}] ->
        TextSpan.new(" ", %{background_color: Enum.at(slices, index).color})
    end
  end

  defp mask(samples, selected) do
    samples
    |> Enum.with_index()
    |> Enum.reduce(0, fn
      {^selected, sample_index}, mask ->
        x = rem(sample_index, 2)
        y = div(sample_index, 2)
        Bitwise.bor(mask, elem(elem(@braille_bits, y), x))

      {_other, _sample_index}, mask ->
        mask
    end)
  end

  defp legend(_slices, _total, width, height) when width <= 0 or height <= 0, do: []

  defp legend(slices, total, width, height) do
    slices
    |> Enum.take(height)
    |> Enum.map(fn slice ->
      percentage = :erlang.float_to_binary(slice.value / total * 100, decimals: 1) <> "%"
      available = width - 1

      tail =
        if available >= string_length(percentage) + 2 do
          label_width = available - string_length(percentage) - 2
          label = Text.truncate(slice.name, label_width)
          gap = available - string_length(label) - string_length(percentage) - 1
          " " <> label <> String.duplicate(" ", gap) <> percentage
        else
          Text.truncate(" " <> percentage, available)
        end

      [TextSpan.new("■", %{foreground_color: slice.color})] ++
        if(tail == "", do: [], else: [TextSpan.new(tail, %{foreground_color: :text})])
    end)
  end

  defp combine(chart, _legend, %{position: :none}, width, height) do
    rows = Enum.map(chart, &pad_row(&1, width))
    rows_to_spans(rows, height)
  end

  defp combine(chart, legend, %{position: :right} = layout, width, height) do
    blank_legend = [TextSpan.new(String.duplicate(" ", layout.legend_width))]

    rows =
      for row <- 0..(height - 1) do
        chart_row = chart |> Enum.at(row, []) |> pad_row(layout.chart_width)
        legend_row = Enum.at(legend, row, blank_legend)
        chart_row ++ [TextSpan.new("  ")] ++ legend_row
      end

    rows_to_spans(Enum.map(rows, &pad_row(&1, width)), height)
  end

  defp combine(chart, legend, %{position: :bottom}, width, height) do
    rows = Enum.map(chart, &pad_row(&1, width)) ++ Enum.map(legend, &pad_row(&1, width))
    rows_to_spans(rows, height)
  end

  defp pad_row(spans, width) do
    used = Enum.reduce(spans, 0, fn span, count -> count + string_length(span.text) end)
    spans ++ [TextSpan.new(String.duplicate(" ", max(width - used, 0)))]
  end

  defp rows_to_spans(rows, height) do
    rows
    |> Enum.take(height)
    |> Enum.intersperse([TextSpan.new("\n")])
    |> List.flatten()
  end
end
