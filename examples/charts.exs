defmodule Breeze.Charts.Examples.Charts do
  use Breeze.View
  import Breeze.Blocks, only: [scroll: 1]
  import Breeze.Charts

  def mount(_opts, term) do
    Process.send_after(self(), :tick, 500)

    {:ok,
     assign(term,
       chart: :line,
       mode: "grouped",
       orientation: "vertical",
       paused: false,
       fixed_scale: false,
       samples: 6,
       series: [%{key: :input, name: "Input"}, %{key: :output, name: "Output"}],
       data: [
         %{x: 1, values: %{input: 42, output: 18}},
         %{x: 2, values: %{input: 61, output: 24}},
         %{x: 3, values: %{input: 35, output: 21}},
         %{x: 4, values: %{input: 52, output: 32}},
         %{x: 5, values: %{input: 48, output: 27}},
         %{x: 6, values: %{input: 65, output: 38}}
       ]
     )}
  end

  def handle_info(:tick, term) do
    Process.send_after(self(), :tick, 500)

    if term.assigns.paused do
      {:noreply, term}
    else
      previous = List.last(term.assigns.data).values
      samples = term.assigns.samples + 1

      next = %{
        x: samples,
        values: %{input: advance(previous.input), output: advance(previous.output)}
      }

      {:noreply, assign(term, data: tl(term.assigns.data) ++ [next], samples: samples)}
    end
  end

  def handle_event("line", _, term), do: {:noreply, assign(term, chart: :line)}
  def handle_event("bar", _, term), do: {:noreply, assign(term, chart: :bar)}
  def handle_event("pause", _, term), do: {:noreply, assign(term, paused: !term.assigns.paused)}

  def handle_event("scale", _, term),
    do: {:noreply, assign(term, fixed_scale: !term.assigns.fixed_scale)}

  def handle_event("mode", _, term) do
    mode = if term.assigns.mode == "grouped", do: "stacked", else: "grouped"
    {:noreply, assign(term, chart: :bar, mode: mode)}
  end

  def handle_event("orientation", _, term) do
    orientation = if term.assigns.orientation == "vertical", do: "horizontal", else: "vertical"
    {:noreply, assign(term, chart: :bar, orientation: orientation)}
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        width: max(assigns.breeze.terminal.width - 4, 1),
        height: max(assigns.breeze.terminal.height - 7, 4),
        maximum: if(assigns.fixed_scale, do: 200, else: nil)
      )

    ~H"""
    <box class="w-full h-full bg-panel">
      <box class="bold text-primary">
        Live charts · sample {@samples} · {if @paused do
          "Paused"
        else
          "Running"
        end}
      </box>
      <box>l Line · b Bar · m Grouped/stacked · o Orientation</box>
      <box>p Pause · s Scale · t Theme · q Quit</box>
      <box class="text-muted">
        {@chart} · {@mode} · {@orientation} · {if @fixed_scale do
          "Fixed 0–200"
        else
          "Automatic scale"
        end}
      </box>
      <.scroll id="chart" class="w-full grow">
        <.line_chart
          :if={@chart == :line}
          data={@data}
          series={@series}
          width={@width}
          height={@height}
          min={0}
          max={@maximum}
        />
        <.bar_chart
          :if={@chart == :bar}
          data={@data}
          series={@series}
          width={@width}
          height={@height}
          mode={@mode}
          orientation={@orientation}
          max={@maximum}
        />
      </.scroll>
    </box>
    """
  end

  defp advance(value), do: value |> Kernel.+(:rand.uniform(31) - 16) |> max(0) |> min(100)
end

Breeze.Server.run(
  view: Breeze.Charts.Examples.Charts,
  theme: Breeze.Theme.builtin(:gruvbox),
  global_keybindings:
    Enum.map(
      [
        {"l", "line"},
        {"b", "bar"},
        {"m", "mode"},
        {"o", "orientation"},
        {"p", "pause"},
        {"s", "scale"}
      ],
      fn {key, event} ->
        {key, event,
         fn _, term -> Breeze.Charts.Examples.Charts.handle_event(event, %{}, term) end}
      end
    ) ++
      [{"t", "Theme", &Breeze.View.cycle_theme/2}, {"q", "Quit", fn _, term -> {:stop, term} end}]
)
