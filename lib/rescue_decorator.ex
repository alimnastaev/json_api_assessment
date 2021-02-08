defmodule JsonApi.RescueDecorator do
  @moduledoc """
  Add a rescue to any function.
  """
  use Decorator.Define, rescue_decorator: 0

  def rescue_decorator(body, context = %{args: [conn, _]}) do
    quote do
      try do
        unquote(body)
      rescue
        e ->
          Logger.error(
            "Rescue Error in #{unquote(context.module)} #{unquote(context.name)} #{inspect(e)}"
          )

          send_resp(
            unquote(conn),
            500,
            %{body: nil, errors: ["Internal Server Error"]} |> Jason.encode!()
          )
      end
    end
  end
end
