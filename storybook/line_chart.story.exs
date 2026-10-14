defmodule Breeze.Charts.Storybook.LineChart do
  use Breeze.Storybook.Story
  import Breeze.Blocks, only: [scroll: 1, checkbox: 1]
  import Breeze.Charts

  def group, do: "Charts"

  def story do
    %{
      id: "line-chart",
      title: "Chart (Line)",
      description: "Render connected lines or unconnected scatter points on shared axes.",
      variants: [
        %{
          id: "lines",
          label: "Lines",
          description: "Latency (Y, ms) over elapsed time (X, seconds).",
          source:
            ~s|<.line_chart data={@line_data} series={@series} width={44} height={10} min={@min} max={@max} />|
        },
        %{
          id: "points",
          label: "Scatter",
          description: "Individual observations positioned by numeric X and Y values.",
          notes: [
            "Points are not connected and numeric X values do not need to be sorted.",
            "The axes, bounds, colors, and legend are shared with line mode."
          ],
          source:
            ~s|<.line_chart data={@scatter_data} series={@series} width={44} height={10} display="points" />|
        }
      ],
      notes: [
        "Each data row has numeric x and values keyed by the series key.",
        "Series have a key and name. Colors are assigned automatically unless supplied.",
        "Toggle the checkbox to switch between automatic and fixed bounds.",
        "Braille dots share one color per terminal cell. Later series win at crossings.",
        "Width and height include the axes and legend. Scroll the preview on smaller terminals."
      ],
      source:
        ~s|<.line_chart data={@line_data} series={@series} width={44} height={10} min={@min} max={@max} />|
    }
  end

  def mount(_opts, term) do
    {:ok,
     term
     |> assign(
       fixed_scale: false,
       series: [
         %{key: :baseline, name: "Baseline"},
         %{key: :candidate, name: "Candidate"}
       ],
       line_data: [
         %{x: 0, values: %{baseline: 140, candidate: 180}},
         %{x: 1, values: %{baseline: 190, candidate: 150}},
         %{x: 2, values: %{baseline: 160, candidate: 170}},
         %{x: 3, values: %{baseline: 240, candidate: 160}},
         %{x: 4, values: %{baseline: 200, candidate: 130}},
         %{x: 5, values: %{baseline: 180, candidate: 150}},
         %{x: 6, values: %{baseline: 220, candidate: 120}}
       ],
       scatter_data: [
         %{x: 0.8, values: %{baseline: 185, candidate: 125}},
         %{x: 5.7, values: %{baseline: 225, candidate: 155}},
         %{x: 1.9, values: %{baseline: 145, candidate: 205}},
         %{x: 4.2, values: %{baseline: 195, candidate: 115}},
         %{x: 3.1, values: %{baseline: 235, candidate: 175}},
         %{x: 6.4, values: %{baseline: 165, candidate: 215}},
         %{x: 2.5, values: %{baseline: 205, candidate: 135}},
         %{x: 5.0, values: %{baseline: 135, candidate: 185}}
       ]
     )
     |> focus("storybook-line-chart-scale")}
  end

  def render(assigns) do
    display = if assigns[:__breeze_story_variant__] == "points", do: "points", else: "lines"
    data = if display == "points", do: assigns.scatter_data, else: assigns.line_data

    assigns =
      assign(assigns,
        data: data,
        display: display,
        min: if(assigns.fixed_scale, do: 0, else: nil),
        max: if(assigns.fixed_scale, do: 300, else: nil)
      )

    ~H"""
    <.scroll id="storybook-line-chart-scroll" class="w-full h-full bg-panel">
      <.checkbox
        id="storybook-line-chart-scale"
        checked={@fixed_scale}
        br-change="storybook_chart_scale_changed"
      >
        Fixed scale: 0–300 ms
      </.checkbox>
      <box class="pt-1">
        <.line_chart
          data={@data}
          series={@series}
          width={44}
          height={10}
          min={@min}
          max={@max}
          display={@display}
        />
      </box>
    </.scroll>
    """
  end

  def handle_event("storybook_chart_scale_changed", %{value: value}, term) do
    {:noreply, assign(term, fixed_scale: value)}
  end

  def handle_event(_, _, term), do: {:noreply, term}
end
