defmodule JsonApi.HTTP do
  @moduledoc false

  alias JsonApi.Cron

  def request({username, repo_name}) do
    HTTPoison.request(
      :get,
      "https://api.github.com/repos/#{username}/#{repo_name}/stargazers",
      [],
      [{"Accept", "application/vnd.github.v3.star+json"}]
    )
    |> case do
      {:ok, %{body: "[]", status_code: 200}} ->
        {:error, :no_stars_yet}

      {:ok, %{body: starred_users, status_code: 200}} ->
        {:ok, list_of_maps} = Jason.decode(starred_users)

        Enum.map(list_of_maps, fn map ->
          stargazer = map["user"]["login"]
          timestamp = map["starred_at"]
          {username, repo_name, {stargazer, timestamp, "starred"}}
        end)

      {:ok, %{status_code: 403}} ->
        Process.sleep(1000 * 60 * 15)
        Cron.run()
    end
  end
end
