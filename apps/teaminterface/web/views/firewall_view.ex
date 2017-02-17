defmodule Teaminterface.FirewallView do
  use Teaminterface.Web, :view

  import Teaminterface.DashboardView, only: [digest: 1, cbid: 2]

  def query(conn, text, clauses) do
    new_params = conn.params
    |> Map.new
    |> Map.merge(clauses |> Map.new)

    klass = case String.length(text) do
              1 -> "shape"
              _ -> ""
            end

    link(text,
         to: firewall_path(conn,
                              :index,
                              new_params),
         class: klass)
  end

  def filter_explainer(conn, params) when %{} == params do
    content_tag(:p, "No filters")
  end

  def filter_explainer(conn, params) do
    clauses = params
    |> Enum.map(fn({name, value}) ->
      remove_params = params
      |> Map.delete(name)

      remove_link = link("x",
                         to: firewall_path(conn, :index, remove_params),
                         class: "shape")

      {name, value, remove_link}
    end)
    |> Enum.map(fn
      ({"not_" <> name, value, rm_link}) -> [rm_link, "#{name} != #{value}"]
      ({name, value, rm_link}) -> [rm_link, "#{name} = #{value}"]
    end)
    |> Enum.map(&content_tag(:li, &1))

    content_tag(:ul, clauses, [class: "filters"])
  end
end
