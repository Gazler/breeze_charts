defmodule Breeze.Charts.PieChartTest do
  use ExUnit.Case, async: true

  alias Breeze.Charts.Pie

  defmodule ChartView do
    use Breeze.View
    import Breeze.Charts

    def mount(opts, term), do: {:ok, assign(term, Map.new(opts))}

    def render(assigns) do
      ~H"""
      <.pie_chart data={@data} width={@width} height={@height} show_legend={@show_legend}/>
      """
    end
  end

  @data [
    %{name: "Mocha Marvels", value: 32.9, color: 1},
    %{name: "Caramel Swirls", value: 24.4, color: 2},
    %{name: "PB Bliss", value: 19.0, color: 3},
    %{name: "Choco Chippers", value: 9.0, color: 4},
    %{name: "Mint Melts", value: 7.4, color: 5},
    %{name: "Berry Bursts", value: 7.2, color: 6}
  ]

  test "rasterizes a circular pie with Braille edges and solid interiors" do
    spans = Pie.render(@data, 28, 12, false)
    rows = spans |> text() |> String.split("\n")

    assert length(rows) == 12
    assert Enum.all?(rows, &(BackBreeze.Utils.string_length(&1) == 28))
    assert Enum.any?(spans, &braille?/1)
    assert Enum.any?(spans, &Map.has_key?(&1.style, :background_color))

    colors =
      spans
      |> Enum.flat_map(fn span ->
        [span.style[:foreground_color], span.style[:background_color]]
      end)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    assert MapSet.subset?(MapSet.new(1..6), colors)
  end

  test "uses foreground and background together across internal slice boundaries" do
    spans =
      Pie.render(
        [
          %{name: "A", value: 37, color: :primary},
          %{name: "B", value: 63, color: :secondary}
        ],
        24,
        10,
        false
      )

    assert Enum.any?(spans, fn span ->
             braille?(span) and Map.has_key?(span.style, :foreground_color) and
               Map.has_key?(span.style, :background_color) and
               span.style.foreground_color != span.style.background_color
           end)
  end

  test "places a percentage legend to the right or below without exceeding dimensions" do
    wide = Pie.render(@data, 50, 12)
    narrow = Pie.render(@data, 18, 12)

    assert text(wide) =~ "Mocha Marvels"
    assert text(wide) =~ "32.9%"
    assert text(narrow) =~ "32.9%"

    for {spans, width, height} <- [{wide, 50, 12}, {narrow, 18, 12}] do
      rows = spans |> text() |> String.split("\n")
      assert length(rows) == height
      assert Enum.all?(rows, &(BackBreeze.Utils.string_length(&1) == width))
    end

    for width <- 1..12, height <- 1..8 do
      rows = Pie.render(@data, width, height) |> text() |> String.split("\n")
      assert length(rows) <= height
      assert Enum.all?(rows, &(BackBreeze.Utils.string_length(&1) <= width))
    end
  end

  test "empty and all-zero data render nothing" do
    assert Pie.render([], 20, 8) == []
    assert Pie.render([%{name: "Nothing", value: 0}], 20, 8) == []
  end

  test "validates slice data and dimensions" do
    assert_raise ArgumentError, ~r/data must be a list/, fn -> Pie.render(%{}, 20, 8) end

    assert_raise ArgumentError, ~r/string :name and nonnegative numeric :value/, fn ->
      Pie.render([%{name: "Bad", value: -1}], 20, 8)
    end

    assert_raise ArgumentError, ~r/single-line/, fn ->
      Pie.render([%{name: "Bad\nname", value: 1}], 20, 8)
    end

    assert_raise ArgumentError, ~r/width must be a positive integer/, fn ->
      Pie.render([], 0, 8)
    end

    assert_raise ArgumentError, ~r/height must be a positive integer/, fn ->
      Pie.render([], 20, 0)
    end
  end

  test "public component resolves foreground and background slice colors" do
    theme = Breeze.Theme.builtin(:dracula)

    session =
      Breeze.Test.start!(ChartView,
        size: {40, 16},
        theme: theme,
        start_opts: [
          data: [
            %{name: "A", value: 37, color: :primary},
            %{name: "B", value: 63, color: :secondary}
          ],
          width: 30,
          height: 10,
          show_legend: false
        ]
      )

    try do
      output = Breeze.Test.render!(session)
      assert output =~ "38;"
      assert output =~ "48;"
    after
      Breeze.Test.stop(session)
    end
  end

  defp text(spans), do: Enum.map_join(spans, & &1.text)

  defp braille?(span) do
    case String.to_charlist(span.text) do
      [code] -> code > 0x2800 and code <= 0x28FF
      _ -> false
    end
  end
end
