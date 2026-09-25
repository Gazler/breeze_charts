# Breeze.Charts

Chart components for [Breeze](https://github.com/Gazler/breeze). Currently includes
sparklines: one Unicode bar per value, with automatic or fixed scaling.

## Usage

Add `breeze_charts` to your dependencies in `mix.exs`:

```elixir
{:breeze_charts, "~> 0.1.0"}
```

Import the components in your view:

```elixir
defmodule Dashboard do
  use Breeze.View
  import Breeze.Charts

  def render(assigns) do
    ~H"""
    <.sparkline values={[2, 4, 3, 8, 6]} class="text-success" />
    <.sparkline values={[10, 35, 70, 55]} min={0} max={100} />
    """
  end
end
```

Empty data renders no bars. Constant values render `▁`. Values outside fixed
bounds are clamped. Width defaults to the number of values; a narrower `class`
clips the chart without resampling it. Existing `class` and `style` overrides
are supported.

Run the interactive example from this checkout:

```sh
mix deps.get
mix run examples/sparkline.exs
```

Press `q` to quit.

## Storybook

Browse the sparkline's automatic and shared-scale examples:

```sh
mix breeze.storybook
```

The story is in `storybook/sparkline.story.exs`.

## Documentation

Build the API reference and rendered chart previews with:

```sh
mix docs
```

## Credits

The sparkline component, its original tests, and the example content were
created by **[George Guimarães](https://github.com/georgeguimaraes)** in
[Breeze PR #57](https://github.com/Gazler/breeze/pull/57), commit
[`9f16c3e`](https://github.com/Gazler/breeze/commit/9f16c3e194f78ac5a645fb38b9953a4440ffe7c8).

Licensed under the MIT license. See [LICENCE.md](LICENCE.md).
