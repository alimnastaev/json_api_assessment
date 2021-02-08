defmodule JsonApiWeb.Plug.CastParams do
  @moduledoc false

  use JsonApiWeb, :controller
  import Plug.Conn

  alias JsonApiWeb.Plug.StargazersControllerCastParams

  def call(conn = %Plug.Conn{request_path: "/api" <> _}, _) do
    conn
    |> cast_params(:api)
  end

  def call(conn, _) do
    conn
  end

  defp cast_params(conn, select) do
    select_to_mod(select).cast_params(conn)
    |> case do
      {:ok, params} ->
        assign(conn, :clean_params, params)

      {:error, code, message, validation_errors} ->
        conn
        |> error_resp(code, message, validation_errors)
        |> halt()

      {:error, code, message} ->
        conn
        |> error_resp(code, message)
        |> halt()

      _ ->
        conn
        |> error_resp(400, "Bad Request")
        |> halt()
    end
  end

  defp error_resp(conn, code, message, validation_errors \\ "") do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(
      code,
      %{error: code, message: message, validation_errors: validation_errors} |> Jason.encode!()
    )
  end

  defp select_to_mod(select) do
    mods = %{
      api: StargazersControllerCastParams
    }

    if is_nil(mods[select]) do
      :error
    else
      mods[select]
    end
  end
end
