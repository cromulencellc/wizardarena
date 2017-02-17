defmodule Teaminterface.LayoutView do
  use Teaminterface.Web, :view

  def title(_assigns = %{title: title}) do
    "#{title} | #{title(%{})}"
  end

  def title(_assigns) do
    Application.get_env(:teaminterface,
                        Teaminterface.Web,
                        %{contest: "Wizard Arena"})[:contest]
  end

  def body_class(conn) do
    controller_name = conn
    |> Phoenix.Controller.controller_module
    |> Phoenix.Naming.resource_name("Controller")

    action_name = conn
    |> Phoenix.Controller.action_name

    "con_#{controller_name} act_#{action_name}"
  end

  def round do
    rnd = Teaminterface.Round.current_or_next

    cond do
      is_nil(rnd) -> "no round"
      not is_nil(rnd.finished_at) -> "finished round #{rnd.id}"
      not is_nil(rnd.started_at) -> "started round #{rnd.id}"
      true -> "waiting for round #{rnd.id}"
    end
  end
end
