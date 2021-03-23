defmodule JsonApi.Cron do
  @moduledoc """
  This file will be triggered every day by
  by Quantum to keep our pool of starred and unstarred users
  """
  alias JsonApi.HTTP

  def run do
    users =
      :ets.select(:users, [{:"$1", [], [:"$1"]}])
      |> Enum.map(&HTTP.request/1)
      |> Enum.filter(fn elem -> elem != {:error, :no_stars_yet} end)

    new_data =
      if users != [] do
        List.flatten(users)
      else
        users
      end

    local_data = :ets.select(:stargazers, [{:"$1", [], [:"$1"]}])

    unstarred =
      Enum.reduce(local_data, [], fn old_elem, acc ->
        if Enum.member?(new_data, old_elem) do
          acc
        else
          {username, repo_name, {stargazer, timestamp, _}} = old_elem

          timestamp = ts_minus_one_day(timestamp)

          new_elem = {username, repo_name, {stargazer, timestamp, "unstarred"}}

          acc ++ [new_elem] ++ [old_elem]
        end
      end)

    :ets.delete_all_objects(:stargazers)

    updated_data = new_data ++ unstarred

    Enum.each(updated_data, fn item -> :ets.insert(:stargazers, item) end)

    # IEX OUTPUT
    :ets.select(:stargazers, [{:"$1", [], [:"$1"]}])
  end

  defp ts_minus_one_day(timestamp) do
    {:ok, dt, 0} = DateTime.from_iso8601(timestamp)

    dt
    |> Timex.shift(days: -1)
    |> DateTime.to_iso8601()
  end
end
