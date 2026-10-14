defmodule Breeze.Charts.HeatmapTest do
  use ExUnit.Case, async: true

  alias Breeze.Charts.Heatmap

  defmodule ChartView do
    use Breeze.View
    import Breeze.Charts

    def mount(opts, term), do: {:ok, assign(term, Map.new(opts))}

    def render(assigns) do
      ~H"""
      <.heatmap data={@data} row_labels={@row_labels} column_labels={@column_labels} min={0} max={100}/>
      """
    end
  end

  test "maps matrix values across an RGB gradient" do
    spans =
      Heatmap.render([[0, 50, 100]],
        min: 0,
        max: 100,
        low_color: {0, 0, 0},
        high_color: {200, 100, 50},
        show_scale: false
      )

    assert Enum.map(spans, & &1.style.background_color) == [
             {0, 0, 0},
             {100, 50, 25},
             {200, 100, 50}
           ]

    assert Enum.map(spans, & &1.text) == ["  ", "  ", "  "]
  end

  test "interpolates across multi-stop color scales" do
    spans =
      Heatmap.render([[0, 25, 50, 75, 100]],
        min: 0,
        max: 100,
        colors: [{0, 0, 255}, {0, 255, 0}, {255, 255, 0}, {255, 128, 0}, {255, 0, 0}],
        show_scale: false
      )

    assert Enum.map(spans, & &1.style.background_color) == [
             {0, 0, 255},
             {0, 255, 0},
             {255, 255, 0},
             {255, 128, 0},
             {255, 0, 0}
           ]
  end

  test "renders row and column labels with a bounded color scale" do
    spans =
      Heatmap.render([[0, 20], [80, 100]],
        row_labels: ["Mon", "Tue"],
        column_labels: ["00", "12"],
        min: 0,
        max: 100,
        low_color: {10, 20, 30},
        high_color: {110, 120, 130}
      )

    output = text(spans)
    assert output =~ "00"
    assert output =~ "12"
    assert output =~ "Mon"
    assert output =~ "Tue"
    assert output =~ "0 "
    assert output =~ " 100"
    assert length(String.split(output, "\n")) == 5
  end

  test "leaves missing values transparent and clamps values outside fixed bounds" do
    spans =
      Heatmap.render([[-10, nil, 150]],
        min: 0,
        max: 100,
        low_color: {0, 0, 0},
        high_color: {255, 255, 255},
        show_scale: false
      )

    assert Enum.at(spans, 0).style.background_color == {0, 0, 0}
    refute Map.has_key?(Enum.at(spans, 1).style, :background_color)
    assert Enum.at(spans, 2).style.background_color == {255, 255, 255}
  end

  test "supports constant and entirely missing matrices" do
    constant = Heatmap.render([[5]], show_scale: false)
    missing = Heatmap.render([[nil]], show_scale: false)

    assert constant |> hd() |> Map.fetch!(:style) |> Map.has_key?(:background_color)
    refute missing |> hd() |> Map.fetch!(:style) |> Map.has_key?(:background_color)
  end

  test "validates matrix shape, labels, values, bounds, and cell width" do
    for data <- [[], [[]], [[1], [1, 2]], [["bad"]]] do
      assert_raise ArgumentError, fn -> Heatmap.render(data) end
    end

    assert_raise ArgumentError, ~r/row_labels/, fn ->
      Heatmap.render([[1], [2]], row_labels: ["one"])
    end

    assert_raise ArgumentError, ~r/column_labels/, fn ->
      Heatmap.render([[1, 2]], column_labels: ["one\ntwo", "two"])
    end

    assert_raise ArgumentError, ~r/min must be below max/, fn ->
      Heatmap.render([[1]], min: 2, max: 2)
    end

    assert_raise ArgumentError, ~r/cell_width/, fn -> Heatmap.render([[1]], cell_width: 0) end

    assert_raise ArgumentError, ~r/at least two colors/, fn ->
      Heatmap.render([[1]], colors: [{0, 0, 0}])
    end
  end

  test "public component resolves theme colors and derives its dimensions" do
    session =
      Breeze.Test.start!(ChartView,
        size: {40, 15},
        theme: Breeze.Theme.builtin(:dracula),
        start_opts: [
          data: [[0, 50, 100], [20, 70, nil]],
          row_labels: ["Mon", "Tue"],
          column_labels: ["00", "12", "24"]
        ]
      )

    try do
      output = Breeze.Test.render!(session)
      assert output =~ "48;2;"
      assert Breeze.Test.render_text!(session) =~ "Mon"
    after
      Breeze.Test.stop(session)
    end
  end

  defp text(spans), do: Enum.map_join(spans, & &1.text)
end
