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
          {username, repo_name, {stargazer, _, _}} = old_elem

          new_elem =
            {username, repo_name,
             {stargazer, Date.utc_today() |> Date.add(-1) |> Date.to_string(), "unstarred"}}

          acc ++ [new_elem] ++ [old_elem]
        end
      end)

    :ets.delete_all_objects(:stargazers)

    updated_data = new_data ++ unstarred

    Enum.each(updated_data, fn item -> :ets.insert(:stargazers, item) end)

    # IEX OUTPUT
    :ets.select(:stargazers, [{:"$1", [], [:"$1"]}])
  end
end
