defmodule Breeze.Charts.StorybookTest do
  use ExUnit.Case, async: true

  test "storybook discovers and renders the extracted sparkline" do
    session =
      Breeze.Test.start!(Breeze.Storybook,
        size: {90, 30},
        start_opts: [directory: Path.expand("../storybook", __DIR__)]
      )

    on_exit(fn -> Breeze.Test.stop(session) end)
    output = Breeze.Test.render_text!(session)

    assert output =~ "Sparkline"
    assert output =~ "Throughput"
    assert output =~ "CPU"
    assert output =~ "Memory"
    assert output =~ "▂▂▂▂▃▅▆▇▅▄▃▂"
  end
end
