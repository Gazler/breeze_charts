[
  import_deps: [:breeze],
  plugins: [Breeze.HTMLFormatter],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test,examples,storybook,doc_support}/**/*.{ex,exs}"
  ]
]
