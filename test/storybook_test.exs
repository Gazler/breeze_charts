defmodule Breeze.Charts.StorybookTest do
  use ExUnit.Case, async: true

  for file <- ["line_chart.story.exs", "bar_chart.story.exs"] do
    Code.require_file(Path.expand("../storybook/#{file}", __DIR__))
  end

  test "storybook discovers and renders the extracted sparkline" do
    session =
      Breeze.Test.start!(Breeze.Storybook,
        size: {90, 30},
        start_opts: [directory: Path.expand("../storybook", __DIR__), file: "sparkline.story.exs"]
      )

    on_exit(fn -> Breeze.Test.stop(session) end)
    output = Breeze.Test.render_text!(session)

    assert output =~ "Sparkline"
    assert output =~ "Throughput"
    assert output =~ "CPU"
    assert output =~ "Memory"
    assert output =~ "▂▂▂▂▃▅▆▇▅▄▃▂"
  end

  test "line chart story redraws both series when its bounds change" do
    session = Breeze.Test.start!(Breeze.Charts.Storybook.LineChart, size: {50, 16})
    on_exit(fn -> Breeze.Test.stop(session) end)

    automatic = Breeze.Test.render_text!(session)
    assert automatic =~ "Baseline"
    assert automatic =~ "Candidate"
    assert automatic =~ ~r/240\s*│/u

    assert {:noreply, "storybook-line-chart-scale", true} = Breeze.Test.input(session, "Enter")

    fixed = Breeze.Test.render_text!(session)
    assert fixed =~ ~r/300\s*│/u
    assert fixed =~ "Baseline"
    assert fixed =~ "Candidate"
    refute fixed =~ ~r/240\s*│/u
  end

  test "bar chart story switches the same series between grouped and stacked layouts" do
    session =
      Breeze.Test.start!(Breeze.Storybook,
        size: {80, 40},
        start_opts: [directory: Path.expand("../storybook", __DIR__), file: "bar_chart.story.exs"]
      )

    on_exit(fn -> Breeze.Test.stop(session) end)
    grouped = Breeze.Test.render_text!(session)
    assert grouped =~ "Preview: Chart (Bar) / Grouped"
    assert grouped =~ "Run C"
    assert grouped =~ "Input"
    assert grouped =~ "Output"
    assert grouped =~ "610"
    refute grouped =~ "850"

    assert {:noreply, "storybook-nav", true} =
             Breeze.Test.event(session, "select_variant", %{value: "stacked"})

    stacked = Breeze.Test.render_text!(session)
    assert stacked =~ "Preview: Chart (Bar) / Stacked"
    assert stacked =~ "Run C"
    assert stacked =~ "Input"
    assert stacked =~ "Output"
    assert stacked =~ "850"
  end

  test "bar chart story transposes the same series to horizontal rows" do
    session = Breeze.Test.start!(Breeze.Charts.Storybook.BarChart, size: {50, 18})
    on_exit(fn -> Breeze.Test.stop(session) end)

    vertical = Breeze.Test.render_text!(session)
    assert vertical =~ "└"
    assert vertical =~ ~r/Run A\s+Run B\s+Run C/u

    assert {:noreply, "storybook-bar-chart-orientation", true} =
             Breeze.Test.input(session, "Enter")

    horizontal = Breeze.Test.render_text!(session)
    refute horizontal =~ "└"
    assert horizontal =~ ~r/Run A[^\n]+420/u
    assert horizontal =~ ~r/Run B[^\n]+610/u
    assert horizontal =~ ~r/Run C[^\n]+350/u
  end
end
