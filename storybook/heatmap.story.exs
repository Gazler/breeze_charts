defmodule Breeze.Charts.Storybook.Heatmap do
  use Breeze.Storybook.Story
  import Breeze.Blocks, only: [scroll: 1]
  import Breeze.Charts

  def group, do: "Charts"

  def story do
    %{
      id: "heatmap",
      title: "Chart (Heat map)",
      description: "Illustrative UK temperatures by month and time of day.",
      notes: [
        "Blue represents the coldest values, followed by green, yellow, orange, and red.",
        "Columns cover January through December; rows cover eight periods of the day.",
        "The values are an illustrative seasonal profile in degrees Celsius, not observations from a specific weather station.",
        "The fixed -5–25°C range keeps colors comparable across every cell."
      ],
      source:
        ~s|<.heatmap data={@temperatures} row_labels={@times} column_labels={@months} colors={@colors} min={-5} max={25} />|
    }
  end

  def mount(_opts, term) do
    {:ok,
     assign(term,
       months: ~w(J F M A M J J A S O N D),
       times: ["Midnight", "Dawn", "Morning", "Midday", "Afternoon", "Evening", "Dusk", "Night"],
       colors: ["#2563EB", "#22C55E", "#FACC15", "#F97316", "#DC2626"],
       temperatures: [
         [-3, -2, -2, 4, 8, 11, 13, 13, 10, 7, -3, -2],
         [-2, -1, 1, 3, 7, 10, 12, 12, 9, 6, 2, -1],
         [1, 2, 4, 7, 11, 14, 16, 16, 13, 10, 6, 3],
         [5, 6, 8, 11, 15, 18, 20, 27, 17, 13, 9, 6],
         [6, 7, 9, 12, 16, 19, 25, 28, 18, 14, 10, 7],
         [3, 4, 6, 9, 13, 16, 18, 18, 15, 11, 7, 4],
         [2, 3, 5, 8, 12, 15, 17, 17, 14, 10, 6, 3],
         [-2, -3, 3, 6, 10, 13, 15, 15, 12, 9, 5, -2]
       ]
     )}
  end

  def render(assigns) do
    ~H"""
    <.scroll id="storybook-heatmap-scroll" class="w-full h-full bg-panel">
      <.heatmap
        data={@temperatures}
        row_labels={@times}
        column_labels={@months}
        colors={@colors}
        min={-5}
        max={25}
      />
    </.scroll>
    """
  end
end
