defmodule Breeze.Charts.Heatmap do
  @moduledoc false

  alias BackBreeze.TextSpan
  alias Breeze.Charts.Text

  import BackBreeze.Utils, only: [string_length: 1]

  @scale_steps 8

  def render(data, options \\ []) do
    {rows, columns} = validate_data!(data)
    row_labels = validate_labels!(options[:row_labels] || [], rows, "row")
    column_labels = validate_labels!(options[:column_labels] || [], columns, "column")
    cell_width = options[:cell_width] || 2

    unless is_integer(cell_width) and cell_width > 0 do
      raise ArgumentError, "heatmap cell_width must be a positive integer"
    end

    {minimum, maximum} = bounds(data, options[:min], options[:max])

    colors =
      options[:colors] ||
        [options[:low_color] || {40, 42, 54}, options[:high_color] || {139, 233, 253}]

    unless is_list(colors) and length(colors) >= 2 do
      raise ArgumentError, "heatmap colors must contain at least two colors"
    end

    show_scale = Keyword.get(options, :show_scale, true)

    label_width =
      if row_labels == [], do: 0, else: row_labels |> Enum.map(&string_length/1) |> Enum.max()

    prefix_width = label_width + if(row_labels == [], do: 0, else: 1)

    header =
      if column_labels == [] do
        []
      else
        [
          [TextSpan.new(String.duplicate(" ", prefix_width))] ++
            Enum.map(column_labels, fn label ->
              TextSpan.new(center(Text.truncate(label, cell_width), cell_width), %{
                foreground_color: :text
              })
            end)
        ]
      end

    cells =
      data
      |> Enum.with_index()
      |> Enum.map(fn {values, row} ->
        label = if row_labels == [], do: "", else: Enum.at(row_labels, row)

        label_spans =
          if row_labels == [] do
            []
          else
            [
              TextSpan.new(pad_leading(label, label_width) <> " ", %{
                foreground_color: :text
              })
            ]
          end

        label_spans ++
          Enum.map(values, fn
            nil ->
              TextSpan.new(String.duplicate(" ", cell_width))

            value ->
              weight =
                if minimum == maximum, do: 0.5, else: (value - minimum) / (maximum - minimum)

              TextSpan.new(String.duplicate(" ", cell_width), %{
                background_color: scale_color(colors, weight)
              })
          end)
      end)

    scale =
      if show_scale do
        scale_row(minimum, maximum, colors, prefix_width)
      else
        []
      end

    join_rows(header ++ cells ++ scale)
  end

  defp validate_data!(data) when is_list(data) and data != [] do
    unless Enum.all?(data, &(is_list(&1) and &1 != [])) do
      raise ArgumentError, "heatmap data must be a nonempty list of nonempty rows"
    end

    columns = data |> hd() |> length()

    unless Enum.all?(data, &(length(&1) == columns)) do
      raise ArgumentError, "heatmap rows must all have the same length"
    end

    unless Enum.all?(List.flatten(data), &(is_nil(&1) or is_number(&1))) do
      raise ArgumentError, "heatmap values must be numbers or nil"
    end

    {length(data), columns}
  end

  defp validate_data!(_data),
    do: raise(ArgumentError, "heatmap data must be a nonempty list of nonempty rows")

  defp validate_labels!([], _expected, _kind), do: []

  defp validate_labels!(labels, expected, kind) when is_list(labels) do
    unless length(labels) == expected and Enum.all?(labels, &label?/1) do
      raise ArgumentError,
            "heatmap #{kind}_labels must contain one single-line string per #{kind}"
    end

    labels
  end

  defp validate_labels!(_labels, _expected, kind),
    do: raise(ArgumentError, "heatmap #{kind}_labels must be a list")

  defp label?(label),
    do: is_binary(label) and not Regex.match?(~r/[\x00-\x1f\x7f]/u, label)

  defp bounds(data, minimum, maximum) do
    unless (is_nil(minimum) or is_number(minimum)) and (is_nil(maximum) or is_number(maximum)) do
      raise ArgumentError, "heatmap min and max must be numeric"
    end

    if minimum != nil and maximum != nil and minimum >= maximum do
      raise ArgumentError, "heatmap min must be below max"
    end

    values = data |> List.flatten() |> Enum.reject(&is_nil/1)
    inferred_minimum = Enum.min(values, fn -> 0 end)
    inferred_maximum = Enum.max(values, fn -> 1 end)
    minimum = minimum || min(inferred_minimum, maximum || inferred_minimum)
    maximum = maximum || max(inferred_maximum, minimum)
    {minimum, maximum}
  end

  defp scale_row(minimum, maximum, colors, prefix_width) do
    gradient =
      for step <- 0..(@scale_steps - 1) do
        TextSpan.new("  ", %{
          background_color: scale_color(colors, step / (@scale_steps - 1))
        })
      end

    [
      [TextSpan.new(String.duplicate(" ", prefix_width))],
      [TextSpan.new(String.duplicate(" ", prefix_width) <> format(minimum) <> " ")] ++
        gradient ++ [TextSpan.new(" " <> format(maximum), %{foreground_color: :text})]
    ]
  end

  defp blend({lr, lg, lb}, {hr, hg, hb}, weight) do
    weight = max(0.0, min(weight * 1.0, 1.0))

    {
      round(lr + (hr - lr) * weight),
      round(lg + (hg - lg) * weight),
      round(lb + (hb - lb) * weight)
    }
  end

  defp blend(low_color, high_color, weight), do: if(weight < 0.5, do: low_color, else: high_color)

  defp scale_color(colors, weight) do
    weight = max(0.0, min(weight * 1.0, 1.0))
    segments = length(colors) - 1
    position = weight * segments
    index = min(trunc(position), segments - 1)
    blend(Enum.at(colors, index), Enum.at(colors, index + 1), position - index)
  end

  defp center(text, width) do
    padding = width - string_length(text)
    left = div(padding, 2)
    String.duplicate(" ", left) <> text <> String.duplicate(" ", padding - left)
  end

  defp pad_leading(text, width) do
    String.duplicate(" ", max(width - string_length(text), 0)) <> text
  end

  defp format(value) when is_integer(value), do: Integer.to_string(value)
  defp format(value), do: Float.to_string(value)

  defp join_rows(rows), do: rows |> Enum.intersperse([TextSpan.new("\n")]) |> List.flatten()
end
