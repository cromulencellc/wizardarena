defmodule Teaminterface.RoundNickname do
  @doc ~S"""

  iex> Teaminterface.RoundNickname.for(4)
  "lengthy-cheese"

  iex> Teaminterface.RoundNickname.for(5)
  "scientific-consistency"

  iex> Teaminterface.RoundNickname.adjective(6)
  "fuzzy"

  iex> Teaminterface.RoundNickname.noun(7)
  "bond"
  """

  @base_seed 4109807777643961956
  @adjective_seed 12109995787839438662
  @noun_seed 18113195010546916746

  def for(round_num) do
    "#{adjective(round_num)}-#{noun(round_num)}"
  end

  def adjective(round_num) do
    state = :rand.seed(:exs1024, {@base_seed, @adjective_seed, round_num})
    {idx, _new_state} = :rand.uniform_s(100, state)
    Nicknamer.NicknameServer.adjective(idx)
  end

  def noun(round_num) do
    state = :rand.seed(:exs1024, {@base_seed, @noun_seed, round_num})
    {idx, _new_state} = :rand.uniform_s(100, state)
    Nicknamer.NicknameServer.noun(idx)
  end
end
