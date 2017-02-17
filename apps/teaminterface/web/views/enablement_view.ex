defmodule Teaminterface.EnablementView do
  use Teaminterface.Web, :view

  def enable_klass(true), do: "enabled"
  def enable_klass(false), do: "disabled"
end
