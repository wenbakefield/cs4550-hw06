defmodule Bulls.GameSup do
  @moduledoc """
  Modified from CS 4550 lecture notes
  Author: Nat Tuck
  Attribution: https://github.com/NatTuck/scratch-2021-01/blob/master/4550/0219/hangman/lib/hangman/game_sup.ex
  """
  use DynamicSupervisor

  def start_link(arg) do
    DynamicSupervisor.start_link(
      __MODULE__,
      arg,
      name: __MODULE__
    )
  end

  @impl true
  def init(_arg) do
    {:ok, _} = Registry.start_link(
      keys: :unique,
      name: Bulls.GameReg
    )
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(spec) do
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

end
