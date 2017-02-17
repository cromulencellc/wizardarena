defmodule Teaminterface.Repo do
  use Ecto.Repo, otp_app: :teaminterface
  use Scrivener, page_size: 100

  def fix_counter(table_names) when is_list(table_names) do
    for table_name <- table_names, do: fix_counter(table_name)
  end

  def fix_counter(table_name) when is_binary(table_name) do
    q = """
      SELECT
        setval('#{table_name}_id_seq',
               (select max(id) from #{table_name}))
    """
  Ecto.Adapters.SQL.query(__MODULE__, q, [])
  end
end
