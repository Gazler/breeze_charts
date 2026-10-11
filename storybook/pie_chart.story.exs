defmodule Breeze.Charts.Storybook.PieChart do
  use Breeze.Storybook.Story
  import Breeze.Blocks, only: [scroll: 1]
  import Breeze.Charts

  def group, do: "Charts"

  def story do
    %{
      id: "pie-chart",
      title: "Chart (Pie)",
      description: "Compare pie-chart density and size across terminal layouts.",
      variants: [
        %{
          id: "few-segments",
          label: "Few segments",
          description: "Four broad slices with clearly visible boundaries.",
          source: ~s|<.pie_chart data={@few_segments} width={52} height={14} />|
        },
        %{
          id: "many-segments",
          label: "Many segments",
          description: "Eighteen slices demonstrate how thin segments rasterize.",
          source: ~s|<.pie_chart data={@many_segments} width={62} height={18} />|
        },
        %{
          id: "small",
          label: "Small chart",
          description: "A compact pie without a legend, using the full component area.",
          source:
            ~s|<.pie_chart data={@few_segments} width={20} height={8} show_legend={false} />|
        },
        %{
          id: "large",
          label: "Large chart",
          description: "A larger chart gives curved edges and narrow slices more resolution.",
          source: ~s|<.pie_chart data={@market_share} width={76} height={24} />|
        }
      ],
      notes: [
        "The chart samples eight subpixels per terminal cell using Unicode Braille.",
        "Foreground and background colors preserve both slices along shared boundaries.",
        "The legend moves below the chart when there is not enough horizontal space.",
        "Very thin segments need a larger chart to remain visually distinct."
      ],
      source: ~s|<.pie_chart data={@few_segments} width={52} height={14} />|
    }
  end

  def mount(_opts, term) do
    many_values = [18, 15, 12, 10, 8, 7, 6, 5, 4, 3, 3, 2, 2, 1.5, 1.5, 1, 0.7, 0.3]

    {:ok,
     assign(term,
       few_segments: [
         %{name: "Desktop", value: 48},
         %{name: "Mobile", value: 31},
         %{name: "Tablet", value: 14},
         %{name: "Other", value: 7}
       ],
       many_segments:
         many_values
         |> Enum.with_index(1)
         |> Enum.map(fn {value, index} -> %{name: "Segment #{index}", value: value} end),
       market_share: [
         %{name: "Mocha Marvels", value: 32.9},
         %{name: "Caramel Swirls", value: 24.4},
         %{name: "PB Bliss", value: 19.0},
         %{name: "Choco Chippers", value: 9.0},
         %{name: "Mint Melts", value: 7.4},
         %{name: "Berry Bursts", value: 7.2}
       ]
     )}
  end

  def render(assigns) do
    {data, width, height, show_legend} =
      case assigns[:__breeze_story_variant__] do
        "many-segments" -> {assigns.many_segments, 62, 18, true}
        "small" -> {assigns.few_segments, 20, 8, false}
        "large" -> {assigns.market_share, 76, 24, true}
        _ -> {assigns.few_segments, 52, 14, true}
      end

    assigns =
      assign(assigns,
        data: data,
        width: width,
        height: height,
        show_legend: show_legend
      )

    ~H"""
    <.scroll id="storybook-pie-chart-scroll" class="w-full h-full bg-panel">
      <.pie_chart data={@data} width={@width} height={@height} show_legend={@show_legend}/>
    </.scroll>
    """
  end
end
