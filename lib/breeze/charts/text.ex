defmodule Breeze.Charts.Text do
  @moduledoc false

  def legend_spans("", _color), do: []

  def legend_spans(text, color) do
    {marker, label} = String.split_at(text, 1)

    [
      BackBreeze.TextSpan.new(marker, %{foreground_color: color}),
      BackBreeze.TextSpan.new(label, %{foreground_color: :text})
    ]
  end

  def truncate(text, width) do
    {graphemes, _remaining} =
      text
      |> String.graphemes()
      |> Enum.reduce_while({[], width}, fn grapheme, {graphemes, remaining} ->
        size = BackBreeze.Utils.string_length(grapheme)

        if size <= remaining do
          {:cont, {[grapheme | graphemes], remaining - size}}
        else
          {:halt, {graphemes, remaining}}
        end
      end)

    graphemes |> Enum.reverse() |> IO.iodata_to_binary()
  end
end
