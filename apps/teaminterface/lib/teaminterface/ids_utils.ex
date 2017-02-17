defmodule Teaminterface.IdsUtils do
  def parse(rules) when is_binary(rules) do
    case :cgcids_lexer.tokenize(rules) do
      {:ok, tokens, _lineno} ->
        parse(tokens)
      _ ->
        false
    end
  end

  def parse(tokens) when is_list(tokens) do
    case :cgcids_parser.parse(tokens) do
      {:ok, _rules} ->
        true
      _ -> false
    end
  end
end
