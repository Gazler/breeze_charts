defmodule Breeze.Charts.Examples.Sparkline do
  use Breeze.View
  import Breeze.Charts

  def mount(_opts, term) do
    Process.send_after(self(), :tick, 500)

    {:ok,
     assign(term,
       throughput: [12, 18, 14, 24, 32, 28, 42, 36, 48, 40, 52, 44],
       cpu: [10, 15, 20, 18, 35, 55, 70, 85, 60, 45, 30, 20],
       memory: [40, 42, 43, 45, 48, 50, 52, 55, 58, 60, 62, 65]
     )}
  end

  def handle_info(:tick, term) do
    Process.send_after(self(), :tick, 500)

    {:noreply,
     assign(term,
       throughput: advance(term.assigns.throughput, 20),
       cpu: advance(term.assigns.cpu, 15),
       memory: advance(term.assigns.memory, 5)
     )}
  end

  defp advance(values, step) do
    next = List.last(values) + :rand.uniform(2 * step + 1) - step - 1
    tl(values) ++ [next |> max(0) |> min(100)]
  end

  def render(assigns) do
    ~H"""
    <box class="w-full h-full bg-panel">
      <box class="text-muted">Updates every 500 ms. Press q to quit.</box>
      <box class="bold">Automatic scale</box>
      <box class="inline w-full">
        <box class="w-14">Throughput</box>
        <.sparkline values={@throughput} class="text-success"/>
      </box>
      <box class="bold pt-1">Shared scale: 0–100%</box>
      <box class="inline w-full">
        <box class="w-14">CPU</box>
        <.sparkline values={@cpu} min={0} max={100}/>
      </box>
      <box class="inline w-full">
        <box class="w-14">Memory</box>
        <.sparkline values={@memory} min={0} max={100} class="text-accent"/>
      </box>
    </box>
    """
  end
end

Breeze.Server.run(
  view: Breeze.Charts.Examples.Sparkline,
  global_keybindings: [{"q", "Quit", fn _, term -> {:stop, term} end}]
)
