defmodule JsonApiWeb.StargazersControllerTest do
  @moduledoc false

  use JsonApiWeb, :controller

  use ExUnit.Case
  use JsonApiWeb.ConnCase

  setup do
    starred_repo_body = %{
      "username" => "octocat",
      "repo" => "hello-world"
    }

    no_stars_repo_body = %{
      "username" => "alimnastaev"
    }

    %{starred_repo_body: starred_repo_body, no_stars_repo_body: no_stars_repo_body}
  end

  defp request(url, body) do
    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> post(url, body)

    conn
  end

  describe "JsonApiWeb.StargazersController.add_new_repo" do
    test "SUCCESS CASE", %{starred_repo_body: starred_repo_body} do
      :ets.delete_all_objects(:users)
      :ets.delete_all_objects(:stargazers)

      # adding repo with stars into the system
      conn = request("http://localhost:4000/api/add_new_repo", starred_repo_body)

      assert %{
               "body" => %{
                 "message" =>
                   "User octocat and repository hello-world along with stargazers have been saved in the system"
               },
               "errors" => nil
             } == json_response(conn, 200)

      # if we try to add an existing repo we  will not save it again and message will be provided
      conn = request("http://localhost:4000/api/add_new_repo", starred_repo_body)

      assert %{
               "body" => %{
                 "message" => "User octocat and repository hello-world already exist."
               },
               "errors" => nil
             } == json_response(conn, 201)
    end

    test "Fail CASE", %{no_stars_repo_body: no_stars_repo_body} do
      ######### that's where NORM library shines ###########
      # in StargazersControllerCastParams we specified that
      # username and repo are required payload fields
      # so missing a required field(s) API will respond with nicely 422 error and a message
      conn = request("http://localhost:4000/api/add_new_repo", no_stars_repo_body)

      assert %{
               "error" => 422,
               "message" => "Invalid request parameters",
               "validation_errors" => [
                 %{
                   "input" => %{"username" => "alimnastaev"},
                   "path" => ["repo"],
                   "spec" => ":required"
                 }
               ]
             } == json_response(conn, 422)
    end
  end

  describe "JsonApiWeb.StargazersController.new_and_former_stargazers" do
    test "User and repo not in the system" do
      wrong_payload = %{
        username: "no_user_in_the_system",
        repo: "hello-world",
        start_range: "2011-01-07T00:00:00Z",
        end_range: "2021-01-26T23:59:59Z"
      }

      conn = request("http://localhost:4000/api/new_and_former_stargazers", wrong_payload)

      assert %{
               "body" => %{
                 "message" =>
                   "User no_user_in_the_system and repository hello-world not in the system yet. Please, add them first"
               },
               "errors" => nil
             } == json_response(conn, 200)
    end

    test "User with zero stars in the system" do
      add_user = %{
        username: "alimnastaev",
        repo: "aoc_2020"
      }

      conn = request("http://localhost:4000/api/add_new_repo", add_user)

      assert %{
               "body" => %{
                 "message" =>
                   "User alimnastaev and repository aoc_2020 have been saved in the system"
               },
               "errors" => nil
             } == json_response(conn, 200)

      user_exist_zero_stars = %{
        username: "alimnastaev",
        repo: "aoc_2020",
        start_range: "2011-01-07T00:00:00Z",
        end_range: "2021-01-26T23:59:59Z"
      }

      conn = request("http://localhost:4000/api/new_and_former_stargazers", user_exist_zero_stars)

      assert %{
               "body" => %{
                 "message" => "Repository aoc_2020 not starred yet. Consider to be the first one"
               },
               "errors" => nil
             } == json_response(conn, 200)
    end

    test "User with stars in the system and we can retrieve stargazers for date range" do
      :ets.delete_all_objects(:users)
      :ets.delete_all_objects(:stargazers)

      add_user_with_stars = %{
        username: "octocat",
        repo: "hello-world"
      }

      conn = request("http://localhost:4000/api/add_new_repo", add_user_with_stars)

      assert %{
               "body" => %{
                 "message" =>
                   "User octocat and repository hello-world along with stargazers have been saved in the system"
               },
               "errors" => nil
             } == json_response(conn, 200)

      payload = %{
        username: "octocat",
        repo: "hello-world",
        start_range: "2011-01-07T00:00:00Z",
        end_range: "2021-01-26T23:59:59Z"
      }

      conn = request("http://localhost:4000/api/new_and_former_stargazers", payload)

      assert %{
               "body" => [
                 "schacon starred",
                 "adelcambre starred",
                 "usergenic starred",
                 "fdb starred",
                 "darinel starred",
                 "Willianvdv starred",
                 "sul4bh starred",
                 "preavy starred",
                 "benjic starred",
                 "hagiwaratakayuki starred",
                 "stefanlasiewski starred",
                 "hbjerry starred",
                 "Visgean starred",
                 "jiska starred",
                 "hittudiv starred",
                 "paulomichael starred",
                 "garbagemonster starred",
                 "minamipj9 starred",
                 "coolhead starred",
                 "Spaceghost starred",
                 "RustyF starred",
                 "chexee starred",
                 "adrianbarbic starred",
                 "yasirmturk starred",
                 "moonshadows starred",
                 "ff6347 starred",
                 "LunaticNeko starred",
                 "saadrehman starred",
                 "allanmaio starred",
                 "kapare starred"
               ],
               "errors" => nil
             } == json_response(conn, 200)
    end
  end
end
