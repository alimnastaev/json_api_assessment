defmodule JsonApiWeb.StargazersController do
  @moduledoc false

  use JsonApiWeb, :controller
  use JsonApi.RescueDecorator
  require Logger

  # Checking if username and repo exist in the system:
  # if YES: not saving and provide a message
  # if NOT: checking that user and repo exist in GitHub:
  #       if user and repo exist with ZERO stars -> inserting to ETS :users
  #       if user and repo exist WITH stars -> inserting to ETS :users and ETS :stargazers

  # 1. Adding github users to ETS table :users -
  #           {username, repo_name}
  # 2. Saving the info in ETS table :stargazers -
  #       {"username", "repo_name", {"stargazer_name", "2021-01-24", "starred"}}
  @decorate rescue_decorator()
  def add_new_repo(conn, _params) do
    {conn, 200, conn.assigns.clean_params}
    |> user_repo_exist_in_system?()
    |> user_repo_exist_in_github?()
    |> save_in_ets()
    |> resp_send()
  end

  defp user_repo_exist_in_system?(
         {conn, 200,
          %{
            username: username,
            repo: repo_name
          }}
       ) do
    :ets.match_object(:users, {username, repo_name})
    |> case do
      [{username, repo_name}] ->
        {conn, 201,
         %{
           response: %{
             body: %{message: "User #{username} and repository #{repo_name} already exist."},
             errors: nil
           }
         }}

      [] ->
        {conn, 200,
         %{
           username: username,
           repo: repo_name
         }}
    end
  end

  defp user_repo_exist_in_github?(
         {conn, 200,
          %{
            username: username,
            repo: repo_name
          }}
       ) do
    HTTPoison.request(
      :get,
      "https://api.github.com/repos/#{username}/#{repo_name}/stargazers",
      [],
      [{"Accept", "application/vnd.github.v3.star+json"}]
    )
    |> case do
      {:ok, %{body: "[]", status_code: 200}} ->
        {conn, 200,
         %{
           username: username,
           repo: repo_name
         }}

      {:ok, %{body: stargazers, status_code: 200}} ->
        {:ok, list_of_maps} = Jason.decode(stargazers)

        list_of_stargazers =
          Enum.map(list_of_maps, fn map ->
            stargazer = map["user"]["login"]
            timestamp = map["starred_at"]
            {username, repo_name, {stargazer, timestamp, "starred"}}
          end)

        {conn, 200,
         %{
           username: username,
           repo: repo_name,
           stargazers: list_of_stargazers
         }}

      {:ok, %{status_code: 403}} ->
        {conn, 403,
         %{
           response: %{
             body: nil,
             errors: ["API rate limit exceeded. Wait a little bit and try again"]
           }
         }}

      {_, %{status_code: 404}} ->
        {conn, 404, %{response: %{body: nil, errors: ["No User or Repository found."]}}}
    end
  end

  defp user_repo_exist_in_github?({conn, status_code, params}), do: {conn, status_code, params}

  defp save_in_ets(
         {conn, 200,
          %{
            username: username,
            repo: repo_name,
            stargazers: list_of_stargazers
          }}
       ) do
    :ets.insert(:users, {username, repo_name})

    Enum.each(list_of_stargazers, fn item -> :ets.insert(:stargazers, item) end)

    {conn, 200,
     %{
       response: %{
         body: %{
           message:
             "User #{username} and repository #{repo_name} along with stargazers have been saved in the system"
         },
         errors: nil
       }
     }}
  end

  defp save_in_ets(
         {conn, 200,
          %{
            username: username,
            repo: repo_name
          }}
       ) do
    :ets.insert(:users, {username, repo_name})

    {conn, 200,
     %{
       response: %{
         body: %{
           message: "User #{username} and repository #{repo_name} have been saved in the system"
         },
         errors: nil
       }
     }}
  end

  defp save_in_ets({conn, status_code, params}), do: {conn, status_code, params}

  # Pool of New and Former Stargazers
  @decorate rescue_decorator()
  def new_and_former_stargazers(conn, _params) do
    {conn, 200, conn.assigns.clean_params}
    |> user_exist_in_system?()
    |> user_with_stargazers?()
    |> get_stargazers()
    |> resp_send()
  end

  defp user_exist_in_system?(
         {conn, 200,
          %{
            username: username,
            repo: repo,
            start_range: start_range,
            end_range: end_range
          }}
       ) do
    :ets.match_object(:users, {username, repo})
    |> case do
      [] ->
        {conn, 200,
         %{
           response: %{
             body: %{
               message:
                 "User #{username} and repository #{repo} not in the system yet. Please, add them first"
             },
             errors: nil
           }
         }}

      _ ->
        {conn, 200,
         %{
           username: username,
           repo: repo,
           start_range: start_range,
           end_range: end_range
         }}
    end
  end

  defp user_with_stargazers?(
         {conn, 200,
          %{
            username: username,
            repo: repo,
            start_range: start_range,
            end_range: end_range
          }}
       ) do
    stargazers = :ets.match_object(:stargazers, {username, repo, {:_, :_, :_}})

    case stargazers do
      [] ->
        {conn, 200,
         %{
           response: %{
             body: %{
               message: "Repository #{repo} not starred yet. Consider to be the first one"
             },
             errors: nil
           }
         }}

      _ ->
        {conn, 200,
         %{
           repo: repo,
           start_range: start_range,
           end_range: end_range,
           stargazers: stargazers
         }}
    end
  end

  defp user_with_stargazers?({conn, status_code, params}), do: {conn, status_code, params}

  defp get_stargazers(
         {conn, 200,
          %{
            repo: repo,
            start_range: start_range,
            end_range: end_range,
            stargazers: stargazers
          }}
       ) do
    all_correct_users =
      Enum.map(stargazers, fn user ->
        {_username, _repo_name, {stargazer, timestamp, flag}} = user

        if find_in_range(start_range, end_range, timestamp) do
          "#{stargazer} #{flag}"
        end
      end)
      |> Enum.reject(fn x -> x == nil end)

    case all_correct_users do
      [] ->
        [start_time, _] = String.split(start_range, "T", parts: 2)
        [end_time, _] = String.split(end_range, "T", parts: 2)

        {conn, 200,
         %{
           response: %{
             body: %{
               message: "No activity in repository #{repo} during #{start_time} - #{end_time}"
             },
             errors: nil
           }
         }}

      _ ->
        {conn, 200,
         %{
           response: %{
             body: all_correct_users,
             errors: nil
           }
         }}
    end
  end

  defp get_stargazers({conn, status_code, params}), do: {conn, status_code, params}

  def find_in_range(start_range, end_range, timestamp) do
    if valid_time?(start_range) |> is_map() and valid_time?(end_range) |> is_map() and
         valid_time?(timestamp) |> is_map() do
      DateTime.diff(valid_time?(start_range), valid_time?(timestamp)) < 0 and
        DateTime.diff(valid_time?(timestamp), valid_time?(end_range)) < 0
    else
      false
    end
  end

  defp valid_time?(time) do
    case DateTime.from_iso8601(time) do
      {:ok, valid_time, 0} -> valid_time
      _ -> false
    end
  end

  defp resp_send({conn, status_code, %{response: response}}) do
    if Mix.env() == :dev do
      :ets.select(:users, [{:"$1", [], [:"$1"]}])
      |> IO.inspect(label: "USERS ===  \n")

      :ets.select(:stargazers, [{:"$1", [], [:"$1"]}])
      |> IO.inspect(label: "STARGAZERS ===  \n")
    end

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status_code, response |> Jason.encode!())
  end
end
