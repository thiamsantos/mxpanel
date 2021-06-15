if System.get_env("CI") == "true" do
  Code.put_compiler_option(:warnings_as_errors, true)
end

Finch.start_link(name: Mxpanel.HTTPClient)
ExUnit.start()
