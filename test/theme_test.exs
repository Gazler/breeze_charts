defmodule Breeze.Charts.ThemeTest do
  use ExUnit.Case, async: true

  defmodule View do
    use Breeze.View
    import Breeze.Charts

    def mount(opts, term), do: {:ok, assign(term, Map.new(opts))}

    def render(%{chart: :line} = assigns) do
      ~H"""
      <.line_chart data={@data} series={@series} width={100} height={14}/>
      """
    end

    def render(assigns) do
      ~H"""
      <.bar_chart data={@data} series={@series} width={100} height={14} orientation={@chart}/>
      """
    end
  end

  test "cycles all six theme roles and preserves explicit colors" do
    series = Enum.map(1..7, &%{key: to_string(&1), name: "Series #{&1}"})
    {[], prepared} = Breeze.Charts.Data.prepare([], series)

    assert Enum.map(prepared, & &1.color) ==
             [:primary, :secondary, :success, :accent, :warning, :error, :primary]
  end

  test "charts resolve series, labels, and axes using the active theme" do
    roles = [:primary, :secondary, :success, :accent, :warning, :error]

    series =
      Enum.map(roles, &%{key: &1, name: Atom.to_string(&1)}) ++
        [
          %{key: :custom, name: "Custom", color: {12, 34, 56}},
          %{key: :index, name: "Index", color: 42},
          %{key: :named, name: "Named", color: :muted},
          %{key: :hex, name: "Hex", color: "#a1B2c3"},
          %{key: :short_hex, name: "Short", color: "#f8A"}
        ]

    values = series |> Enum.with_index(1) |> Map.new(fn {s, i} -> {s.key, i} end)
    data = [%{x: 0, values: values}, %{x: 1, values: values}]

    for chart <- [:line, "vertical", "horizontal"], name <- [:dracula, :nord] do
      theme = Breeze.Theme.builtin(name)

      session =
        Breeze.Test.start!(View,
          size: {110, 30},
          theme: theme,
          start_opts: [chart: chart, data: data, series: series]
        )

      try do
        output = Breeze.Test.render!(session)

        for role <- roles ++ [:text, :muted] do
          assert output =~ ansi(Breeze.Theme.resolve_color(theme, role))
        end

        if chart != "horizontal" do
          assert output =~ ansi(Breeze.Theme.resolve_color(theme, :border))
        end

        assert output =~ ansi({12, 34, 56})
        assert output =~ ansi(42)
        assert output =~ ansi({161, 178, 195})
        assert output =~ ansi({255, 136, 170})
      after
        Breeze.Test.stop(session)
      end
    end
  end

  test "legend labels use text color while markers retain the series color" do
    series = [%{key: :a, name: "Example", color: :success}]
    data = [%{x: 0, values: %{a: 1}}]

    for spans <- [
          Breeze.Charts.Line.render(data, series, 30, 8, []),
          Breeze.Charts.Bar.render_vertical(data, series, 30, 8, "grouped", nil),
          Breeze.Charts.Bar.render(data, series, 30, "grouped", nil)
        ] do
      assert Enum.any?(spans, &(&1.text in ["●", "■"] and &1.style.foreground_color == :success))
      assert Enum.any?(spans, &(&1.text =~ "Example" and &1.style[:foreground_color] == :text))
    end
  end

  defp ansi({r, g, b}), do: "38;2;#{r};#{g};#{b}"
  defp ansi(index), do: "38;5;#{index}"
end
