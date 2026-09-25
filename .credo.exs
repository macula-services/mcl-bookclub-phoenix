%{
  configs: [
    %{
      name: :default,
      files: %{
        included: ["apps/*/lib/", "apps/*/test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      strict: true,
      checks: %{
        disabled: [
          # The house ruleset is structural, not stylistic: nesting, tries,
          # if-expressions. The readability checks stay on for humans.
        ]
      }
    }
  ]
}
