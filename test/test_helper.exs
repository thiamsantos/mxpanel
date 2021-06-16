if System.get_env("CI") == "true" and function_exported?(Code, :put_compiler_option, 2) do
  Code.put_compiler_option(:warnings_as_errors, true)
end

Finch.start_link(name: Mxpanel.HTTPClient)
ExUnit.start()
