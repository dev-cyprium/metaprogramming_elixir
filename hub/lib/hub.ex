defmodule Hub do
  HTTPoison.start
  @username "chrismccord"

  HTTPoison.get!("https://api.github.com/users/#{@username}/repos")
  |> Map.get(:body)
  |> Poison.decode!
  |> Enum.each(fn repo ->
    def unquote(String.to_atom(repo["name"]))() do
      unquote(Macro.escape(repo))
    end
  end)

  def go(repo) do
    url = apply(__MODULE__, repo, [])["html_url"]
    IO.puts "Launching browsr to #{url}..."
    System.cmd("xdg-open", [url])
  end
end
