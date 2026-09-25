defmodule Breeze.Charts.Docs.Previews do
  @moduledoc false

  @output Path.expand("../doc_src/generated/charts.md", __DIR__)
  @themes [
    {:greenscreen, "Greenscreen"},
    {:nebula, "Nebula"},
    {:catppuccin, "Catppuccin Mocha"},
    {:dracula, "Dracula"},
    {:commander, "Commander Blue"},
    {:gruvbox, "Gruvbox Dark"},
    {:nord, "Nord"},
    {:solarized_light, "Solarized Light"},
    {:solarized_dark, "Solarized Dark"}
  ]

  defmodule Sparkline do
    use Breeze.View
    import Breeze.Charts

    def render(assigns) do
      ~H"""
      <box class="bg-panel">
        <box class="bold">Automatic scale</box>
        <.sparkline values={[12, 18, 14, 24, 32, 28, 42, 36, 48, 40, 52, 44]} class="text-success"/>
        <box class="bold pt-1">Shared scale: 0–100%</box>
        <box class="inline">
          <box class="w-8">CPU</box>
          <.sparkline values={[10, 15, 20, 18, 35, 55, 70, 85, 60, 45, 30, 20]} min={0} max={100}/>
        </box>
        <box class="inline">
          <box class="w-8">Memory</box>
          <.sparkline values={~c"(*+-0247:<>A"} min={0} max={100} class="text-accent"/>
        </box>
      </box>
      """
    end
  end

  def write! do
    options =
      Enum.map_join(@themes, "\n", fn {id, label} ->
        selected = if id == :gruvbox, do: " selected", else: ""
        ~s(<option value="#{id}"#{selected}>#{label}</option>)
      end)

    sources =
      Enum.map_join(@themes, ",", fn {id, _label} ->
        theme = Breeze.Theme.builtin(id)
        session = Breeze.Test.start!(Sparkline, size: {36, 6}, theme: theme)

        content =
          try do
            session |> Breeze.Test.render!() |> Base.encode64()
          after
            Breeze.Test.stop(session)
          end

        # IDs and RGB colors are controlled values; ANSI content is base64 encoded.
        ~s({"theme":"#{id}","background":"#{color(theme, :background)}","foreground":"#{color(theme, :text)}","content":"#{content}"})
      end)

    File.mkdir_p!(Path.dirname(@output))

    File.write!(@output, """
    # Chart previews

    These previews are generated from `Breeze.Charts` using Breeze's renderer.
    Change the theme to see how chart colors follow the application's palette.

    <div class="breeze-theme-picker">
      <label for="breeze-component-theme">Preview theme</label>
      <select id="breeze-component-theme" data-breeze-theme-select>#{options}</select>
    </div>

    ## Sparkline

    See `Breeze.Charts.sparkline/1` for attributes and scaling behavior.

    <div class="breeze-ansi" data-ansi-preview="true">
      <script type="application/json" class="breeze-ansi-sources">[#{sources}]</script>
    </div>

    <a href="#" class="breeze-code-toggle" aria-expanded="false">Show code</a>

    ```elixir
    import Breeze.Charts

    # Automatic bounds
    <.sparkline values={[12, 18, 14, 24, 32, 28, 42, 36, 48, 40, 52, 44]} class="text-success" />

    # Fixed bounds shared across charts
    <.sparkline values={[10, 15, 20, 18, 35, 55, 70, 85, 60, 45, 30, 20]} min={0} max={100} />
    ```

    Originally authored by [George Guimarães](https://github.com/georgeguimaraes)
    in [Breeze PR #57](https://github.com/Gazler/breeze/pull/57).
    """)
  end

  defp color(theme, name) do
    case Breeze.Theme.resolve_color(theme, name) do
      {red, green, blue} -> "rgb(#{red}, #{green}, #{blue})"
      "#" <> _ = color -> color
      _ -> "inherit"
    end
  end
end
