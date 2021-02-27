defmodule Bulls.GameServer do
  @moduledoc """
  Modified from CS 4550 lecture notes
  Author: Nat Tuck
  Attribution: https://github.com/NatTuck/scratch-2021-01/blob/master/4550/0219/hangman/lib/hangman/game_server.ex.
  """
  use GenServer
  
  alias Bulls.BackupAgent
  alias Bulls.Game
  
  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker
    }
    Bulls.GameSup.start_child(spec)
  end
  
  def reg(name) do
    {:via, Registry, {Bulls.GameReg, name}}
  end

  def start_link(name) do
    game = BackupAgent.get(name) || Game.new(&timer(name, &1))
    GenServer.start_link(__MODULE__, game, name: reg(name))
  end

  defp timer(name, round) do
    Process.send_after(self(), {:same_round, name, round}, 30_000)
  end

  def join(name, user) do
    GenServer.call(reg(name), {:join, name, user})
  end

  def ready(name, user) do
    GenServer.call(reg(name), {:ready, name, user})
  end

  def view(name) do
    GenServer.call(reg(name), {:view, name})
  end

  def guess(name, user, number) do
    GenServer.call(reg(name), {:guess, name, user, number})
  end

  def reset(name) do
    GenServer.call(reg(name), {:reset, name})
  end

  def init(game) do
    {:ok, game}
  end

  def handle_call({:join, name, user}, _from, game) do
    game = Game.user_join(game, user)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:ready, name, user}, _from, game) do
    game = Game.user_ready(game, user)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:view, _name}, _from, game) do
    view = Game.view(game)
    {:reply, view, game}
  end

  def handle_call({:guess, name, user, number}, _from, game) do
    game = Game.guess(game, user, number)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:reset, name}, _from, game) do
    game = Game.end_game(game)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_info({:same_round, name, round}, game) do
    game = Game.end_round(game, round)
    view = Game.view(game)
    BullsWeb.Endpoint.broadcast("game:" <> name, "view", view)
    {:noreply, game}
  end
end
