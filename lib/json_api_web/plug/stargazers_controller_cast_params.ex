defmodule JsonApiWeb.Plug.StargazersControllerCastParams do
  @moduledoc false

  import Norm

  #! Add New Repositories
  def cast_params(%{
        request_path: "/api/add_new_repo",
        method: "POST",
        params: params
      }) do
    map =
      schema(%{
        "username" => spec(String.valid?()),
        "repo" => spec(String.valid?())
      })

    req_fields = selection(map, ["username", "repo"])

    case conform(params, req_fields) do
      {:ok, %{"username" => username, "repo" => repo}} ->
        cast = %{
          username: username,
          repo: repo
        }

        {:ok, cast}

      {:error, error} ->
        {:error, 422, "Invalid request parameters", error}
    end
  end

  #! New and Former Stargazers
  def cast_params(%{
        request_path: "/api/new_and_former_stargazers",
        method: "POST",
        params: params
      }) do
    map =
      schema(%{
        "username" => spec(String.valid?()),
        "repo" => spec(String.valid?()),
        "start_range" =>
          spec(
            String.valid?() and
              fn start_range ->
                start_range_should_be_before_end_range_with_valid_format(
                  start_range,
                  params["end_range"]
                )
              end
          ),
        "end_range" => spec(String.valid?() and fn end_range -> valid_time_format?(end_range) end)
      })

    req_fields = selection(map, ["username", "repo", "start_range", "end_range"])

    case conform(params, req_fields) do
      {:ok,
       %{
         "username" => username,
         "repo" => repo_name,
         "start_range" => start_range,
         "end_range" => end_range
       }} ->
        cast = %{
          username: username,
          repo: repo_name,
          start_range: start_range,
          end_range: end_range
        }

        {:ok, cast}

      {:error, error} ->
        {:error, 422, "Invalid request parameters", error}
    end
  end

  def start_range_should_be_before_end_range_with_valid_format(start, stop) do
    if is_map(valid_time?(start)) and is_map(valid_time?(stop)) do
      DateTime.diff(valid_time?(start), valid_time?(stop)) < 0
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

  def valid_time_format?(time) do
    case DateTime.from_iso8601(time) do
      {:ok, _, _} -> true
      _ -> false
    end
  end
end
